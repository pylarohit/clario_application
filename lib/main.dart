import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/login.dart';
import 'auth/onboarding.dart';
import 'home/home.dart';
import 'package:app_links/app_links.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize Supabase with credentials from .env
  final supabaseUrl = dotenv.env['NEXT_PUBLIC_SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY'];

  if (supabaseUrl != null && supabaseAnonKey != null) {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  // Setup deep linking for OAuth callbacks (mobile only)
  if (!kIsWeb) {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      debugPrint('📱 Deep link received: $uri');
      try {
        Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('❌ Deep link error: $e');
      }
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clario',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthGate(),
      //home: HomePage(), // Temporarily bypassing login - go directly to dashboard
      routes: {
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// AuthGate: Checks authentication status and routes accordingly
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _hasProfile = false;
  bool _isChecking = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _checkAuth();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      debugPrint('🔐 Auth state changed: ${data.event}');
      debugPrint('🔐 Session exists: ${data.session != null}');
      debugPrint('🔐 User ID: ${data.session?.user.id}');
      
      if (data.event == AuthChangeEvent.signedIn) {
        debugPrint('⏰ Sign-in detected, setting loading state...');
        
        if (mounted) {
          setState(() {
            _loading = true;
            _hasProfile = false;
            _isChecking = false;
          });
        }
        
        // Check profile after small delay
        await Future.delayed(Duration(milliseconds: 300));
        if (mounted) {
          await _checkUserProfile();
        }
      } else if (data.event == AuthChangeEvent.signedOut) {
        debugPrint('👋 User signed out');
        if (mounted) {
          setState(() {
            _hasProfile = false;
            _loading = false;
            _isChecking = false;
          });
        }
      } else if (data.event == AuthChangeEvent.tokenRefreshed) {
        debugPrint('🔄 Token refreshed - checking if rebuild needed');
        // Token refresh might happen on app resume - ensure we show correct screen
        if (mounted) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null && !_loading && !_isChecking) {
            setState(() {
              _loading = true;
            });
            await _checkUserProfile();
          }
        }
      }
    });
  }

  Future<void> _checkAuth() async {
    // Initial profile check - only if user is logged in
    final user = Supabase.instance.client.auth.currentUser;
    debugPrint('🔍 Initial check - User exists: ${user != null}');
    if (user != null) {
      debugPrint('🔍 Calling initial _checkUserProfile()...');
      await _checkUserProfile();
    } else {
      // No user logged in, stop loading
      debugPrint('ℹ️ No user logged in initially');
      if (mounted) {
        setState(() {
          _loading = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _checkUserProfile() async {
    // Prevent multiple simultaneous checks
    if (_isChecking) {
      debugPrint('⏳ Profile check already in progress, skipping...');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // Set checking state (loading already set in caller)
      if (mounted && !_loading) {
        setState(() {
          _loading = true;
          _isChecking = true;
        });
      }

      try {
        debugPrint('🔍 Checking user profile for: ${user.id}');
        
        // On mobile, do multiple retries with increasing delays for new user database record creation
        final maxRetries = kIsWeb ? 1 : 3;
        Map<String, dynamic>? response;
        
        for (int attempt = 1; attempt <= maxRetries; attempt++) {
          if (attempt > 1) {
            final waitMs = attempt * 500; // 500ms, 1000ms, 1500ms
            debugPrint('⏰ Retry $attempt: Waiting ${waitMs}ms for database record...');
            await Future.delayed(Duration(milliseconds: waitMs));
          } else if (attempt == 1) {
            // Small initial delay on mobile to give database time to create record
            if (!kIsWeb) {
              debugPrint('⏰ Initial 300ms wait for database...');
              await Future.delayed(Duration(milliseconds: 300));
            }
          }
          
          response = await Supabase.instance.client
              .from('users')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          
          debugPrint('📊 Attempt $attempt - Response: ${response != null ? "Found" : "Not found"}');
          
          // If found, stop retrying
          if (response != null) break;
        }
        
        // If still no record after all retries, it's a brand new user
        if (response == null) {
          debugPrint('🆕 Brand new user - no database record found after retries, showing onboarding');
          if (mounted) {
            setState(() {
              _hasProfile = false;
              _loading = false;
              _isChecking = false;
            });
          }
          return;
        }
        
        // Validate onboarding completion
        final hasCompletedOnboarding = _validateOnboardingCompletion(response);

        debugPrint('🎯 Setting state - hasProfile: $hasCompletedOnboarding');
        if (mounted) {
          setState(() {
            _hasProfile = hasCompletedOnboarding;
            _loading = false;
            _isChecking = false;
          });
          debugPrint('✅ State updated - widget should rebuild now');
        }
      } catch (e) {
        debugPrint('❌ Error checking user data: $e');
        debugPrint('🔄 Assuming onboarding not completed - routing to onboarding');
        if (mounted) {
          setState(() {
            _hasProfile = false;
            _loading = false;
            _isChecking = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasProfile = false;
          _isChecking = false;
        });
      }
    }
  }

  bool _validateOnboardingCompletion(Map<String, dynamic>? response) {
    if (response == null) {
      debugPrint('❌ No user data - showing onboarding');
      return false;
    }
    
    debugPrint('🔍 FULL USER DATA: $response');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 userPhone: "${response['userPhone']}" (type: ${response['userPhone']?.runtimeType})');
    debugPrint('🏫 institutionName: "${response['institutionName']}" (type: ${response['institutionName']?.runtimeType})');
    debugPrint('👤 current_status: "${response['current_status']}" (type: ${response['current_status']?.runtimeType})');
    debugPrint('🎯 mainFocus: "${response['mainFocus']}"');
    debugPrint('👥 userName: "${response['userName']}"');
    debugPrint('📧 userEmail: "${response['userEmail']}"');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    // Check phone - REQUIRED (only from onboarding)
    final hasPhone = response['userPhone'] != null &&
                     response['userPhone'].toString().trim().length >= 7 &&
                     response['userPhone'].toString().trim() != 'null';
    
    // Check institution - REQUIRED (only from onboarding)
    final hasInstitution = response['institutionName'] != null &&
                          response['institutionName'].toString().trim().length >= 3 &&
                          response['institutionName'].toString().trim() != 'null';
    
    // Check profession/status - REQUIRED (only from onboarding)
    final hasStatus = response['current_status'] != null &&
                     response['current_status'].toString().trim().isNotEmpty &&
                     response['current_status'].toString().trim() != 'null';
    
    debugPrint('✓ Has Phone: $hasPhone');
    debugPrint('✓ Has Institution: $hasInstitution');
    debugPrint('✓ Has Status: $hasStatus');
    
    // User has completed onboarding if they have these 3 required fields
    final isComplete = hasPhone && hasInstitution && hasStatus;
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('✅ Onboarding Complete: $isComplete');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    
    return isComplete;
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    debugPrint(
      '🏠 AuthGate build - loading: $_loading, session: ${session != null}, hasProfile: $_hasProfile',
    );

    // Not logged in -> Show Login (even if still loading)
    if (session == null) {
      debugPrint('➡️ Routing to LoginPage (no session)');
      return const LoginPage();
    }

    // Still checking user profile -> Show loading
    if (_loading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading your profile...',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Logged in but hasn't completed onboarding -> Show Onboarding
    if (!_hasProfile) {
      debugPrint('➡️ Routing to OnboardingPage (first time user)');
      return const OnboardingPage();
    }

    // Logged in and completed onboarding -> Show Home Dashboard
    debugPrint('➡️ Routing to HomePage (returning user)');
    return HomePage();
  }
}

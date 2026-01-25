import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    );
  }
  
  // Setup deep linking for OAuth callbacks (mobile only)
  if (!kIsWeb) {
    final appLinks = AppLinks();
    appLinks.uriLinkStream.listen((uri) {
      try {
        if (Supabase.instance.client.auth.currentSession == null) {
          Supabase.instance.client.auth.getSessionFromUrl(uri);
        }
      } catch (e) {
        // Ignore errors from non-OAuth deep links
        print('Deep link error (ignored): $e');
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => HomePage(),
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

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (mounted) {
        await _checkUserProfile();
      }
    });
    
    await _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user != null) {
      try {
        print('🔍 Checking profile for user: ${user.id}');
        // Check if user has a profile
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        print('📊 Profile response: $response');
        final hasProfile = response != null && response['full_name'] != null;
        print('✅ Has profile: $hasProfile');
        
        if (mounted) {
          setState(() {
            _hasProfile = hasProfile;
            _loading = false;
          });
        }
      } catch (e) {
        print('❌ Error checking profile: $e');
        print('🔄 Assuming no profile - routing to onboarding');
        if (mounted) {
          setState(() {
            _hasProfile = false;
            _loading = false;
          });
        }
      }
    } else {
      setState(() {
        _loading = false;
        _hasProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    final session = Supabase.instance.client.auth.currentSession;
    print('🏠 AuthGate build - session: ${session != null}, hasProfile: $_hasProfile');
    
    // Not logged in -> Show Login
    if (session == null) {
      print('➡️ Routing to LoginPage');
      return const LoginPage();
    }
    
    // Logged in but no profile -> Show Onboarding
    if (!_hasProfile) {
      print('➡️ Routing to OnboardingPage');
      return const OnboardingPage();
    }
    
    // Logged in with profile -> Show Home
    return HomePage();
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import '../_components/onboarding_card.dart';

const List<Map<String, dynamic>> steps = [
  {
    'id': 1,
    'title': 'Welcome',
    'description': 'Let\'s get to know you better',
    'icon': Icons.flag,
  },
  {
    'id': 2,
    'title': 'Current Status',
    'description': 'Tell us what best describes you right now.',
    'icon': Icons.work,
  },
  {
    'id': 3,
    'title': 'Your Focus',
    'description': 'Choose your main goals',
    'icon': Icons.school,
  },
  {
    'id': 4,
    'title': 'Google workspace',
    'description': 'Connect your Google Workspace',
    'icon': Icons.g_mobiledata,
  },
  {
    'id': 5,
    'title': 'Invite Friends',
    'description': 'Invite your friends on this platform',
    'icon': Icons.people,
  },
];

class CallbackPage extends StatefulWidget {
  const CallbackPage({super.key});

  @override
  State<CallbackPage> createState() => _CallbackPageState();
}

class _CallbackPageState extends State<CallbackPage> {
  User? user;
  bool loading = true;
  bool isNewUser = false;

  @override
  void initState() {
    super.initState();
    _checkUser();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        _checkUser();
      }
    });
  }

  Future<void> _checkUser() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      setState(() {
        user = currentUser;
        loading = false;
        // TODO: Implement isNewUser logic, e.g., check if user exists in DB
        isNewUser = false; // Placeholder
      });
      final prefs = await SharedPreferences.getInstance();
      final onboardingDone = prefs.getBool('isOnboardingDone') ?? false;
      if (isNewUser) {
        Fluttertoast.showToast(msg: 'Welcome aboard, ${user!.email}!');
      } else if (!onboardingDone || !(user!.userMetadata?['is_verified'] ?? true)) {
        Fluttertoast.showToast(msg: 'Resuming your onboarding Process');
      } else {
        Fluttertoast.showToast(msg: 'Welcome back, ${user!.email}!');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    } catch (error) {
      debugPrint('Error signing out: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(
                'Validating user...',
                style: GoogleFonts.raleway(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Text(
                'Please wait and tighten your seatbelt',
                style: GoogleFonts.inter(fontSize: 20),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: SharedPreferences.getInstance().then((prefs) => prefs.getBool('isOnboardingDone') ?? false),
      builder: (context, snapshot) {
        final onboardingDone = snapshot.data ?? false;
        if (!onboardingDone || isNewUser) {
          return Scaffold(
            body: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.5, 0.9),
                      radius: 1.25,
                      colors: [Colors.white, Color(0xFF6366F1)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 20,
                  child: Row(
                    children: [
                      Image.asset('assets/clarioWhite.png', width: 60, height: 60),
                      Text(
                        'Clario',
                        style: GoogleFonts.raleway(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 60,
                  right: 80,
                  child: Text(
                    'learn more • earn more • grow more •',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Center(
                  child: OnBoardingCard(),
                ),
              ],
            ),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
          return Container();
        }
      },
    );
  }
}

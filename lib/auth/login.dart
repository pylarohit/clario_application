import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import '../home/home.dart';
import '_components/animated_gradient_text_demo.dart';
import '_components/marquee_demo.dart';



// Main App Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!,
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']!,
  );
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    Supabase.instance.client.auth.getSessionFromUrl(uri);
  });
  runApp(const MyApp());
}




// Root App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clario Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.raleway().fontFamily,
      ),
      home: const LoginPage(),
      routes: {
        '/home': (context) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}





// Login Page Stateful Widget
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}




// Login Page State Management
class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  bool isSignup = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;
  String error = '';

  late ScrollController _scrollController;
  late AnimationController _animationController;




  // Initialization and Setup
  @override
  void initState() {
    super.initState();


    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn && mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )
      ..repeat();

    _animationController.addListener(() {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _animationController.value *
              _scrollController.position.maxScrollExtent,
        );
      }
    });
  }



  // Cleanup
  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }



  // OAuth Authentication Handler
  Future<void> handleLogin(OAuthProvider provider) async {
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(provider);
      // Session will be handled via auth state listener
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }




  // Email/Password Authentication Handler
  Future<void> handleAuth() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      if (isSignup) {
        final response = await Supabase.instance.client.auth.signUp(
          email: emailController.text,
          password: passwordController.text,
        );
        if (response.user != null && response.session == null) {
          setState(() =>
          error = 'Please check your email for verification link');
        } else {
          // Navigate
          //Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        if (response.session != null) {
          //Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }




  // Main UI Build Method
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery
        .of(context)
        .size;
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;
    final isSmallScreen = screenWidth < 600;

    final double gradientTop = isSmallScreen
        ? screenHeight * 0.05
        : screenHeight * 0.08;
    final double logoTop = isSmallScreen ? screenHeight * 0.1 : screenHeight *
        0.13;
    final double quoteTop = isSmallScreen ? screenHeight * 0.22 : screenHeight *
        0.26;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [



            // Hero Section with Gradient Background
            Container(
              height: screenHeight * 0.50,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0f172a),
                    Color(0xFF1e293b),
                    Colors.deepPurple,
                    Colors.indigo,
                  ],
                ),
              ),
              child: Stack(
                children: [



                  // Animated Gradient Text Component
                  Positioned(
                    top: gradientTop,
                    left: 0,
                    right: 0,
                    child: const Center(
                      child: AnimatedGradientTextDemo(),
                    ),
                  ),
                  
                  
                  
                  // Main Logo Display
                  Positioned(
                    top: logoTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/clarioWhite.png', // Local white logo
                        width: isSmallScreen ? 80 : 120,
                        height: isSmallScreen ? 80 : 120,
                        color: Colors.white,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  
                  
                  
                  
                  // Inspirational Quote
                  Positioned(
                    top: quoteTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '“Clarity Today,\nSuccess Tomorrow.”',
                        style: GoogleFonts.sora(
                          fontSize: isSmallScreen ? 30 : 58,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.7),
                          letterSpacing: 1.5,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  
                  
                  
                  // Scrolling Testimonials
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: const MarqueeDemo(),
                  ),
                ],
              ),
            ),





            // Login Form Section
            Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
              child: Column(
                children: [
                  
                  
                  // App Logo and Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/clarioBlack.png',
                        width: isSmallScreen ? 40 : 60,
                        height: isSmallScreen ? 40 : 60,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      Text('Clario', style: GoogleFonts.raleway(
                          fontSize: isSmallScreen ? 24 : 32,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 32),





                  // OAuth Authentication Buttons
                  _buildOAuthButton(
                    onPressed: loading ? null : () =>
                        handleLogin(OAuthProvider.google),
                    iconPath: 'assets/search.png',
                    label: 'continue with Google',
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildOAuthButton(
                    onPressed: loading ? null : () =>
                        handleLogin(OAuthProvider.discord),
                    iconPath: 'assets/discord.png',
                    label: 'continue with Discord',
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  _buildOAuthButton(
                    onPressed: loading ? null : () =>
                        handleLogin(OAuthProvider.slack),
                    iconPath: 'assets/slack.png',
                    label: 'continue with Slack',
                    isSmallScreen: isSmallScreen,
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 32),





                  // Divider Text
                  Text(
                    'or continue with ${isSignup
                        ? "Creating Account"
                        : "Logging In"}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 24),




                  // Email Input Field
                  SizedBox(
                    width: isSmallScreen ? screenWidth * 0.85 : screenWidth *
                        0.6,
                    child: TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 12 : 16),
                  
                  
                  
                  
                  // Password Input Field
                  SizedBox(
                    width: isSmallScreen ? screenWidth * 0.85 : screenWidth *
                        0.6,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 24 : 32),





                  // Main Authentication Button
                  ElevatedButton(
                    onPressed: loading ? null : handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: Size(
                          double.infinity, isSmallScreen ? 45 : 50),
                    ),
                    child: loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      isSignup ? 'Sign Up →' : 'Sign In →',
                      style: TextStyle(color: Colors.white,
                          fontSize: isSmallScreen ? 16 : 18),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 9 : 24),






                  // Toggle Between Sign In/Sign Up
                  TextButton(
                    onPressed: () => setState(() => isSignup = !isSignup),
                    child: Text(
                      isSignup
                          ? "Already have an account? Sign In"
                          : "Don't have an account? Sign Up",
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),






                  // Error Message Display
                  if (error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        error,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }





  // OAuth Button Builder
  Widget _buildOAuthButton({
    required VoidCallback? onPressed,
    required String iconPath,
    required String label,
    required bool isSmallScreen,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Image.asset(
          iconPath, width: isSmallScreen ? 20 : 24, fit: BoxFit.contain),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[50],
        foregroundColor: Colors.black,
        minimumSize: Size(isSmallScreen ? 300 : 350, isSmallScreen ? 45 : 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

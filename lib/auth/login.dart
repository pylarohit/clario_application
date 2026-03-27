import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import '../home/home.dart';

//Main App Entry Point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['NEXT_PUBLIC_SUPABASE_URL']!,
    anonKey: dotenv.env['NEXT_PUBLIC_SUPABASE_ANON_KEY']!,
  );
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) async {
    debugPrint('🔗 Deep Link Received: $uri');
    await Supabase
        .instance.client.auth.getSessionFromUrl(uri);
    debugPrint('✅ Session refreshed from deep link');
  });
  runApp(const MyApp());
}


// Root App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reskill Login',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.raleway().fontFamily,
      ),
      home: const LoginPage(),
      routes: {'/home': (context) => HomePage()},
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Custom Wave Clipper for Header ───────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 60,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Concentric Arcs Painter (purple wave pattern in header) ─────────────────
class _ConcentricArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.15, -size.height * 0.1);
    const int arcCount = 22;

    for (int i = 0; i < arcCount; i++) {
      final radius = 30.0 + i * 18.0;
      final opacity = (0.35 - i * 0.012).clamp(0.05, 0.35);
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -0.2,
        3.14 * 0.7,
        false,
        paint,
      );
    }

    // Secondary arc group from top-right
    final center2 = Offset(size.width * 0.95, -size.height * 0.25);
    for (int i = 0; i < 14; i++) {
      final radius = 25.0 + i * 16.0;
      final opacity = (0.2 - i * 0.012).clamp(0.03, 0.2);
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawArc(
        Rect.fromCircle(center: center2, radius: radius),
        1.5,
        3.14 * 0.6,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Login Page ──────────────────────────────────────────────────────────────
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  bool isSignup = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  bool loading = false;
  String error = '';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    _fadeController.reverse().then((_) {
      setState(() => isSignup = !isSignup);
      _fadeController.forward();
    });
  }

  // ─── OAuth Handler ────────────────────────────────────────────────────────
 
 Future<void> handleLogin(OAuthProvider provider) async {
    setState(() => loading = true);
    try {
      final result = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      if (!result) {
        throw Exception('OAuth sign in was cancelled or failed');
      }
    } catch (e) {
      debugPrint('❌ OAuth Error: $e');
      if (mounted) {
        setState(() => error = 'Sign in failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }



  // ─── Email / Password Handler ─────────────────────────────────────────────
  Future<void> handleAuth() async {
    setState(() {
      loading = true;
      error = '';
    });
    try {
      if (isSignup) {
        debugPrint('🔐 Starting signup...');
        final response = await Supabase.instance.client.auth.signUp(
          email: emailController.text,
          password: passwordController.text,
        );
        debugPrint(
          '✅ Signup response: user=${response.user?.id}, session=${response.session != null}',
        );
        if (response.user != null && response.session == null) {
          setState(
            () => error = 'Please check your email for verification link',
          );
        } else if (response.session != null) {
          debugPrint('🚀 Signup successful - AuthGate will handle routing');
        }
      } else {
        debugPrint('🔐 Starting login...');
        final response =
            await Supabase.instance.client.auth.signInWithPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        debugPrint('✅ Login response: session=${response.session != null}');
        if (response.session != null) {
          debugPrint('🚀 Login successful - AuthGate will handle routing');
        }
      }
    } catch (e) {
      debugPrint('❌ Auth error: $e');
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final screenWidth = mq.size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Gradient Header with wave clip ──────────────────────────────
            _buildGradientHeader(screenHeight, screenWidth),

            // ── Form Body ───────────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    // Title
                    Text(
                      isSignup ? 'Create Your Account' : 'Welcome Back',
                      style: GoogleFonts.raleway(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignup
                          ? "We're here to help you reach the peaks\nof learning. Are you ready?"
                          : "Ready to continue your learning journey?\nYour path is right here.",
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Full Name (Signup only) ─────────────────────────────
                    if (isSignup) ...[
                      _buildTextField(
                        controller: nameController,
                        hint: 'Enter full name',
                        icon: null,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Email ───────────────────────────────────────────────
                    _buildTextField(
                      controller: emailController,
                      hint: 'Enter email',
                      icon: null,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // ── Password ────────────────────────────────────────────
                    _buildTextField(
                      controller: passwordController,
                      hint: isSignup ? 'Enter password' : 'Password',
                      icon: null,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[400],
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    // ── Remember Me / Forgot Password ───────────────────────
                    if (!isSignup) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) =>
                                  setState(() => _rememberMe = v ?? false),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: BorderSide(color: Colors.grey[400]!),
                              activeColor: const Color(0xFF9B59B6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Remember me',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.raleway(
                                fontSize: 13,
                                color: const Color(0xFF9B59B6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              color: const Color(0xFF9B59B6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── Main Action Button ──────────────────────────────────
                    _buildGradientButton(),

                    const SizedBox(height: 28),

                    // ── Divider with 'Sign in with' ─────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            isSignup ? 'Sign up with' : 'Sign in with',
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Social Icons ────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIconButtonImage(
                          assetPath: 'assets/discord.png',
                          onTap: () =>
                              handleLogin(OAuthProvider.discord),
                        ),
                        const SizedBox(width: 24),
                        _socialIconButtonImage(
                          assetPath: 'assets/search.png',
                          onTap: () =>
                              handleLogin(OAuthProvider.google),
                        ),
                        const SizedBox(width: 24),
                        _socialIconButtonImage(
                          assetPath: 'assets/slack.png',
                          onTap: () =>
                              handleLogin(OAuthProvider.slack),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Toggle Sign In / Sign Up ────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSignup
                                ? 'Already have an account? '
                                : "Don't have an account? ",
                            style: GoogleFonts.raleway(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleMode,
                            child: Text(
                              isSignup ? 'Log In' : 'Sign Up',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF9B59B6),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF9B59B6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Error Message ───────────────────────────────────────
                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Center(
                          child: Text(
                            error,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  /// Gradient header with wave pattern & back button
  Widget _buildGradientHeader(double screenHeight, double screenWidth) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: screenHeight * 0.26,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB39DDB), // soft lavender
              Color(0xFFCE93D8), // orchid
              Color(0xFFF48FB1), // pink
              Color(0xFFE1BEE7), // light purple
            ],
          ),
        ),
        child: Stack(
          children: [
            // Concentric arcs decorative pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _ConcentricArcsPainter(),
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// Styled text field
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.raleway(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.raleway(
            fontSize: 15,
            color: Colors.grey[400],
          ),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey[400], size: 20)
              : null,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  /// Gradient action button (Log In / Get Started)
  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: loading ? null : handleAuth,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFF8BBD0), // soft pink
              Color(0xFFCE93D8), // orchid
              Color(0xFFB39DDB), // lavender
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCE93D8).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isSignup ? 'Get Started' : 'Log In',
                  style: GoogleFonts.raleway(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }



  /// Social icon (Image asset version – for Google)
  Widget _socialIconButtonImage({
    required String assetPath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Image.asset(
            assetPath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../home/home.dart';           // If needed
import '../mentor/dashboard.dart';    // Mentor dashboard
import '../auth-mentor/mentor_onboarding.dart'; // Mentor Onboarding

// ─── Custom Wave Clipper ─────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 80);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height + 40,
      size.width,
      size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Concentric Arcs Painter ────────────────────────────────────────
class _ConcentricArcsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final center = Offset(size.width * 0.1, -size.height * 0.2);
    for (int i = 0; i < 35; i++) {
      final radius = 20.0 + i * 22.0;
      final opacity = (0.25 - i * 0.006).clamp(0.02, 0.25);
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Mentor Login Page ──────────────────────────────────────────────
class MentorLoginPage extends StatefulWidget {
  const MentorLoginPage({super.key});

  @override
  State<MentorLoginPage> createState() => _MentorLoginPageState();
}

class _MentorLoginPageState extends State<MentorLoginPage>
    with TickerProviderStateMixin {
  bool isSignup = false;
  bool _obscurePassword = true;
  bool loading = false;
  String error = '';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

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
      setState(() {
        isSignup = !isSignup;
        error = '';
      });
      _fadeController.forward();
    });
  }

  // ─── Email / Password Handler ─────────────────────────────────────
  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Please enter email and password');
      return;
    }
    if (isSignup && name.isEmpty) {
      setState(() => error = 'Please enter your full name');
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      if (isSignup) {
        debugPrint('🔐 Starting mentor signup...');

        final response = await Supabase.instance.client.auth.signUp(
          email: email,
          password: password,
          data: {
            'full_name': name,
            'role': 'mentor',
          },
        );

        if (response.user != null) {
          if (response.session == null) {
            setState(() => error = 'Account created! Please check your email for verification link.');
          } else {
            await _checkProfileAndNavigate(response.user!.id);
          }
        }
      } else {
        debugPrint('🔐 Starting mentor login...');

        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        if (response.session != null && response.user != null) {
          await _checkProfileAndNavigate(response.user!.id);
        }
      }
    } on AuthException catch (e) {
      debugPrint('❌ Auth Error: ${e.message}');
      setState(() => error = e.message);
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      setState(() => error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ─── Check if mentor profile exists → Onboarding or Dashboard ─────
  Future<void> _checkProfileAndNavigate(String userId) async {
    try {
      final mentorProfile = await Supabase.instance.client
          .from('mentors')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        if (mentorProfile == null) {
          // New mentor - go to onboarding
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MentorOnboardingPage()),
          );
        } else {
          // Existing mentor - go to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MentorDashboard()),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Profile check error: $e');
      // Fallback - go to dashboard if table query fails
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MentorDashboard()),
        );
      }
    }
  }

  // ─── OAuth Handler (Same as user login) ───────────────────────────
  Future<void> handleLogin(OAuthProvider provider) async {
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      // Note: Deep link listener in main.dart will handle session
      // You should handle role-based routing in a global Auth Listener
    } catch (e) {
      debugPrint('❌ OAuth Error: $e');
      if (mounted) {
        setState(() => error = 'Sign in with ${provider.name} failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildGradientHeader(screenHeight),

            FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),
                    Text(
                      isSignup ? 'Apply as Mentor' : 'Mentor Login',
                      style: GoogleFonts.raleway(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignup
                          ? "Join our elite community of mentors.\nHelp students reach their potential."
                          : "Welcome back to your mentor workspace.\nManage your impact and connections.",
                      style: GoogleFonts.raleway(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Name field only during signup
                    if (isSignup) ...[
                      _buildTextField(
                        controller: nameController,
                        hint: 'Enter full name',
                      ),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(
                      controller: emailController,
                      hint: 'Enter work email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: passwordController,
                      hint: isSignup ? 'Create password' : 'Password',
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
                    const SizedBox(height: 24),

                    _buildGradientButton(),
                    const SizedBox(height: 28),

                    // Social Login Divider
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            isSignup ? 'Sign up with' : 'Sign in with',
                            style: GoogleFonts.raleway(
                                fontSize: 13, color: Colors.grey[500]),
                          ),
                        ),
                        Expanded(child: Container(height: 1, color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _socialIconButtonImage(
                          assetPath: 'assets/discord.png',
                          onTap: () => handleLogin(OAuthProvider.discord),
                        ),
                        const SizedBox(width: 24),
                        _socialIconButtonImage(
                          assetPath: 'assets/search.png',
                          onTap: () => handleLogin(OAuthProvider.google),
                        ),
                        const SizedBox(width: 24),
                        _socialIconButtonImage(
                          assetPath: 'assets/slack.png',
                          onTap: () => handleLogin(OAuthProvider.slack),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Toggle Login / Signup
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSignup ? 'Already a mentor? ' : "Interested in mentoring? ",
                            style: GoogleFonts.raleway(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          GestureDetector(
                            onTap: _toggleMode,
                            child: Text(
                              isSignup ? 'Log In' : 'Apply Now',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF2563EB),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Back to Student Login
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Are you a Student? ',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Click here!',
                              style: GoogleFonts.raleway(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF5E9EF5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (error.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: Text(
                            error,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Reusable Widgets ───────────────────────────────────────────────
  Widget _buildGradientHeader(double screenHeight) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: screenHeight * 0.26,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.centerLeft,
            radius: 2.0,
            colors: [
              Color(0xFF1E293B),
              Color(0xFF1B2347),
              Color(0xFF2563EB),
              Color(0xFF8B5CF6),
            ],
            stops: [0.0, 0.4, 0.8, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ConcentricArcsPainter()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.raleway(fontSize: 15, color: Colors.black87),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.raleway(fontSize: 15, color: Colors.grey[400]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildGradientButton() {
    return GestureDetector(
      onTap: loading ? null : handleAuth,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1B2347)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.3),
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
                  isSignup ? 'Apply as Mentor' : 'Log In',
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
          border: Border.all(color: Colors.grey[100]!),
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
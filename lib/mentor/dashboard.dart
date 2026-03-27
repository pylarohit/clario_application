import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorDashboard extends StatefulWidget {
  const MentorDashboard({super.key});

  @override
  State<MentorDashboard> createState() => _MentorDashboardState();
}

class _MentorDashboardState extends State<MentorDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mentor Dashboard',
          style: GoogleFonts.raleway(
            color: const Color(0xFF1B2347),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rocket_launch_rounded, size: 80, color: Color(0xFF5E9EF5)),
            const SizedBox(height: 24),
            Text(
              'Welcome, Mentor!',
              style: GoogleFonts.raleway(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1B2347),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Setting up your professional workspace...',
              style: GoogleFonts.raleway(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// INSIGHTS REVEAL PAGE - Production Ready
// ========================================
// Displays quiz results with animated reveal
// Features:
// - Progressive insight revelation animation
// - Supabase integration for data persistence
// - Responsive design for all screen sizes
// - Next step guidance dialogs
// - Career advisor integration
// Fully responsive for mobile, tablet, and desktop
// ========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../home.dart';
import '../ai_career_coach/career_coach_page.dart';

class InsightsRevealPage extends StatefulWidget {
  final Map<String, dynamic> insights;
  final String userId;
  final String userName;
  final String currentStatus;
  final String mainFocus;
  final String? userAvatar;

  const InsightsRevealPage({
    super.key,
    required this.insights,
    required this.userId,
    required this.userName,
    required this.currentStatus,
    required this.mainFocus,
    this.userAvatar,
  });

  @override
  State<InsightsRevealPage> createState() => _InsightsRevealPageState();
}

class _InsightsRevealPageState extends State<InsightsRevealPage>
    with SingleTickerProviderStateMixin {
  // ========== RESPONSIVE BREAKPOINTS ==========
  static const double mobileBreakpoint = 600;
  static const double smallMobileBreakpoint = 380;
  static const double tabletBreakpoint = 900;

  // ========== STATE VARIABLES ==========
  // Track which insights have been revealed
  final Map<String, bool> _insightStates = {
    'stream': false,
    'interests': false,
    'degrees': false,
    'careers': false,
    'summary': false,
  };

  // Animation and loading states
  bool _isRevealing = true; // Whether insights are still being revealed
  bool _savingToDatabase = false; // Whether data is being saved to Supabase
  Timer? _revealTimer; // Timer for progressive reveal animation

  @override
  void initState() {
    super.initState();
    _startRevealAnimation();
  }

  void _startRevealAnimation() {
    final keys = _insightStates.keys.toList();
    int index = 0;

    _revealTimer = Timer.periodic(Duration(milliseconds: 800), (timer) {
      if (index < keys.length) {
        setState(() {
          _insightStates[keys[index]] = true;
        });
        index++;
      } else {
        timer.cancel();
        setState(() => _isRevealing = false);
      }
    });
  }

  // ========== DATA PERSISTENCE ==========

  /// Saves quiz insights to Supabase database
  /// Updates both userQuizData and users tables
  /// Shows completion dialog on success
  Future<void> _saveToSupabase() async {
    if (_savingToDatabase) return; // Prevent double submission

    setState(() => _savingToDatabase = true);

    try {
      final supabase = Supabase.instance.client;

      // Validate required data
      if (widget.userId.isEmpty) {
        throw Exception('User ID is empty. Please log in again.');
      }

      if (widget.insights.isEmpty) {
        throw Exception('No insights data available to save.');
      }

      debugPrint('User ID: ${widget.userId}');
      debugPrint('Quiz insights: ${widget.insights}');

      // Prepare insert data for userQuizData table
      final Map<String, dynamic> insertData = {
        'userId': widget.userId,
        'user_current_status': widget.currentStatus,
        'user_mainFocus': widget.mainFocus,
        'quizInfo': widget.insights,
        'userName': widget.userName,
      };

      // Only add userAvatar if it has a valid value
      if (widget.userAvatar != null && widget.userAvatar!.isNotEmpty) {
        insertData['userAvatar'] = widget.userAvatar;
      }

      debugPrint('Attempting to insert quiz data: $insertData');

      // Insert quiz data to userQuizData table
      final insertResponse = await supabase
          .from('userQuizData')
          .insert(insertData)
          .select();

      debugPrint('Insert response: $insertResponse');

      // Update users table - mark quiz as done
      final updateResponse = await supabase
          .from('users')
          .update({'isQuizDone': true})
          .eq('id', widget.userId)
          .select();

      debugPrint('Update response: $updateResponse');

      if (mounted) {
        // Show completion dialog
        _showCompletionDialog();
      }
    } catch (e) {
      debugPrint('Error saving quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving quiz: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingToDatabase = false);
      }
    }
  }

  // ========== UI DIALOGS ==========

  /// Shows completion dialog after successful save
  /// Provides option to continue or view dashboard
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        final isMobile = screenWidth < mobileBreakpoint;
        final isSmallMobile = screenWidth < smallMobileBreakpoint;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 16 : 24,
            vertical: isSmallMobile ? 20 : 24,
          ),
          child: Container(
            width: isMobile ? screenWidth * 0.9 : 600,
            constraints: BoxConstraints(
              maxWidth: isSmallMobile ? screenWidth * 0.95 : 600,
              maxHeight: screenHeight * (isSmallMobile ? 0.85 : 0.88),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      // Pop all routes back to home
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // Trigger HomePage refresh immediately and with delay for safety
                      HomePageState.triggerRefresh();
                      Future.delayed(Duration(milliseconds: 500), () {
                        HomePageState.triggerRefresh();
                      });
                    },
                    icon: Icon(Icons.close, size: 24),
                    padding: EdgeInsets.all(16),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isSmallMobile ? 20 : (isMobile ? 24 : 32),
                      0,
                      isSmallMobile ? 20 : (isMobile ? 24 : 32),
                      isSmallMobile ? 20 : (isMobile ? 24 : 32),
                    ),
                    child: Column(
                      children: [
                        // Success icon
                        Container(
                          width: isSmallMobile ? 60 : (isMobile ? 70 : 80),
                          height: isSmallMobile ? 60 : (isMobile ? 70 : 80),
                          decoration: BoxDecoration(
                            color: Color(0xFF5E9EF5).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle,
                            size: 48,
                            color: Color(0xFF5E9EF5),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Title
                        Text(
                          'Quiz Complete!',
                          style: GoogleFonts.inter(
                            fontSize: isSmallMobile ? 22 : (isMobile ? 24 : 28),
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2347),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isSmallMobile ? 10 : 12),

                        // Subtitle
                        Text(
                          'Congratulations on completing your personalized assessment!\nYour insights have been saved and your dashboard has been updated.',
                          style: GoogleFonts.inter(
                            fontSize: isSmallMobile ? 13 : (isMobile ? 14 : 16),
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(
                          height: isSmallMobile ? 28 : (isMobile ? 32 : 40),
                        ),

                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Close current dialog and show Next Step dialog
                              Navigator.of(context).pop();
                              _showNextStepDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF5E9EF5),
                              padding: EdgeInsets.symmetric(
                                vertical: isSmallMobile ? 14 : 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Continue',
                                  style: GoogleFonts.inter(
                                    fontSize: isSmallMobile ? 14 : 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: isSmallMobile ? 18 : 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Shows next step dialog with career advisor guidance
  /// Offers option to talk to AI advisor or set up later
  void _showNextStepDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final screenWidth = screenSize.width;
        final screenHeight = screenSize.height;
        final isMobile = screenWidth < mobileBreakpoint;
        final isSmallMobile = screenWidth < smallMobileBreakpoint;
        final isTablet =
            screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallMobile ? 16 : 20),
          ),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 16 : 24,
            vertical: isSmallMobile ? 24 : 40,
          ),
          child: Container(
            width: isMobile ? screenWidth * 0.95 : (isTablet ? 650 : 700),
            constraints: BoxConstraints(
              maxHeight: screenHeight * (isSmallMobile ? 0.88 : 0.9),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      HomePageState.triggerRefresh();
                      Future.delayed(Duration(milliseconds: 500), () {
                        HomePageState.triggerRefresh();
                      });
                    },
                    icon: Icon(Icons.close, size: isSmallMobile ? 20 : 24),
                    padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      isSmallMobile ? 16 : (isMobile ? 20 : 32),
                      0,
                      isSmallMobile ? 16 : (isMobile ? 20 : 32),
                      isSmallMobile ? 16 : (isMobile ? 20 : 32),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Image (only on desktop)
                        if (!isMobile)
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: EdgeInsets.only(right: 24),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFFC1CC),
                                        Color(0xFFFFE4E8),
                                      ],
                                    ),
                                  ),
                                  child: Image.asset(
                                    'assets/advisor.png',
                                    height: isTablet ? 400 : 500,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: isTablet ? 400 : 500,
                                        decoration: BoxDecoration(
                                          color: Color(
                                            0xFF5E9EF5,
                                          ).withValues(alpha: 0.05),
                                        ),
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 80,
                                                color: Color(
                                                  0xFF5E9EF5,
                                                ).withValues(alpha: 0.3),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                'Image not available',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Right side - Content
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Info icon
                              Container(
                                width: isSmallMobile ? 50 : 60,
                                height: isSmallMobile ? 50 : 60,
                                decoration: BoxDecoration(
                                  color: Color(0xFF5E9EF5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  size: isSmallMobile ? 26 : 32,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: isSmallMobile ? 16 : 20),

                              // Title
                              Text(
                                'Next Step!',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallMobile
                                      ? 22
                                      : (isMobile ? 24 : 32),
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2347),
                                ),
                              ),
                              SizedBox(height: isSmallMobile ? 12 : 16),

                              // Description
                              Text(
                                'Now its time to decide your Career Path. AI powered career adviser will guide you through the process.',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallMobile
                                      ? 13
                                      : (isMobile ? 14 : 15),
                                  color: Colors.grey[700],
                                  height: 1.6,
                                ),
                              ),
                              SizedBox(height: isSmallMobile ? 24 : 32),

                              // What You Need To Do section
                              Text(
                                'What You Need To Do:',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallMobile ? 16 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B2347),
                                ),
                              ),
                              SizedBox(height: isSmallMobile ? 14 : 20),

                              // Step 1
                              _buildStepCard(
                                number: '1',
                                title: 'Say Hello',
                                description: 'Greet your AI Career Adviser.',
                                color: Color(0xFF5E9EF5),
                                isMobile: isMobile,
                                isSmallMobile: isSmallMobile,
                              ),
                              SizedBox(height: isSmallMobile ? 10 : 12),

                              // Step 2
                              _buildStepCard(
                                number: '2',
                                title: 'Ask Bout Your Career',
                                description:
                                    'Ask your confusion and career options according to your interests.',
                                color: Color(0xFF9C27B0),
                                isMobile: isMobile,
                                isSmallMobile: isSmallMobile,
                              ),
                              SizedBox(height: isSmallMobile ? 10 : 12),

                              // Step 3
                              _buildStepCard(
                                number: '3',
                                title: 'Select your career',
                                description:
                                    'After getting career options, tell your AI Career Adviser about desired career that suits you the best.',
                                color: Color(0xFF00BFA5),
                                isMobile: isMobile,
                                isSmallMobile: isSmallMobile,
                              ),
                              SizedBox(height: isSmallMobile ? 24 : 32),

                              // Buttons
                              Flex(
                                direction: isSmallMobile
                                    ? Axis.vertical
                                    : Axis.horizontal,
                                children: [
                                  Expanded(
                                    flex: isSmallMobile ? 0 : 1,
                                    child: SizedBox(
                                      width: isSmallMobile
                                          ? double.infinity
                                          : null,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // Get the root navigator
                                          final rootNavigator = Navigator.of(
                                            context,
                                            rootNavigator: true,
                                          );

                                          // Close dialog
                                          Navigator.of(context).pop();

                                          // Pop all quiz/insights routes back to home
                                          rootNavigator.popUntil(
                                            (route) => route.isFirst,
                                          );

                                          // Refresh home page
                                          HomePageState.triggerRefresh();

                                          // Navigate to Career Coach page with delay
                                          Future.delayed(
                                            Duration(milliseconds: 400),
                                            () {
                                              rootNavigator.push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      CareerCoachPage(),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF5E9EF5),
                                          padding: EdgeInsets.symmetric(
                                            vertical: isSmallMobile ? 14 : 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Talk to AI Adviser',
                                                style: GoogleFonts.inter(
                                                  fontSize: isSmallMobile
                                                      ? 13
                                                      : 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: isSmallMobile ? 16 : 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: isSmallMobile ? 0 : 12,
                                    height: isSmallMobile ? 12 : 0,
                                  ),
                                  Expanded(
                                    flex: isSmallMobile ? 0 : 1,
                                    child: SizedBox(
                                      width: isSmallMobile
                                          ? double.infinity
                                          : null,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // Go to dashboard
                                          Navigator.of(context).pop();
                                          Navigator.of(
                                            context,
                                          ).popUntil((route) => route.isFirst);
                                          HomePageState.triggerRefresh();
                                          Future.delayed(
                                            Duration(milliseconds: 500),
                                            () {
                                              HomePageState.triggerRefresh();
                                            },
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: EdgeInsets.symmetric(
                                            vertical: isSmallMobile ? 14 : 16,
                                          ),
                                          side: BorderSide(
                                            color: Color(0xFF5E9EF5),
                                            width: 1.5,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Set up Later',
                                                style: GoogleFonts.inter(
                                                  fontSize: isSmallMobile
                                                      ? 13
                                                      : 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF5E9EF5),
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward,
                                              color: Color(0xFF5E9EF5),
                                              size: isSmallMobile ? 16 : 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== UI HELPER WIDGETS ==========

  /// Builds a step card showing what user needs to do
  /// Used in the next step dialog
  Widget _buildStepCard({
    required String number,
    required String title,
    required String description,
    required Color color,
    required bool isMobile,
    required bool isSmallMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(isSmallMobile ? 10 : 12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: isSmallMobile ? 32 : 36,
            height: isSmallMobile ? 32 : 36,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: isSmallMobile ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 14 : (isMobile ? 15 : 16),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2347),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 12 : (isMobile ? 13 : 14),
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  // ========== MAIN BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    // Responsive padding and spacing
    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    final cardSpacing = isSmallMobile ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      // ========== APP BAR ==========
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Your Insights',
          style: GoogleFonts.inter(
            color: Color(0xFF1B2347),
            fontWeight: FontWeight.w600,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
      ),
      // ========== MAIN CONTENT ==========
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Text(
                'Analyzing Your Responses',
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 20 : (isMobile ? 22 : 24),
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                ),
              ),
              SizedBox(height: 8),
              Text(
                _isRevealing
                    ? 'Please wait while we process your quiz...'
                    : 'Here are your personalized insights',
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 13 : 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: isSmallMobile ? 24 : 32),

              // ===== INSIGHTS CARDS =====
              _buildInsightCard(
                'stream',
                'Educational Stream',
                widget.insights['stream']?.toString() ?? 'Not available',
                Icons.school,
                Color(0xFF5E9EF5),
                isMobile,
                isSmallMobile,
              ),
              SizedBox(height: cardSpacing),

              _buildInsightCard(
                'interests',
                'Main Interest',
                widget.insights['Interest']?.toString() ?? 'Not available',
                Icons.favorite,
                Color(0xFFE91E63),
                isMobile,
                isSmallMobile,
              ),
              SizedBox(height: cardSpacing),

              _buildInsightCard(
                'degrees',
                'Recommended Degrees',
                _formatList(widget.insights['degree']),
                Icons.emoji_events,
                Color(0xFFFF9800),
                isMobile,
                isSmallMobile,
              ),
              SizedBox(height: cardSpacing),

              _buildInsightCard(
                'careers',
                'Career Options',
                _formatList(widget.insights['careerOptions']),
                Icons.work,
                Color(0xFF00BFA5),
                isMobile,
                isSmallMobile,
              ),
              SizedBox(height: cardSpacing),

              _buildInsightCard(
                'summary',
                'Summary',
                widget.insights['summary']?.toString() ?? 'Not available',
                Icons.description,
                Color(0xFF9C27B0),
                isMobile,
                isSmallMobile,
              ),
              SizedBox(height: isSmallMobile ? 24 : 32),

              // ===== COMPLETION MESSAGE =====
              if (!_isRevealing)
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5E9EF5), Color(0xFF00BFA5)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: isSmallMobile ? 40 : 48,
                      ),
                      SizedBox(height: isSmallMobile ? 10 : 12),
                      Text(
                        'Analysis Complete!',
                        style: GoogleFonts.inter(
                          fontSize: isSmallMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your personalized insights are ready',
                        style: GoogleFonts.inter(
                          fontSize: isSmallMobile ? 13 : 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // ===== ACTION BUTTON =====
              if (!_isRevealing)
                Container(
                  margin: EdgeInsets.only(top: isSmallMobile ? 20 : 24),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _savingToDatabase ? null : _saveToSupabase,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5E9EF5),
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallMobile ? 14 : 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _savingToDatabase
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: isSmallMobile ? 18 : 20,
                                height: isSmallMobile ? 18 : 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Saving...',
                                style: GoogleFonts.inter(
                                  fontSize: isSmallMobile ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Confirm & Continue',
                            style: GoogleFonts.inter(
                              fontSize: isSmallMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an animated insight card
  /// Shows loading, then reveals content with animation
  Widget _buildInsightCard(
    String key,
    String title,
    String content,
    IconData icon,
    Color color,
    bool isMobile,
    bool isSmallMobile,
  ) {
    final isCompleted = _insightStates[key] ?? false;
    final isAnimating = _isRevealing && !isCompleted;

    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: isCompleted ? 1.0 : 0.3,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.white : Colors.grey[100],
          border: Border.all(
            color: isCompleted ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isCompleted
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isSmallMobile ? 36 : 40,
                  height: isSmallMobile ? 36 : 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isSmallMobile ? 20 : 24,
                  ),
                ),
                SizedBox(width: isSmallMobile ? 10 : 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isSmallMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B2347),
                    ),
                  ),
                ),
                if (isAnimating)
                  SizedBox(
                    width: isSmallMobile ? 18 : 20,
                    height: isSmallMobile ? 18 : 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else if (isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: color,
                    size: isSmallMobile ? 20 : 24,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: Colors.grey[400],
                    size: isSmallMobile ? 20 : 24,
                  ),
              ],
            ),
            if (isCompleted) ...[
              SizedBox(height: isSmallMobile ? 10 : 12),
              Text(
                content,
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 13 : 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatList(dynamic value) {
    if (value == null) return 'Not available';
    if (value is List) {
      if (value.isEmpty) return 'Not available';
      return value.join('\n• ');
    }
    return value.toString();
  }
}

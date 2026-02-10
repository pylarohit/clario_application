import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_page.dart';

class QuizStartDialog extends StatelessWidget {
  final String currentStatus;
  final String mainFocus;
  final String userName;
  final String userId;
  final String? userAvatar;

  const QuizStartDialog({
    super.key,
    required this.currentStatus,
    required this.mainFocus,
    required this.userName,
    required this.userId,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: isMobile ? screenWidth * 0.9 : 450,
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: isMobile ? MediaQuery.of(context).size.height * 0.7 : 600,
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, size: 24),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            
            SizedBox(height: isMobile ? 8 : 16),

            // Title
            Text(
              'Ready to start your quiz?',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 22 : 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2347),
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isMobile ? 12 : 16),

            // Subtitle
            Text(
              'This will help us generate personalized insights, customized roadmaps, and better career options for you.',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 15,
                color: Colors.black,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: isMobile ? 20 : 32),

            // Image placeholder (person with arms crossed)
            Container(
              height: isMobile ? 220 : 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/element1.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            SizedBox(height: isMobile ? 20 : 32),

            // Buttons
            Row(
              children: [
                // Cancel button
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 14 : 16,
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B2347),
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.close,
                          size: isMobile ? 16 : 18,
                          color: Color(0xFF1B2347),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                // Start Quiz button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(
                            currentStatus: currentStatus,
                            mainFocus: mainFocus,
                            userName: userName,
                            userId: userId,
                            userAvatar: userAvatar,
                          ),
                        ),
                      );
                      
                      // If quiz was completed, trigger a refresh on the parent
                      if (result == true && context.mounted) {
                        // The HomePage will auto-refresh via didChangeDependencies
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5E9EF5),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isMobile ? 14 : 16,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start Quiz',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 14 : 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward,
                          size: isMobile ? 16 : 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required String currentStatus,
    required String mainFocus,
    required String userName,
    required String userId,
    String? userAvatar,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => QuizStartDialog(
        currentStatus: currentStatus,
        mainFocus: mainFocus,
        userName: userName,
        userId: userId,
        userAvatar: userAvatar,
      ),
    );
  }
}

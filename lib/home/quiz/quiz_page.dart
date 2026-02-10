// ============================================================================
// QUIZ PAGE - Personalized Career Assessment
// ============================================================================
// This page provides an interactive quiz experience for students to discover
// their career paths based on their current status, interests, and goals.
// Features: Progress tracking, dynamic questions, responsive design, AI insights
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz_data.dart';
import 'insights_reveal_page.dart';

class QuizPage extends StatefulWidget {
  final String currentStatus;
  final String mainFocus;
  final String userName;
  final String userId;
  final String? userAvatar;

  const QuizPage({
    super.key,
    required this.currentStatus,
    required this.mainFocus,
    required this.userName,
    required this.userId,
    this.userAvatar,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // ========== RESPONSIVE BREAKPOINTS ==========
  static const double mobileBreakpoint = 600;
  static const double smallMobileBreakpoint = 380;

  // ========== STATE VARIABLES ==========
  /// Current question index (0-based)
  int _step = 0;

  /// Whether quiz has been started
  bool _started = false;

  /// Whether all questions have been answered
  bool _finished = false;

  /// Loading state during AI analysis
  bool _loading = false;

  /// User answers: `Map<section, Map<questionIndex, answer>>`
  Map<String, Map<int, String>> _answers = {};

  /// Flattened list of all questions for current user
  late List<Map<String, dynamic>> _allQuestions;

  @override
  void initState() {
    super.initState();
    _allQuestions = QuizData.getFlattenedQuestions(
      widget.currentStatus,
      widget.mainFocus,
    );
  }

  // ========== ANSWER MANAGEMENT ==========

  /// Saves user's answer for the current question
  void _saveAnswer(String value) {
    if (_step >= _allQuestions.length) return;

    final currentQ = _allQuestions[_step];
    setState(() {
      if (!_answers.containsKey(currentQ['section'])) {
        _answers[currentQ['section']] = {};
      }
      _answers[currentQ['section']]![currentQ['index']] = value;
    });
  }

  /// Handles quiz submission and navigation to insights page
  Future<void> _handleSubmit() async {
    if (_loading) return; // Prevent double submission

    setState(() => _loading = true);

    try {
      // Prepare quiz data
      final result = _allQuestions.map((q) {
        final section = q['section'];
        final index = q['index'];
        final question = q['question'] as QuizQuestion;
        return {
          'section': section,
          'question': question.question,
          'answer': _answers[section]?[index] ?? '',
        };
      }).toList();

      
      // For now, we'll simulate the AI response
      final insights = await _simulateAIResponse(result);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InsightsRevealPage(
              insights: insights,
              userId: widget.userId,
              userName: widget.userName,
              currentStatus: widget.currentStatus,
              mainFocus: widget.mainFocus,
              userAvatar: widget.userAvatar,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ========== AI INSIGHTS GENERATION ==========

  /// Generates personalized career insights based on quiz responses
  ///
  /// This method analyzes user answers to provide:
  /// - Educational stream recommendation
  /// - Interest identification
  /// - Degree suggestions
  /// - Career path options
  /// - Comprehensive career summary
  ///
  
  Future<Map<String, dynamic>> _simulateAIResponse(
    List<dynamic> quizData,
  ) async {
    // Simulate network delay
    await Future.delayed(Duration(seconds: 2));

    // Extract key answers from quiz
    Map<String, String> keyAnswers = {};
    for (var qa in quizData) {
      String question = qa['question'].toString().toLowerCase();
      String answer = qa['answer'].toString();

      if (question.contains('which stream')) {
        keyAnswers['stream'] = answer;
      }
      if (question.contains('confident')) {
        keyAnswers['confidence'] = answer;
      }
      if (question.contains('why did you choose')) {
        keyAnswers['reason'] = answer;
      }
      if (question.contains('additional skill') ||
          question.contains('skills are you most interested')) {
        keyAnswers['skill_interest'] = answer;
      }
      if (question.contains('college do you prefer')) {
        keyAnswers['college_preference'] = answer;
      }
      if (question.contains('interests and hobbies')) {
        keyAnswers['hobbies'] = answer;
      }
      if (question.contains('biggest confusion')) {
        keyAnswers['confusion'] = answer;
      }
      if (question.contains('matters most')) {
        keyAnswers['career_priority'] = answer;
      }
      if (question.contains('activities excite you')) {
        keyAnswers['activity_preference'] = answer;
      }
      if (question.contains('motivates you')) {
        keyAnswers['motivation'] = answer;
      }
      if (question.contains('learn skills better')) {
        keyAnswers['learning_style'] = answer;
      }
    }

    // Determine stream
    String stream =
        keyAnswers['stream'] ?? _determineStream(widget.currentStatus);

    // Determine interests based on actual answers
    String interests = _determineInterests(keyAnswers);

    // Suggest degrees based on stream and interests
    List<String> degrees = _suggestDegrees(stream, keyAnswers);

    // Suggest career options based on answers
    List<String> careerOptions = _suggestCareers(stream, keyAnswers);

    // Generate AI summary
    String summary = _generateSummary(stream, keyAnswers);

    return {
      'stream': stream,
      'Interest': interests,
      'degree': degrees,
      'careerOptions': careerOptions,
      'summary': summary,
    };
  }

  String _determineStream(String status) {
    if (status.toLowerCase().contains('12th')) {
      return 'Science';
    } else if (status.toLowerCase().contains('graduate')) {
      return 'Engineering / Technology';
    }
    return 'General';
  }

  String _determineInterests(Map<String, String> keyAnswers) {
    List<String> interests = [];

    // Based on skill interest
    String skillInterest = keyAnswers['skill_interest']?.toLowerCase() ?? '';
    if (skillInterest.contains('technical')) {
      interests.add('Technical');
      interests.add('coding');
      interests.add('problem-solving tasks');
    } else if (skillInterest.contains('creative')) {
      interests.add('Creative design');
      interests.add('artistic projects');
    } else if (skillInterest.contains('sports')) {
      interests.add('Sports');
      interests.add('fitness');
    } else if (skillInterest.contains('entrepreneurship')) {
      interests.add('Business');
      interests.add('entrepreneurship');
      interests.add('leadership');
    } else if (skillInterest.contains('communication')) {
      interests.add('Communication');
      interests.add('public speaking');
    }

    // Based on activity preference
    String activityPref =
        keyAnswers['activity_preference']?.toLowerCase() ?? '';
    if (activityPref.contains('problem-solving')) {
      interests.add('problem-solving tasks');
    } else if (activityPref.contains('creative')) {
      interests.add('creative projects');
    } else if (activityPref.contains('helping')) {
      interests.add('helping people');
    } else if (activityPref.contains('leadership')) {
      interests.add('leadership roles');
    }

    // Based on hobbies
    String hobbies = keyAnswers['hobbies']?.toLowerCase() ?? '';
    if (hobbies.contains('coding') || hobbies.contains('programming')) {
      interests.add('coding');
    }
    if (hobbies.contains('reading')) {
      interests.add('reading');
    }
    if (hobbies.contains('music') || hobbies.contains('art')) {
      interests.add('arts');
    }

    if (interests.isEmpty) {
      interests = ['General academic pursuits'];
    }

    // Remove duplicates and join
    return interests.toSet().toList().join(', ');
  }

  List<String> _suggestDegrees(String stream, Map<String, String> keyAnswers) {
    List<String> degrees = [];
    String streamLower = stream.toLowerCase();
    String skillInterest = keyAnswers['skill_interest']?.toLowerCase() ?? '';

    if (streamLower.contains('science')) {
      if (skillInterest.contains('technical')) {
        degrees = ['B.Tech', 'B.Sc', 'M.Tech'];
      } else if (skillInterest.contains('creative')) {
        degrees = ['B.Sc (Design)', 'BFA', 'B.Des'];
      } else {
        degrees = ['B.Tech', 'B.Sc', 'M.Tech'];
      }
    } else if (streamLower.contains('commerce')) {
      degrees = ['B.Com', 'BBA', 'CA', 'MBA'];
    } else if (streamLower.contains('arts')) {
      degrees = ['BA', 'BFA', 'B.Des', 'MA'];
    } else if (streamLower.contains('medical')) {
      degrees = ['MBBS', 'BDS', 'BAMS', 'BHMS', 'B.Pharm'];
    } else if (streamLower.contains('engineering')) {
      String activityPref =
          keyAnswers['activity_preference']?.toLowerCase() ?? '';
      if (activityPref.contains('problem-solving') ||
          skillInterest.contains('technical')) {
        degrees = [
          'M.Tech (Computer Science)',
          'M.Tech (AI/ML)',
          'MS in Data Science',
        ];
      } else if (activityPref.contains('leadership')) {
        degrees = [
          'MBA (Technology Management)',
          'M.Tech + MBA Dual',
          'Executive MBA',
        ];
      } else {
        degrees = ['M.Tech', 'MS', 'MBA'];
      }
    } else {
      degrees = ['B.Tech', 'B.Sc', 'BBA', 'B.Com'];
    }

    return degrees;
  }

  List<String> _suggestCareers(String stream, Map<String, String> keyAnswers) {
    List<String> careers = [];
    String streamLower = stream.toLowerCase();
    String skillInterest = keyAnswers['skill_interest']?.toLowerCase() ?? '';
    String activityPref =
        keyAnswers['activity_preference']?.toLowerCase() ?? '';
    String careerPriority = keyAnswers['career_priority']?.toLowerCase() ?? '';

    // Science/Technical stream
    if (streamLower.contains('science') ||
        skillInterest.contains('technical')) {
      if (activityPref.contains('problem-solving')) {
        careers = [
          'Software Engineer',
          'Data Scientist',
          'IT Consultant',
          'Cyber Security Specialist',
          'Technical Writer',
        ];
      } else if (activityPref.contains('creative')) {
        careers = [
          'UI/UX Designer',
          'Product Designer',
          'Game Developer',
          'Web Designer',
          'Mobile App Developer',
        ];
      } else {
        careers = [
          'Software Engineer',
          'Data Analyst',
          'IT Consultant',
          'Network Engineer',
          'Database Administrator',
        ];
      }
    }
    // Commerce stream
    else if (streamLower.contains('commerce')) {
      if (careerPriority.contains('high income')) {
        careers = [
          'Investment Banker',
          'Financial Analyst',
          'Chartered Accountant',
          'Management Consultant',
          'Corporate Lawyer',
        ];
      } else if (activityPref.contains('leadership')) {
        careers = [
          'Business Manager',
          'Operations Manager',
          'HR Manager',
          'Marketing Manager',
          'Entrepreneur',
        ];
      } else {
        careers = [
          'Accountant',
          'Financial Analyst',
          'Business Analyst',
          'Auditor',
          'Tax Consultant',
        ];
      }
    }
    // Arts/Creative stream
    else if (streamLower.contains('arts') ||
        skillInterest.contains('creative')) {
      careers = [
        'Graphic Designer',
        'Content Writer',
        'Digital Marketer',
        'Film Maker',
        'Art Director',
        'Social Media Manager',
      ];
    }
    // Medical stream
    else if (streamLower.contains('medical')) {
      careers = [
        'Doctor',
        'Surgeon',
        'Dentist',
        'Pharmacist',
        'Medical Researcher',
        'Healthcare Administrator',
      ];
    }
    // Engineering/Graduate
    else if (streamLower.contains('engineering') ||
        widget.currentStatus.toLowerCase().contains('graduate')) {
      if (skillInterest.contains('entrepreneurship') ||
          activityPref.contains('leadership')) {
        careers = [
          'Product Manager',
          'Startup Founder',
          'Business Consultant',
          'Technical Lead',
          'CTO',
        ];
      } else if (careerPriority.contains('high income')) {
        careers = [
          'Software Architect',
          'Data Scientist',
          'ML Engineer',
          'Cloud Solutions Architect',
          'Blockchain Developer',
        ];
      } else {
        careers = [
          'Software Engineer',
          'Full Stack Developer',
          'DevOps Engineer',
          'Data Engineer',
          'Product Manager',
        ];
      }
    }
    // Default
    else {
      careers = [
        'Software Engineer',
        'Data Analyst',
        'Business Analyst',
        'Product Manager',
      ];
    }

    return careers;
  }

  String _generateSummary(String stream, Map<String, String> keyAnswers) {
    String confidence = keyAnswers['confidence']?.toLowerCase() ?? 'neutral';
    String reason = keyAnswers['reason'] ?? 'career growth';
    String motivation =
        keyAnswers['motivation']?.toLowerCase() ?? 'personal growth';
    String collegePreference =
        keyAnswers['college_preference'] ?? 'reputed institutions';
    String confusion = keyAnswers['confusion']?.toLowerCase() ?? '';
    String careerPriority =
        keyAnswers['career_priority']?.toLowerCase() ?? 'career growth';
    String skillInterest = keyAnswers['skill_interest'] ?? 'technical skills';

    // Determine confidence level
    String confidenceLevel = 'neutral';
    if (confidence.contains('very confident')) {
      confidenceLevel = 'high';
    } else if (confidence.contains('not confident') ||
        confidence.contains('unsure')) {
      confidenceLevel = 'low';
    }

    // Build summary
    StringBuffer summary = StringBuffer();
    summary.write(
      'The student is in the $stream stream with a $confidenceLevel confidence level. ',
    );

    if (reason.toLowerCase().contains('passion')) {
      summary.write('They chose this stream for their passion and interest. ');
    } else if (reason.toLowerCase().contains('salary') ||
        reason.toLowerCase().contains('high')) {
      summary.write('They chose this stream for high salary prospects. ');
    } else if (reason.toLowerCase().contains('social')) {
      summary.write('They chose this stream to make a social impact. ');
    } else {
      summary.write('They chose this stream based on various factors. ');
    }

    summary.write('They are interested in $skillInterest and ');

    if (careerPriority.contains('passion')) {
      summary.write('prefer following their passion. ');
    } else if (careerPriority.contains('income') ||
        careerPriority.contains('salary')) {
      summary.write('prioritize high income. ');
    } else if (careerPriority.contains('balance')) {
      summary.write('value work-life balance. ');
    } else {
      summary.write('seek job security. ');
    }

    summary.write(
      'The student prefers ${collegePreference.toLowerCase()} colleges ',
    );

    if (motivation.contains('money') || motivation.contains('earning')) {
      summary.write('and is motivated by earning money. ');
    } else if (motivation.contains('recognition') ||
        motivation.contains('respect')) {
      summary.write('and is motivated by earning recognition. ');
    } else if (motivation.contains('difference')) {
      summary.write('and is motivated by making a difference in society. ');
    } else {
      summary.write('and is motivated by personal growth. ');
    }

    if (confidenceLevel == 'low' ||
        confusion.contains('lack of guidance') ||
        confusion.contains('too many choices')) {
      summary.write(
        'They are confused about career choices due to a lack of guidance.',
      );
    } else {
      summary.write(
        'They have a clear understanding of their career direction.',
      );
    }

    return summary.toString();
  }

  // ========== MAIN BUILD METHOD ==========

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return _buildWelcomeScreen();
    }

    if (_finished) {
      return _buildFinishedScreen();
    }

    return _buildQuizScreen();
  }

  // ========== WELCOME SCREEN ==========

  Widget _buildWelcomeScreen() {
    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    final iconSize = isSmallMobile ? 60.0 : 80.0;
    final titleSize = isSmallMobile ? 22.0 : (isMobile ? 26.0 : 28.0);
    final subtitleSize = isSmallMobile ? 14.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1B2347)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quiz icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Color(0xFF5E9EF5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.quiz,
                  size: iconSize * 0.5,
                  color: Color(0xFF5E9EF5),
                ),
              ),
              SizedBox(height: isSmallMobile ? 16 : 24),

              // Title
              Text(
                'Welcome to Your Quiz',
                style: GoogleFonts.inter(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallMobile ? 8 : 12),

              // Subtitle
              Text(
                'Personalized assessment for your academic journey',
                style: GoogleFonts.inter(
                  fontSize: subtitleSize,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallMobile ? 24 : 40),

              // User info card
              Container(
                padding: EdgeInsets.all(isSmallMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: Color(0xFFE8F5FF),
                  border: Border.all(color: Color(0xFF5E9EF5)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.inter(
                        fontSize: isSmallMobile ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2347),
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? 12 : 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Current Status: ',
                          style: GoogleFonts.inter(
                            fontSize: isSmallMobile ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            widget.currentStatus,
                            style: GoogleFonts.inter(
                              fontSize: isSmallMobile ? 12 : 14,
                              color: Color(0xFF5E9EF5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Main Focus: ',
                          style: GoogleFonts.inter(
                            fontSize: isSmallMobile ? 12 : 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            widget.mainFocus,
                            style: GoogleFonts.inter(
                              fontSize: isSmallMobile ? 12 : 14,
                              color: Color(0xFF5E9EF5),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: isSmallMobile ? 24 : 40),

              // Start button
              SizedBox(
                width: double.infinity,
                height: isSmallMobile ? 48 : 50,
                child: ElevatedButton(
                  onPressed: () => setState(() => _started = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF5E9EF5),
                    foregroundColor: Colors.white,
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
    );
  }

  // ========== QUIZ SCREEN ==========

  Widget _buildQuizScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);

    // Handle empty questions state
    if (_allQuestions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz'),
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: Colors.black.withValues(alpha: 0.1),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(0xFF1B2347)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: isSmallMobile ? 48 : 64,
                  color: Colors.red[300],
                ),
                SizedBox(height: isSmallMobile ? 12 : 16),
                Text(
                  'No questions available',
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2347),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We couldn\'t find quiz questions for:',
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isSmallMobile ? 12 : 16),
                Container(
                  padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Status: ',
                            style: GoogleFonts.inter(
                              fontSize: isSmallMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '"${widget.currentStatus}"',
                              style: GoogleFonts.inter(
                                fontSize: isSmallMobile ? 12 : 14,
                                color: Color(0xFF5E9EF5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Focus: ',
                            style: GoogleFonts.inter(
                              fontSize: isSmallMobile ? 12 : 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '"${widget.mainFocus}"',
                              style: GoogleFonts.inter(
                                fontSize: isSmallMobile ? 12 : 14,
                                color: Color(0xFF5E9EF5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isSmallMobile ? 12 : 16),
                Text(
                  'Please check the browser console for available quiz options.',
                  style: GoogleFonts.inter(
                    fontSize: isSmallMobile ? 10 : 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentQ = _allQuestions[_step];
    final question = currentQ['question'] as QuizQuestion;
    final progress = ((_step + 1) / _allQuestions.length) * 100;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1B2347)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${_step + 1} of ${_allQuestions.length}',
                        style: GoogleFonts.inter(
                          fontSize: isSmallMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${progress.toInt()}% completed',
                        style: GoogleFonts.inter(
                          fontSize: isSmallMobile ? 10 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Color(0xFFE8F5FF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF5E9EF5),
                    ),
                    minHeight: isSmallMobile ? 6 : 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),

            // Question content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.question,
                      style: GoogleFonts.inter(
                        fontSize: isSmallMobile ? 18 : (isMobile ? 20 : 22),
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2347),
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? 8 : 12),
                    Text(
                      'Section: ${currentQ['section'].toString().replaceAll('_', ' ')}',
                      style: GoogleFonts.inter(
                        fontSize: isSmallMobile ? 12 : 14,
                        color: Color(0xFF5E9EF5),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Note: Your selection will help improve platform experience.',
                      style: GoogleFonts.inter(
                        fontSize: isSmallMobile ? 10 : 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? 20 : 32),

                    // Options or text input
                    if (question.options != null)
                      ...question.options!.map((opt) {
                        final isSelected =
                            _answers[currentQ['section']]?[currentQ['index']] ==
                            opt;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isSmallMobile ? 8 : 12,
                          ),
                          child: InkWell(
                            onTap: () => _saveAnswer(opt),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Color(0xFF5E9EF5)
                                    : Colors.grey[50],
                                border: Border.all(
                                  color: isSelected
                                      ? Color(0xFF5E9EF5)
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                opt,
                                style: GoogleFonts.inter(
                                  fontSize: isSmallMobile ? 14 : 16,
                                  color: isSelected
                                      ? Colors.white
                                      : Color(0xFF1B2347),
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                    else
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Type your answer...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 5,
                        textDirection: TextDirection.ltr,
                        onChanged: (value) {
                          _saveAnswer(value);
                        },
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text:
                                _answers[currentQ['section']]?[currentQ['index']] ??
                                '',
                            selection: TextSelection.collapsed(
                              offset:
                                  (_answers[currentQ['section']]?[currentQ['index']] ??
                                          '')
                                      .length,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Container(
              padding: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_step > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(
                          () => _step = (_step - 1).clamp(
                            0,
                            _allQuestions.length - 1,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallMobile ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: isSmallMobile ? 18 : 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Back',
                              style: GoogleFonts.inter(
                                fontSize: isSmallMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_step > 0) SizedBox(width: 12),
                  Expanded(
                    flex: _step == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed:
                          _answers[currentQ['section']]?[currentQ['index']] !=
                              null
                          ? () {
                              if (_step < _allQuestions.length - 1) {
                                setState(() => _step++);
                              } else {
                                setState(() => _finished = true);
                              }
                            }
                          : null,
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
                        children: [
                          Text(
                            _step < _allQuestions.length - 1
                                ? 'Next'
                                : 'Finish',
                            style: GoogleFonts.inter(
                              fontSize: isSmallMobile ? 14 : 16,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: isSmallMobile ? 18 : 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
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

  // ========== FINISHED SCREEN ==========

  Widget _buildFinishedScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    final horizontalPadding = isSmallMobile ? 16.0 : (isMobile ? 20.0 : 24.0);
    final iconSize = isSmallMobile ? 80.0 : 100.0;
    final titleSize = isSmallMobile ? 24.0 : 28.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Color(0xFF00BFA5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: iconSize * 0.6,
                  color: Color(0xFF00BFA5),
                ),
              ),
              SizedBox(height: isSmallMobile ? 16 : 24),

              Text(
                'Quiz Completed!',
                style: GoogleFonts.inter(
                  fontSize: titleSize,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                ),
              ),
              SizedBox(height: isSmallMobile ? 8 : 12),

              Text(
                'Great job ${widget.userName}! You have reached the end of the quiz.',
                style: GoogleFonts.inter(
                  fontSize: isSmallMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallMobile ? 24 : 40),

              if (_loading)
                Column(
                  children: [
                    SizedBox(
                      width: isSmallMobile ? 32 : 40,
                      height: isSmallMobile ? 32 : 40,
                      child: CircularProgressIndicator(
                        strokeWidth: isSmallMobile ? 3 : 4,
                      ),
                    ),
                    SizedBox(height: isSmallMobile ? 12 : 16),
                    Text(
                      'Analyzing your responses...',
                      style: GoogleFonts.inter(
                        fontSize: isSmallMobile ? 14 : 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _answers = {};
                            _step = 0;
                            _started = false;
                            _finished = false;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallMobile ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retake Quiz',
                          style: GoogleFonts.inter(
                            fontSize: isSmallMobile ? 14 : 16,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF5E9EF5),
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallMobile ? 14 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit Quiz',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isSmallMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

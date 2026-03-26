// ============================================================================
// AI CAREER COACH PAGE - Production-Ready Intelligent Career Guidance System
// ============================================================================
// PURPOSE: Provides AI-powered career coaching with personalized guidance
// FEATURES:
//  - Real-time conversational AI using Google Gemini 2.5 Flash
//  - Automatic career path extraction and database persistence
//  - Context-aware responses based on user profile and quiz completion
//  - Follow-up question generation for deeper exploration
//  - Fully responsive design (mobile, tablet, desktop)
//  - Search limit tracking and user authentication
// DEPENDENCIES: flutter_dotenv, google_generative_ai, supabase_flutter
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// ============================================================================
// DATA MODELS & CONSTANTS
// ============================================================================

/// Message role enum for type-safe message identification
enum MessageRole { user, ai }

/// Message data model representing conversation between user and AI
/// Used to maintain chat history and display conversation flow
class Message {
  final MessageRole role;
  final String text;
  final List<String>? followUpQuestions;

  const Message({
    required this.role,
    required this.text,
    this.followUpQuestions,
  });
}

/// Application-wide constants for UI consistency
class AppConstants {
  // Color palette
  static const Color primaryBlue = Color(0xFF5E9EF5);
  static const Color darkBlue = Color(0xFF1B2347);
  static const Color lightBlue = Color(0xFFDCEBFD);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  
  // AI Configuration
  static const String geminiModel = 'gemini-2.5-flash';
  static const double aiTemperature = 0.7;
  static const int aiMaxTokens = 1024;
  static const int maxSearches = 5;
  static const int followUpCount = 4;
  
  // UI Dimensions
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Error Messages
  static const String errorApiKey = 'API key not configured. Please contact support.';
  static const String errorAiInit = 'Failed to initialize AI. Please try again later.';
  static const String errorQuizRequired = 'Please complete the quiz first to use AI Career Coach!';
  static const String errorNoSearches = 'No searches remaining. Upgrade to continue.';
  static const String errorGenericResponse = 'Failed to generate response. Please try again.';
  static const String errorCareerSave = 'Failed to save career goal. Please try again.';
  
  // Success Messages
  static const String successCareerSaved = 'Career goal set: ';
  
  // Input validation
  static const int minCareerLength = 2;
  static const int maxCareerLength = 100;
}

// ============================================================================
// MAIN WIDGET: AI Career Coach Page
// ============================================================================

class CareerCoachPage extends StatefulWidget {
  const CareerCoachPage({super.key});

  @override
  State<CareerCoachPage> createState() => _CareerCoachPageState();
}

class _CareerCoachPageState extends State<CareerCoachPage> {
  // ==========================================================================
  // CONFIGURATION: Responsive Design Breakpoints
  // ==========================================================================
  static const double mobileBreakpoint = 600;
  static const double smallMobileBreakpoint = 380;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // ==========================================================================
  // UI CONTROLLERS: Text Input and Scroll Management
  // ==========================================================================
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ==========================================================================
  // STATE MANAGEMENT: UI and Chat State
  // ==========================================================================
  bool _showSuggestions = false;
  List<Message> _messages = const [];
  bool _aiLoading = false;
  int _searchesRemaining = AppConstants.maxSearches;

  // ==========================================================================
  // AI CONFIGURATION: Gemini Model Instance
  // ==========================================================================
  GenerativeModel? _model;

  // ==========================================================================
  // USER DATA: Profile Information from Supabase
  // ==========================================================================
  String _userName = 'Guest';
  bool _loadingProfile = true;
  bool _isQuizDone = false; // Quiz completion requirement for features
  String _userCareer = ''; // User's selected career path

  // ==========================================================================
  // LIFECYCLE: Widget Initialization
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // USER PROFILE: Load and Manage User Data from Supabase
  // ==========================================================================

  /// Fetches user profile from Supabase 'users' table
  /// Retrieves: userName, quiz completion status, career goal (mainFocus)
  /// Falls back to email username if profile data unavailable
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response != null) {
          setState(() {
            _userName = response['userName'] ?? user.email?.split('@')[0] ?? 'Guest';
            _isQuizDone = response['isQuizDone'] == true;
            _userCareer = response['mainFocus'] ?? '';
            _loadingProfile = false;
          });
        } else {
          _setFallbackProfile(user);
        }
      }
    } catch (e) {
      // Production: Log to monitoring service instead of print
      debugPrint('❌ Profile load error: $e');
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) _setFallbackProfile(user);
    }
  }

  /// Sets fallback profile data when database fetch fails
  void _setFallbackProfile(User user) {
    setState(() {
      _userName = user.email?.split('@')[0] ?? 'Guest';
      _loadingProfile = false;
    });
  }

  // ==========================================================================
  // AI INITIALIZATION: Configure Gemini Model with API Key
  // ==========================================================================

  /// Initializes Google Gemini 2.5 Flash model for AI responses
  /// Loads API key from .env file and configures generation parameters
  /// Temperature: 0.7 (balanced creativity)
  /// Max tokens: 1024 (concise responses)
  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    
    if (apiKey == null || apiKey.isEmpty) {
      _showError(AppConstants.errorApiKey);
      debugPrint('❌ GEMINI_API_KEY missing in .env');
      return;
    }

    try {
      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: AppConstants.aiTemperature,
          maxOutputTokens: AppConstants.aiMaxTokens,
        ),
      );
    } catch (e) {
      debugPrint('❌ Gemini initialization error: $e');
      _showError(AppConstants.errorAiInit);
    }
  }

  // ==========================================================================
  // AI RESPONSE GENERATION: Core Gemini API Integration
  // ==========================================================================

  /// Generates personalized AI response using Gemini API
  /// 
  /// Process:
  /// 1. Build context-aware prompt with user profile and career goal
  /// 2. Generate main response using Gemini 2.5 Flash
  /// 3. Generate 4 follow-up questions for deeper exploration
  /// 4. Extract and save career intent if mentioned
  /// 
  /// Returns:
  /// - response: AI-generated career advice (String)
  /// - followUps: Suggested follow-up questions (`List<String>`)
  /// 
  /// Throws: Exception if API call fails or returns empty response
  Future<Map<String, dynamic>> _generateAIResponse(String userInput) async {
    try {
      if (_model == null) {
        throw Exception('AI model not initialized');
      }

      // Build context-aware prompt with user profile
      final hasCareerGoal = _userCareer.isNotEmpty && 
          _userCareer.toLowerCase() != 'choose career paths';
      
      final prompt = '''
You are Reskill, a warm and friendly AI Career Coach having a natural conversation.

User Profile:
- Name: $_userName
${hasCareerGoal ? '- Career Goal: $_userCareer' : '- Career Goal: Not yet chosen'}

Current Question: $userInput

Instructions:
- Have a natural, flowing conversation like a real human mentor
${hasCareerGoal ? '- Reference their career goal ($_userCareer) when relevant' : ''}
- Be warm, encouraging, and personable
- Keep responses conversational but concise (3-5 sentences max)
- Give actionable, specific advice
- End with an encouraging note or follow-up question
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('AI returned empty response');
      }

      final aiText = response.text!;

      // Generate contextual follow-up questions
      final followUpPrompt = '''
Based on this career question: "$userInput"

Generate 4 relevant follow-up questions that would help the user explore this topic further.
Return only the questions, one per line, without numbering or bullets.
''';

      List<String> followUps = await _generateFollowUpQuestions(followUpPrompt);

      // Attempt to extract and save career intent from conversation
      await _extractAndSaveCareer(userInput, aiText);

      return {'response': aiText, 'followUps': followUps};
    } catch (e, stackTrace) {
      debugPrint('❌ AI response generation error: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Generates follow-up questions using Gemini API
  /// Falls back to default questions if generation fails
  Future<List<String>> _generateFollowUpQuestions(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text != null && response.text!.isNotEmpty) {
        return response.text!
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^[0-9]+\.\s*'), '').trim())
            .take(AppConstants.followUpCount)
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ Follow-up generation failed: $e');
    }

    return _getDefaultFollowUpQuestions();
  }

  /// Returns default follow-up questions for fallback
  List<String> _getDefaultFollowUpQuestions() {
    return const [
      'What skills do I need for this?',
      'What are the salary expectations?',
      'How long does it take to learn?',
      'What are the job prospects?',
    ];
  }

  // ==========================================================================
  // CAREER PATH EXTRACTION: Detect and Save Career Intent
  // ==========================================================================

  /// Analyzes conversation for career intent and saves to database
  /// 
  /// Detection patterns:
  /// - "want to become", "want to be", "interested in becoming"
  /// - "career as", "career in", "pursue"
  /// 
  /// Uses AI to extract specific career title from user input
  /// Requires quiz completion before saving career path
  Future<void> _extractAndSaveCareer(
    String userInput,
    String aiResponse,
  ) async {
    try {
      if (_model == null) return;

      // Career intent detection patterns
      const careerPatterns = [
        'want to become', 'become a', 'want to be',
        'interested in becoming', 'career as', 'pursue',
        'interested in', 'career in',
      ];

      final hasCareerIntent = careerPatterns.any(
        (pattern) => userInput.toLowerCase().contains(pattern),
      );

      if (!hasCareerIntent) return;

      // Extract career using AI
      final extractPrompt = '''
Extract the specific career or profession from this user input.

User said: "$userInput"

Return ONLY the career title (e.g., "Full Stack Developer", "Data Scientist").
If no specific career mentioned, return "None".
Do not include explanation.
''';

      final extractContent = [Content.text(extractPrompt)];
      final extractResponse = await _model!.generateContent(extractContent);

      if (extractResponse.text != null && extractResponse.text!.isNotEmpty) {
        final career = extractResponse.text!.trim();

        if (_isValidCareerName(career)) {
          await _saveCareerToDatabase(career);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Career extraction failed: $e');
      // Non-critical feature - don't disrupt user experience
    }
  }

  /// Saves extracted career goal to Supabase 'users' table
  /// Requires quiz completion to prevent premature career selection
  /// Updates both database and local state on success
  Future<void> _saveCareerToDatabase(String career) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Enforce quiz completion requirement
      if (!_isQuizDone) {
        _showWarning('Please complete the quiz first to set your career path!');
        return;
      }

      // Persist to database
      await Supabase.instance.client
          .from('users')
          .update({'mainFocus': career})
          .eq('id', user.id);

      // Update local state
      setState(() => _userCareer = career);

      // Confirm to user
      _showSuccess(AppConstants.successCareerSaved + career);
    } catch (e) {
      debugPrint('❌ Career save error: $e');
      _showError(AppConstants.errorCareerSave);
    }
  }

  /// Validates career name before saving
  bool _isValidCareerName(String career) {
    return career.toLowerCase() != 'none' &&
        career.length > AppConstants.minCareerLength &&
        career.length < AppConstants.maxCareerLength;
  }

  // ==========================================================================
  // MESSAGE HANDLING: User Input and AI Response Flow
  // ==========================================================================

  /// Handles user message submission and AI response generation
  /// 
  /// Validation checks:
  /// 1. Non-empty message
  /// 2. Not already loading
  /// 3. Quiz completion required
  /// 4. Search limit not exceeded
  /// 
  /// Flow:
  /// 1. Add user message to chat
  /// 2. Generate AI response
  /// 3. Add AI response with follow-ups to chat
  /// 4. Auto-scroll to bottom
  void _sendMessage() async {
    final text = _searchController.text.trim();
    if (text.isEmpty || _aiLoading) return;

    // Enforce quiz completion
    if (!_isQuizDone) {
      _showWarning(AppConstants.errorQuizRequired);
      return;
    }

    // Check usage limit
    if (_searchesRemaining <= 0) {
      _showWarning(AppConstants.errorNoSearches);
      return;
    }

    // Update state: add user message, start loading
    setState(() {
      _messages = [..._messages, Message(role: MessageRole.user, text: text)];
      _aiLoading = true;
      _searchesRemaining--;
    });

    _searchController.clear();
    _scrollToBottom();

    try {
      // Generate AI response
      final aiData = await _generateAIResponse(text);

      // Add AI response to chat
      setState(() {
        _messages = [
          ..._messages,
          Message(
            role: MessageRole.ai,
            text: aiData['response'] as String,
            followUpQuestions: List<String>.from(aiData['followUps'] as List),
          ),
        ];
        _aiLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Send message error: $e');

      // Add error message to chat
      setState(() {
        _messages = [
          ..._messages,
          const Message(
            role: MessageRole.ai,
            text: 'I apologize, but I encountered an error. Please try again or contact support if the issue persists.',
          ),
        ];
        _aiLoading = false;
      });

      _showError(AppConstants.errorGenericResponse);
    }
  }

  // ==========================================================================
  // UTILITY METHODS: Chat Management and UI Helpers
  // ==========================================================================

  /// Clears conversation history and resets search limit
  void _clearChat() {
    setState(() {
      _messages = const [];
      _searchesRemaining = AppConstants.maxSearches;
    });
  }

  /// Auto-scrolls chat to latest message with smooth animation
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Shows error snackbar with delete icon
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Shows warning snackbar with option to dismiss
  void _showWarning(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Shows success snackbar with checkmark
  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==========================================================================
  // UI BUILD: Main Widget Tree Construction
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppConstants.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Career Coach',
          style: TextStyle(
            color: AppConstants.darkBlue,
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Row(
        children: [
          // Left side - Chat area
          Expanded(
            child: Column(
              children: [
                // Messages area or welcome screen
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : _buildChatArea(),
                ),

                // Input area at bottom
                _buildInputArea(),
              ],
            ),
          ),

          // Right sidebar (desktop only)
          if (screenWidth > desktopBreakpoint)
            Container(
              width: 320,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey[300]!)),
              ),
              child: _buildRightSidebar(),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // UI COMPONENTS: Welcome Screen, Chat Area, and Message Bubbles
  // ==========================================================================

  /// Welcome screen displayed before first message
  /// Shows: personalized greeting, AI features, career suggestions
  Widget _buildWelcomeScreen() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 380;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _loadingProfile ? 'Welcome...' : 'Welcome $_userName',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 22 : (isMobile ? 26 : 32),
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2347),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: isSmallMobile ? 8 : 12),
              Container(
                width: isSmallMobile ? 36 : (isMobile ? 40 : 48),
                height: isSmallMobile ? 36 : (isMobile ? 40 : 48),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF93C5FD),
                      Color(0xFFFBBF24),
                      Color(0xFFFCBED6),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Subtitle
          Text(
            'Lets get started with defining your career goals, and clearing your doubts. Tell me what you want to become.',
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : 16,
              color: Color(0xFF1B2347),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isMobile ? 30 : 40),

          // Show suggestions or feature cards
          if (_showSuggestions)
            _buildCareerSuggestions()
          else
            _buildFeatureCards(),
        ],
      ),
    );
  }

  /// Feature cards displaying AI capabilities:
  /// - Voice Assistant for interview prep
  /// - Instant doubt clearing
  /// - Real-time web search integration
  Widget _buildFeatureCards() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    return Wrap(
      spacing: isMobile ? 12 : 16,
      runSpacing: isMobile ? 12 : 16,
      children: [
        _buildFeatureCard(
          title: 'AI Voice Assistant',
          description:
              'Test your knowledge. AI Voice Assistant made for Interview Preparations.',
          buttonText: 'Try Now',
          icon: Icons.mic,
          isDark: true,
        ),
        _buildFeatureCard(
          title: 'Clear Every Doubt',
          description:
              'Ask questions freely and get simple, accurate explanations in seconds.',
          icon: Icons.search,
          isDark: false,
        ),
        _buildFeatureCard(
          title: 'Live Web Search',
          description: 'Always get real-time and latest, verified answers.',
          icon: Icons.language,
          isDark: false,
        ),
      ],
    );
  }

  /// Grid of popular career paths for quick selection
  /// Tapping a chip fills the search bar with the career name
  Widget _buildCareerSuggestions() {
    const suggestions = [
      'Full Stack Developer',
      'Data Science',
      'AI/ML Developer',
      'Software Engineer',
      'Backend Developer',
      'Frontend Developer',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: suggestions.map((suggestion) {
        return _buildSuggestionChip(suggestion);
      }).toList(),
    );
  }

  /// Scrollable chat interface with alternating user and AI messages
  /// Includes loading indicator when AI is generating response
  Widget _buildChatArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? 8 : (isMobile ? 12 : 20),
      ),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length + (_aiLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return _buildLoadingIndicator();
          }

          final message = _messages[index];

          return message.role == MessageRole.user
              ? _buildUserMessage(message)
              : _buildAIMessage(message);
        },
      ),
    );
  }

  /// User message bubble: right-aligned, blue background
  /// Responsive width scaling for mobile/tablet/desktop
  Widget _buildUserMessage(Message message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isSmallMobile
              ? screenWidth * 0.85
              : (isMobile ? screenWidth * 0.8 : 500),
        ),
        margin: EdgeInsets.only(
          bottom: isSmallMobile ? 12 : 16,
          left: isSmallMobile ? 20 : (isMobile ? 40 : 100),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 10 : (isMobile ? 12 : 16),
          vertical: isSmallMobile ? 8 : (isMobile ? 10 : 12),
        ),
        decoration: BoxDecoration(
          color: AppConstants.primaryBlue,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// AI message bubble: left-aligned, light blue background
  /// Includes AI icon and grid of follow-up question chips
  Widget _buildAIMessage(Message message) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 380;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: isSmallMobile
                  ? screenWidth * 0.95
                  : (isMobile ? screenWidth * 0.9 : 550),
            ),
            margin: EdgeInsets.only(
              bottom: isSmallMobile ? 10 : 12,
              right: isSmallMobile ? 10 : (isMobile ? 20 : 100),
            ),
            padding: EdgeInsets.all(isSmallMobile ? 10 : (isMobile ? 12 : 16)),
            decoration: BoxDecoration(
              color: AppConstants.lightBlue,
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: AppConstants.primaryBlue,
                  size: isMobile ? 20 : 24,
                ),
                SizedBox(width: isMobile ? 8 : 12),
                Expanded(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 13 : 14,
                      color: AppConstants.darkBlue,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Follow-up questions
          if (message.followUpQuestions != null &&
              message.followUpQuestions!.isNotEmpty)
            Container(
              constraints: BoxConstraints(
                maxWidth: isSmallMobile
                    ? screenWidth * 0.95
                    : (isMobile ? screenWidth * 0.9 : 550),
              ),
              margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
              padding: EdgeInsets.all(isSmallMobile ? 8 : (isMobile ? 10 : 12)),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: isMobile ? 14 : 16,
                        color: AppConstants.primaryBlue,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Follow Up',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 10 : 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isSmallMobile ? 1 : (isMobile ? 1 : 2),
                      crossAxisSpacing: isSmallMobile ? 6 : 8,
                      mainAxisSpacing: isSmallMobile ? 6 : 8,
                      childAspectRatio: isSmallMobile ? 6 : (isMobile ? 5 : 3),
                    ),
                    itemCount: message.followUpQuestions!.length,
                    itemBuilder: (context, index) {
                      return InkWell(
                        onTap: () {
                          _searchController.text =
                              message.followUpQuestions![index];
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            message.followUpQuestions![index],
                            style: TextStyle(
                              fontSize: isSmallMobile ? 10 : 11,
                              color: AppConstants.darkBlue,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Animated loading indicator with pulsing effect
  /// Displayed while waiting for AI response
  Widget _buildLoadingIndicator() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: AppConstants.lightBlue,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: isSmallMobile ? 16 : 20,
              height: isSmallMobile ? 16 : 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryBlue),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'AI is thinking...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF1B2347),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fixed bottom input bar with controls
  /// Components: Clear/Suggestions toggle, search counter, text field, send button
  /// Includes "Web" badge indicating real-time search capability
  Widget _buildInputArea() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    return Container(
      padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
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
      child: Column(
        children: [
          // Control buttons row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Clear or Show Suggestions button
              if (_messages.isEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showSuggestions = !_showSuggestions;
                    });
                  },
                  icon: Icon(
                    _showSuggestions
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppConstants.darkBlue,
                  ),
                  label: Text(
                    _showSuggestions ? 'Hide Suggestions' : 'Show Suggestions',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12 : 14,
                      color: AppConstants.darkBlue,
                    ),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _clearChat,
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: isSmallMobile ? 18 : 20,
                  ),
                  label: Text(
                    'Clear Chat',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 12 : 14,
                      color: Colors.red,
                    ),
                  ),
                ),

              // Searches remaining
              Text(
                '$_searchesRemaining searches -',
                style: TextStyle(
                  fontSize: isSmallMobile ? 11 : 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Input field
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? 12 : 16,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: isSmallMobile ? 13 : 15,
                      ),
                    ),
                    style: TextStyle(fontSize: isSmallMobile ? 13 : 15),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),

                // Web badge
                if (!isSmallMobile)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 8 : 12,
                      vertical: isSmallMobile ? 4 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppConstants.primaryBlue),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.language,
                          size: isSmallMobile ? 14 : 16,
                          color: AppConstants.primaryBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Web',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 11 : 13,
                            color: AppConstants.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(width: isSmallMobile ? 4 : 8),

                // Send button
                InkWell(
                  onTap: _aiLoading ? null : _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(isSmallMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: _aiLoading ? Colors.grey : AppConstants.primaryBlue,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: isSmallMobile ? 18 : 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Desktop-only sidebar showcasing premium features
  /// - AI Voice Assistant card (purple gradient)
  /// - Career Fit Assessment card (dark gradient)
  Widget _buildRightSidebar() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // AI Voice Assistant Card
          Container(
            height: 380,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Gradient background
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF7EAFF), Color(0xFFFDE2EA)],
                    ),
                  ),
                ),

                // Gradient overlays
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: RadialGradient(
                        center: Alignment(0.7, -0.6),
                        radius: 0.8,
                        colors: [
                          Color(0xFFAF6DFF).withValues(alpha: 0.85),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'AI Voice Assistant',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.darkBlue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'AI Voice Assistant made for Interview Preparations. Try it out now',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConstants.darkBlue,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.mic),
                        label: Text('Talk Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppConstants.darkBlue,
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.person,
                        size: 120,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Career Fit Card
          Container(
            height: 268,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF475569), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Know your\ncareer',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Fit',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryBlue,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Get to know how much your career is fit for you with help of AI',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[300],
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.arrow_forward, size: 16),
                      label: Text('Find Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConstants.darkBlue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        textStyle: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: -20,
                  right: -10,
                  child: Icon(
                    Icons.assessment,
                    size: 100,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Reusable feature card component
  /// Supports dark/light theme, optional action button, custom icon
  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    String? buttonText,
    required bool isDark,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;

    return Container(
      width: screenWidth > tabletBreakpoint
          ? (screenWidth - 80) / 3
          : double.infinity,
      padding: EdgeInsets.all(isMobile ? 12 : 14),
      decoration: BoxDecoration(
        color: isDark ? AppConstants.darkBlue : Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppConstants.darkBlue,
                  ),
                ),
              ),
              if (buttonText != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFB39DDB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward, size: 12, color: Colors.white),
                    ],
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.white : AppConstants.primaryBlue,
                    size: isMobile ? 18 : 20,
                  ),
                ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 10),
          Text(
            description,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Individual career suggestion chip with tap interaction
  /// On tap: fills search bar and hides suggestions
  Widget _buildSuggestionChip(String text) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isSmallMobile = screenWidth < smallMobileBreakpoint;

    return InkWell(
      onTap: () {
        _searchController.text = text;
        setState(() {
          _showSuggestions = false;
        });
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Container(
        width: isMobile ? double.infinity : 380,
        height: isSmallMobile ? 52 : 60,
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 14 : 20,
          vertical: isSmallMobile ? 12 : 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0E0E0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmallMobile ? 13 : 15,
              color: AppConstants.darkBlue,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

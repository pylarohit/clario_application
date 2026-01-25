import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Message model for chat
class Message {
  final String role; // 'user' or 'ai'
  final String text;
  final List<String>? followUpQuestions;

  Message({required this.role, required this.text, this.followUpQuestions});
}

class CareerCoachPage extends StatefulWidget {
  @override
  _CareerCoachPageState createState() => _CareerCoachPageState();
}

class _CareerCoachPageState extends State<CareerCoachPage> {
  bool _showSuggestions = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Chat state
  List<Message> _messages = [];
  bool _aiLoading = false;
  int _searchesRemaining = 5;

  // Gemini AI Model
  late final GenerativeModel _model;
  
  // User profile
  String _userName = 'Guest';
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        if (response != null && response['full_name'] != null) {
          setState(() {
            _userName = response['full_name'];
            _loadingProfile = false;
          });
        } else {
          setState(() {
            _userName = user.email?.split('@')[0] ?? 'Guest';
            _loadingProfile = false;
          });
        }
      }
    } catch (e) {
      final user = Supabase.instance.client.auth.currentUser;
      setState(() {
        _userName = user?.email?.split('@')[0] ?? 'Guest';
        _loadingProfile = false;
      });
    }
  }

  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      print('ERROR: GEMINI_API_KEY not found in .env file');
      return;
    }
    
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Generate AI response using Gemini
  Future<Map<String, dynamic>> _generateAIResponse(String userInput) async {
    try {
      final prompt = '''
You are an expert AI Career Coach. Provide personalized career guidance based on the user's question.

User Question: $userInput

Please provide:
1. A detailed, helpful response to their question
2. Actionable advice and insights
3. Relevant career guidance

Keep your response concise, professional, and encouraging. Focus on practical advice.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from AI');
      }

      // Generate follow-up questions based on the context
      final followUpPrompt = '''
Based on this career question: "$userInput"

Generate 4 relevant follow-up questions that would help the user explore this topic further.
Format: Return only the questions, one per line, without numbering or bullets.
''';

      final followUpContent = [Content.text(followUpPrompt)];
      final followUpResponse = await _model.generateContent(followUpContent);
      
      List<String> followUps = [];
      if (followUpResponse.text != null) {
        followUps = followUpResponse.text!
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .take(4)
            .toList();
      }

      // Default follow-ups if generation fails
      if (followUps.isEmpty) {
        followUps = [
          'What skills do I need for this?',
          'What are the salary expectations?',
          'How long does it take to learn?',
          'What are the job prospects?',
        ];
      }

      return {
        'response': response.text!,
        'followUps': followUps,
      };
    } catch (e) {
      print('Error generating AI response: $e');
      throw e;
    }
  }

  // Send message
  void _sendMessage() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) return;
    if (_aiLoading) return;
    if (_searchesRemaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No searches remaining. Upgrade to continue.')),
      );
      return;
    }

    setState(() {
      _messages.add(Message(role: 'user', text: text));
      _aiLoading = true;
      _searchesRemaining--;
    });

    _searchController.clear();
    _scrollToBottom();

    try {
      final aiData = await _generateAIResponse(text);

      setState(() {
        _messages.add(
          Message(
            role: 'ai',
            text: aiData['response'],
            followUpQuestions: List<String>.from(aiData['followUps']),
          ),
        );
        _aiLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(
          Message(role: 'ai', text: 'Something went wrong. Please try again.'),
        );
        _aiLoading = false;
      });
    }
  }

  // Clear chat
  void _clearChat() {
    setState(() {
      _messages.clear();
      _searchesRemaining = 5;
    });
  }

  // Scroll to bottom
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1B2347)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'AI Career Coach',
          style: TextStyle(
            color: Color(0xFF1B2347),
            fontSize: 18,
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

          // Right sidebar
          if (screenWidth > 1000)
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

  // Welcome screen (when no messages)
  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _loadingProfile ? 'Welcome...' : 'Welcome $_userName',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                ),
              ),
              SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
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
          SizedBox(height: 20),

          // Subtitle
          Text(
            'Lets get started with defining your career goals, and clearing your doubts. Tell me what you want to become.',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1B2347),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40),

          // Show suggestions or feature cards
          if (_showSuggestions)
            _buildCareerSuggestions()
          else
            _buildFeatureCards(),
        ],
      ),
    );
  }

  // Feature cards
  Widget _buildFeatureCards() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
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

  // Career suggestions grid
  Widget _buildCareerSuggestions() {
    final suggestions = [
      'Software Developer',
      'Data Scientist',
      'Artificial Intelligence Engineer',
      'Computer Systems Analyst',
      'IT Consultant',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return _buildSuggestionChip(suggestions[index]);
      },
    );
  }

  // Chat area with messages
  Widget _buildChatArea() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length + (_aiLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return _buildLoadingIndicator();
          }

          final message = _messages[index];

          if (message.role == 'user') {
            return _buildUserMessage(message);
          } else {
            return _buildAIMessage(message);
          }
        },
      ),
    );
  }

  // User message bubble
  Widget _buildUserMessage(Message message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 500),
        margin: EdgeInsets.only(bottom: 16, left: 100),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF5E9EF5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          style: TextStyle(fontSize: 14, color: Colors.white, height: 1.4),
        ),
      ),
    );
  }

  // AI message bubble with follow-ups
  Widget _buildAIMessage(Message message) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: 550),
            margin: EdgeInsets.only(bottom: 12, right: 100),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFDCEBFD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF5E9EF5), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1B2347),
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
              constraints: BoxConstraints(maxWidth: 550),
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
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
                        size: 16,
                        color: Color(0xFF5E9EF5),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Follow Up',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5E9EF5),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 3,
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
                            horizontal: 12,
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
                              fontSize: 11,
                              color: Color(0xFF1B2347),
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

  // Loading indicator
  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFFDCEBFD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5E9EF5)),
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

  // Input area at bottom
  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                    color: Color(0xFF1B2347),
                  ),
                  label: Text(
                    _showSuggestions ? 'Hide Suggestions' : 'Show Suggestions',
                    style: TextStyle(fontSize: 14, color: Color(0xFF1B2347)),
                  ),
                )
              else
                TextButton.icon(
                  onPressed: _clearChat,
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(
                    'Clear Chat',
                    style: TextStyle(fontSize: 14, color: Colors.red),
                  ),
                ),

              // Searches remaining
              Text(
                '$_searchesRemaining searches -',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Input field
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        fontSize: 15,
                      ),
                    ),
                    style: TextStyle(fontSize: 15),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),

                // Web badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF5E9EF5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, size: 16, color: Color(0xFF5E9EF5)),
                      SizedBox(width: 6),
                      Text(
                        'Web',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5E9EF5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),

                // Send button
                InkWell(
                  onTap: _aiLoading ? null : _sendMessage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _aiLoading ? Colors.grey : Color(0xFF5E9EF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Right sidebar
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
                  color: Colors.black.withOpacity(0.1),
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
                          Color(0xFFAF6DFF).withOpacity(0.85),
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
                          color: Color(0xFF1B2347),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'AI Voice Assistant made for Interview Preparations. Try it out now',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B2347),
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
                          foregroundColor: Color(0xFF1B2347),
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
                        color: Colors.white.withOpacity(0.5),
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
                  color: Colors.black.withOpacity(0.1),
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
                        color: Color(0xFF5E9EF5),
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
                        foregroundColor: Color(0xFF1B2347),
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
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required String title,
    required String description,
    required IconData icon,
    String? buttonText,
    required bool isDark,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width > 900
          ? (MediaQuery.of(context).size.width - 80) / 3
          : double.infinity,
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1B2347) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF1B2347),
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
                        ? Colors.white.withOpacity(0.1)
                        : Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.white : Color(0xFF5E9EF5),
                    size: 20,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white.withOpacity(0.9) : Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return InkWell(
      onTap: () {
        _searchController.text = text;
      },
      child: Container(
        width: MediaQuery.of(context).size.width > 700
            ? (MediaQuery.of(context).size.width - 80) / 3 - 8
            : double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF1B2347),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

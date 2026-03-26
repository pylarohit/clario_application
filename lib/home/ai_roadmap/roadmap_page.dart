// ============================================================================
// AI ROADMAP MAKER PAGE - Personalized Career Roadmap Generator
// ============================================================================
// Features:
// - AI-powered roadmap generation using Gemini 2.5 Flash
// - Supabase integration for storing/retrieving roadmaps (roadmapUsers table)
// - History tab showing past generated roadmaps
// - Suggestions tab with quiz-based career options
// - Filters for timeline (3m/6m/1yr) and mode (Beginner/Intermediate/Advance)
// - Animated loading steps during generation
// - Interactive roadmap visualization with connected nodes
// - Start/Continue roadmap actions
// ============================================================================

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RoadmapPage extends StatefulWidget {
  const RoadmapPage({super.key});

  @override
  State<RoadmapPage> createState() => _RoadmapPageState();
}

class _RoadmapPageState extends State<RoadmapPage>
    with TickerProviderStateMixin {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // AI Model
  GenerativeModel? _model;

  // User data
  String _userId = '';
  bool _isQuizDone = false;
  List<String> _careerSkillOptions = [];
  bool _quizDataLoading = true;

  // Input & Filters
  final TextEditingController _fieldController = TextEditingController();
  String _timeline = '';
  String _mode = '';
  bool _showFilters = false;

  // Roadmap state
  Map<String, dynamic>? _roadmap;
  String? _roadmapId;
  bool _isStarted = false;
  bool _loadingRoadmap = false;
  String? _error;

  // History
  List<Map<String, dynamic>> _histRoadmap = [];

  // Tab state
  int _selectedTabIndex = 1; // 0 = History, 1 = Suggestions

  // Loading animation
  int _stepIndex = 0;
  Timer? _stepTimer;
  final List<String> _steps = [
    'Getting tools ready...',
    'Creating Your Learning Path...',
    'Generating roadmap nodes...',
    'Linking External Resources',
  ];

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadUserData();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _fieldController.dispose();
    _stepTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  void _initializeGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 4096,
        ),
      );
      debugPrint('✅ Roadmap: Gemini AI initialized');
    } else {
      debugPrint('❌ Roadmap: Gemini API key not found');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      _userId = user.id;

      // Load user profile
      final userData = await Supabase.instance.client
          .from('users')
          .select('isQuizDone, mainFocus')
          .eq('id', _userId)
          .maybeSingle();

      if (userData != null) {
        _isQuizDone = userData['isQuizDone'] ?? false;
      }

      // Load quiz data for career suggestions
      final quizData = await Supabase.instance.client
          .from('quizResults')
          .select('quizInfo')
          .eq('user_id', _userId)
          .order('created_at', ascending: false)
          .limit(1);

      if (quizData.isNotEmpty) {
        final quizInfo = quizData[0]['quizInfo'];
        if (quizInfo != null && quizInfo['careerOptions'] is List) {
          _careerSkillOptions =
              List<String>.from(quizInfo['careerOptions']);
        }
      }

      // Load history
      await _fetchHistory();

      if (mounted) {
        setState(() {
          _quizDataLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _quizDataLoading = false;
        });
      }
    }
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await Supabase.instance.client
          .from('roadmapUsers')
          .select('*')
          .eq('user_id', _userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _histRoadmap = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
    }
  }

  // ============================================================================
  // ROADMAP GENERATION
  // ============================================================================

  Future<void> _fetchRoadmap() async {
    final field = _fieldController.text.trim();
    if (field.isEmpty) {
      _showSnackBar('Please enter a career field', isError: true);
      return;
    }
    if (_timeline.isEmpty || _mode.isEmpty) {
      _showSnackBar('Please select timeline and mode from filters',
          isError: true);
      return;
    }

    setState(() {
      _roadmapId = null;
      _loadingRoadmap = true;
      _error = null;
      _roadmap = null;
      _isStarted = false;
    });

    _startLoadingAnimation();

    try {
      if (_model == null) {
        throw Exception('AI model not initialized');
      }

      final prompt = '''
You are an expert career advisor and learning path designer.

Create a detailed, step-by-step learning roadmap for someone who wants to become a "$field".

Timeline: $_timeline
Level: $_mode

Return ONLY a valid JSON object (no markdown, no code blocks, no extra text):
{
  "roadmapTitle": "<Career> Learning Roadmap",
  "description": "A $_timeline learning plan for aspiring <career title>",
  "duration": "$_timeline",
  "initialNodes": [
    {
      "id": "1",
      "data": {
        "title": "Step Title",
        "description": "Brief description of what to learn",
        "link": "https://relevant-resource-url.com"
      },
      "position": {"x": 150, "y": 50}
    }
  ],
  "initialEdges": [
    {"id": "e1-2", "source": "1", "target": "2"}
  ]
}

CRITICAL Requirements:
1. Generate exactly 7 nodes for the roadmap
2. Each node must have a unique id (string "1" through "7")
3. Position nodes in a visually appealing layout:
   - Alternate x positions between 50 and 250
   - Increment y by ~180 for each node
4. Connect nodes sequentially with edges (e.g., 1->2, 2->3, etc.)
5. Include real, working resource URLs for each step (use popular platforms like freecodecamp.org, coursera.org, udemy.com, youtube.com, w3schools.com, geeksforgeeks.org, etc.)
6. Keep descriptions concise (under 15 words each)
7. For $_mode level, adjust the complexity of topics appropriately
8. Return ONLY the JSON object, nothing else
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      final responseText = response.text?.trim() ?? '';

      debugPrint('Roadmap AI Response: $responseText');

      // Parse response
      String cleanJson = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonStart = cleanJson.indexOf('{');
      final jsonEnd = cleanJson.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
        cleanJson = cleanJson.substring(jsonStart, jsonEnd + 1);
      }

      final roadmapJson = json.decode(cleanJson) as Map<String, dynamic>;

      // Save to Supabase
      final insertResult = await Supabase.instance.client
          .from('roadmapUsers')
          .insert({
            'user_id': _userId,
            'roadmap_data': roadmapJson,
            'mode': _mode,
            'timeline': _timeline,
          })
          .select()
          .single();

      if (mounted) {
        setState(() {
          _roadmap = roadmapJson;
          _roadmapId = insertResult['id'].toString();
          _loadingRoadmap = false;
        });
      }

      // Refresh history
      await _fetchHistory();
    } catch (e) {
      debugPrint('Error generating roadmap: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to generate roadmap. Please try again.';
          _loadingRoadmap = false;
        });
      }
    }
    _stopLoadingAnimation();
  }

  void _startLoadingAnimation() {
    _stepIndex = 0;
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _stepIndex = (_stepIndex + 1) % _steps.length;
        });
      }
    });
  }

  void _stopLoadingAnimation() {
    _stepTimer?.cancel();
  }

  // ============================================================================
  // HISTORY & START ACTIONS
  // ============================================================================

  void _loadHistoryRoadmap(Map<String, dynamic> item) {
    setState(() {
      _roadmap = item['roadmap_data'] as Map<String, dynamic>?;
      _roadmapId = item['id'].toString();
      _isStarted = item['isStarted'] ?? false;
    });
    _showSnackBar('Roadmap loaded successfully!');
  }

  Future<void> _handleStartRoadmap() async {
    if (_roadmapId == null) {
      _showSnackBar('No roadmap selected.', isError: true);
      return;
    }

    try {
      await Supabase.instance.client
          .from('roadmapUsers')
          .update({'isStarted': true})
          .eq('id', int.parse(_roadmapId!));

      if (mounted) {
        setState(() {
          _isStarted = true;
        });
      }
      _showSnackBar('Roadmap has been started! Track your progress.');
      await _fetchHistory();
    } catch (e) {
      _showSnackBar('Failed to start roadmap', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter(fontSize: 13)),
        backgroundColor: isError ? Colors.red[600] : const Color(0xFF1B2347),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: _loadingRoadmap
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _roadmap != null
              ? _buildRoadmapView()
              : _buildInputView(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: Text('Try Again',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E9EF5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // APP BAR
  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1B2347)),
        onPressed: () {
          if (_roadmap != null) {
            setState(() {
              _roadmap = null;
              _roadmapId = null;
              _isStarted = false;
            });
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Text(
        _roadmap != null
            ? (_roadmap!['roadmapTitle'] ?? 'Your Roadmap')
            : 'AI Roadmap Maker',
        style: GoogleFonts.inter(
          color: const Color(0xFF1B2347),
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: _roadmap != null
          ? [
              if (_roadmapId != null && !_isStarted)
                TextButton.icon(
                  onPressed: _handleStartRoadmap,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: Text('Start',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF5E9EF5),
                  ),
                ),
              if (_roadmapId != null && _isStarted)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[300]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                      const SizedBox(width: 4),
                      Text('Active',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700])),
                    ],
                  ),
                ),
            ]
          : [
              IconButton(
                icon: Icon(Icons.route, color: Colors.blue[600], size: 22),
                onPressed: () {},
              ),
            ],
    );
  }

  // ============================================================================
  // INPUT VIEW (Default - no roadmap displayed)
  // ============================================================================

  Widget _buildInputView() {
    return Column(
      children: [
        // Header banner
        _buildHeaderBanner(),

        // Tabs
        _buildTabs(),

        // Tab content
        Expanded(
          child: _selectedTabIndex == 0
              ? _buildHistoryTab()
              : _buildSuggestionsTab(),
        ),

        // Bottom input area
        _buildBottomInput(),
      ],
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2347), Color(0xFF2D3A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2347).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.route, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Roadmap Maker',
                  style: GoogleFonts.inter(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level up your career with AI-powered personalized roadmaps.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
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

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem('History', Icons.history, 0),
          _buildTabItem('Suggestions', Icons.auto_awesome, 1),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, IconData icon, int index) {
    final isActive = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1B2347) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isActive ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // HISTORY TAB
  // ============================================================================

  Widget _buildHistoryTab() {
    if (_histRoadmap.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No roadmaps yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Your generated roadmaps will appear here.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: _histRoadmap.length,
      itemBuilder: (context, index) {
        final item = _histRoadmap[index];
        final roadmapData = item['roadmap_data'] as Map<String, dynamic>?;
        final title = roadmapData?['roadmapTitle'] ?? 'Untitled Roadmap';
        final isActive = item['isStarted'] ?? false;
        final createdAt = DateTime.tryParse(item['created_at'] ?? '');
        final dateStr = createdAt != null
            ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
            : '';

        return GestureDetector(
          onTap: () => _loadHistoryRoadmap(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive
                    ? const Color(0xFF5E9EF5)
                    : Colors.grey[200]!,
                width: isActive ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF5E9EF5).withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.account_tree_outlined,
                    size: 20,
                    color: isActive
                        ? const Color(0xFF5E9EF5)
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1B2347),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Active',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 20, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // SUGGESTIONS TAB
  // ============================================================================

  Widget _buildSuggestionsTab() {
    if (_quizDataLoading) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: List.generate(
            4,
            (_) => Container(
              height: 50,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    if (!_isQuizDone || _careerSkillOptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                _isQuizDone
                    ? 'No career suggestions found'
                    : 'Complete Your Quiz First',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isQuizDone
                    ? 'Type a career in the input below to generate a roadmap.'
                    : 'Complete the career quiz to get personalized suggestions.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      itemCount: _careerSkillOptions.length,
      itemBuilder: (context, index) {
        final option = _careerSkillOptions[index];
        return GestureDetector(
          onTap: () {
            setState(() {
              _fieldController.text = option;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[100]!,
                        Colors.indigo[100]!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1B2347),
                    ),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // BOTTOM INPUT
  // ============================================================================

  Widget _buildBottomInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filters section (expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? 60 : 0,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(child: _buildDropdown(
                      value: _timeline.isEmpty ? null : _timeline,
                      hint: 'Timeline',
                      items: ['3 months', '6 months', '1 year'],
                      onChanged: (v) => setState(() => _timeline = v ?? ''),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDropdown(
                      value: _mode.isEmpty ? null : _mode,
                      hint: 'Mode',
                      items: ['Beginner', 'Intermediate', 'Advance'],
                      onChanged: (v) => setState(() => _mode = v ?? ''),
                    )),
                  ],
                ),
              ),
            ),
          ),

          // Main input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2347),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top row: start button / label + coins
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Roadmap Maker',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '10 coins',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Text field + actions
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        // Filters toggle
                        GestureDetector(
                          onTap: () =>
                              setState(() => _showFilters = !_showFilters),
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _showFilters
                                  ? const Color(0xFF5E9EF5).withValues(alpha: 0.1)
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _showFilters
                                    ? const Color(0xFF5E9EF5)
                                    : Colors.blue[200]!,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune,
                                    size: 14,
                                    color: Colors.blue[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Filters',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Text field
                        Expanded(
                          child: TextField(
                            controller: _fieldController,
                            decoration: InputDecoration(
                              hintText: 'e.g. Data Scientist',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.grey[400],
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _fetchRoadmap(),
                          ),
                        ),
                        // Send button
                        GestureDetector(
                          onTap: _fetchRoadmap,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5E9EF5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.send,
                                size: 18, color: Colors.white),
                          ),
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
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.grey[600])),
          isExpanded: true,
          icon: Icon(Icons.expand_more, size: 18, color: Colors.grey[600]),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(e,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.black87)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ============================================================================
  // LOADING STATE
  // ============================================================================

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        text: 'Hang tight, ',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        children: [
                          TextSpan(
                            text: 'Reskill',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF5E9EF5),
                            ),
                          ),
                          TextSpan(
                            text: ' is designing your personalised roadmap',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.route,
                          color: Color(0xFF5E9EF5), size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Colors.grey[300]),
              const SizedBox(height: 20),

              // Steps
              ...List.generate(_steps.length, (i) {
                final isActive = i == _stepIndex;
                return AnimatedOpacity(
                  opacity: isActive ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 400),
                  child: AnimatedScale(
                    scale: isActive ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 400),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFF5E9EF5).withValues(alpha: 0.3)
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (isActive)
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF5E9EF5),
                              ),
                            )
                          else
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.grey[300]!, width: 2),
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _steps[i],
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? const Color(0xFF5E9EF5)
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              size: 18, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // ROADMAP VIEW (interactive roadmap visualization)
  // ============================================================================

  Widget _buildRoadmapView() {
    final nodes = _roadmap?['initialNodes'] as List<dynamic>? ?? [];
    final description = _roadmap?['description'] ?? '';
    final duration = _roadmap?['duration'] ?? '';

    return Column(
      children: [
        // Description header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$description${duration.isNotEmpty ? ' • $duration' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Nodes list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            itemCount: nodes.length,
            itemBuilder: (context, index) {
              final node = nodes[index] as Map<String, dynamic>;
              final data = node['data'] as Map<String, dynamic>? ?? {};
              final title = data['title'] ?? 'Step ${index + 1}';
              final desc = data['description'] ?? '';
              final link = data['link'] ?? '';
              final isLast = index == nodes.length - 1;

              // Color for this step
              final colors = [
                const Color(0xFF5E9EF5),
                const Color(0xFF7C4DFF),
                const Color(0xFF26A69A),
                const Color(0xFFEF5350),
                const Color(0xFFFF9800),
                const Color(0xFF66BB6A),
                const Color(0xFFAB47BC),
              ];
              final color = colors[index % colors.length];

              return Column(
                children: [
                  // Node card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: color.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step number badge
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1B2347),
                                ),
                              ),
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  desc,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (link.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () async {
                                    final uri = Uri.tryParse(link);
                                    if (uri != null &&
                                        await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode
                                              .externalApplication);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.08),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.link,
                                            size: 13, color: color),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Resource',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Connector line
                  if (!isLast)
                    Container(
                      margin: const EdgeInsets.only(left: 34),
                      width: 2,
                      height: 28,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.4),
                            colors[(index + 1) % colors.length]
                                .withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// HOME PAGE - Main Landing Screen
// ============================================================================
// This is the main home page of the Reskill application that contains:
// - Top navigation sidebar with AI tools
// - Bottom navigation bar (Home, Calendar, Chat, Profile)
// - Hero banner carousel
// - AI tools cards
// - Recommended mentors section
// - Career guidance banners
// - College discovery section
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Page imports for navigation
import '../auth/login.dart';
import 'ai_career_coach/career_coach_page.dart';
import 'ai_roadmap/roadmap_page.dart';
import 'calendar_page.dart';
import 'career_board_page.dart';
import 'chat_page.dart';
import 'mentor_connect_page.dart';
import 'mentor_detail_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'quiz/quiz_start_dialog.dart';

/// Main Home Page Widget
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Static callback for triggering refresh from anywhere
  static void Function()? _refreshCallback;

  /// Register refresh callback
  void _registerRefreshCallback() {
    HomePageState._refreshCallback = () {
      if (mounted) {
        _refreshData();
      }
    };
  }

  /// Static method to trigger refresh from anywhere in the app
  static void triggerRefresh() {
    debugPrint('📢 [HomePage] Refresh triggered via static method');
    _refreshCallback?.call();
  }
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  // Navigation state variables
  int _selectedNavIndex = 0; // Sidebar navigation index
  int _bottomNavIndex = 0; // Bottom navigation bar index
  bool _isAiToolsExpanded = false; // AI Tools dropdown expansion state
  bool _isQuickActionsExpanded = false;

  // Carousel state variables
  int _currentCarouselIndex = 0; // Current hero banner index
  int _currentBannerIndex = 0; // Current career banner index

  // User profile data
  String _userName = 'User';
  String _userInitial = 'U';
  String _userStatus = '12th student';
  String _userFocus = 'choose career paths';
  String _userId = '';
  bool _isQuizDone = false;
  String _userStream = '';
  List<String> _userDegrees = [];
  String? _userPhotoUrl; // Google profile photo URL

  // Controllers
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController; // Hero banner page controller
  late PageController _careerBannerController; // Career banner page controller
  Timer? _carouselTimer; // Auto-scroll timer for hero banner

  // ============================================================================
  // DATA - Mentors List (In production, fetch from API)
  // ============================================================================
  List<Map<String, dynamic>> mentors = [
    {
      'id': '1',
      'full_name': 'Zatinder Mehta',
      'current_position': 'Data Scientist',
      'expertise': ['skill building', 'career/path guidance', 'job placement'],
      'rating': 5.0,
      'avatar': 'assets/a1.png',
    },
    {
      'id': '2',
      'full_name': 'Rajesh Kumar',
      'current_position': 'Business Analyst',
      'expertise': [
        'higher studies',
        'career/path guidance',
        'counseling & guidance',
      ],
      'rating': 4.7,
      'avatar': 'assets/a2.png',
    },
    {
      'id': '3',
      'full_name': 'Priya Sharma',
      'current_position': 'Cloud Engineer',
      'expertise': ['higher studies', 'AWS', 'DevOps'],
      'rating': 4.7,
      'avatar': 'assets/a3.png',
    },
    {
      'id': '4',
      'full_name': 'Amit Patel',
      'current_position': 'Full Stack Developer',
      'expertise': ['Web Development', 'React', 'Node.js'],
      'rating': 4.8,
      'avatar': 'assets/a1.png',
    },
  ];

  // ============================================================================
  // DATA - Discover Users List (In production, fetch from API)
  // ============================================================================
  List<Map<String, dynamic>> discoverUsers = [
    {
      'id': '1',
      'userName': 'Alice',
      'selectedCareer': 'Engineering',
      'userAvatar': 'assets/a2.png',
    },
  ];

  // ============================================================================
  // DATA - Colleges List (Loaded from Supabase)
  // ============================================================================
  List<Map<String, dynamic>> colleges = [];

  void _showConnectDialog(Map<String, dynamic> mentor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MentorDetailPage(mentor: mentor),
      ),
    );
  }

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _registerRefreshCallback();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController(initialPage: 0);
    _careerBannerController = PageController(initialPage: 0);
    _startAutoScroll();
    _loadUserProfile().then((_) async {
      if (_isQuizDone) {
        await _loadQuizStream();
      }
      await _loadColleges();
    });
    _loadMentors();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      _refreshData();
    }
  }

  /// Refresh all data when returning to the page
  Future<void> _refreshData() async {
    if (mounted) {
      debugPrint('🔄 [HomePage] Refreshing data...');

      // Show loading indicator briefly
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updating dashboard...'),
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xFF5E9EF5),
        ),
      );

      await Future.wait([_loadUserProfile(), _loadMentors()]);

      // Load quiz stream if quiz is done, then load colleges
      if (_isQuizDone) {
        await _loadQuizStream();
      }
      await _loadColleges();

      debugPrint('✅ [HomePage] Data refresh completed');
    }
  }

  /// Load quiz stream from userQuizData
  Future<void> _loadQuizStream() async {
    try {
      debugPrint('🔍 [Home] Loading quiz stream for user: $_userId');
      final response = await Supabase.instance.client
          .from('userQuizData')
          .select('quizInfo')
          .eq('userId', _userId)
          .maybeSingle();

      debugPrint('📦 [Home] Quiz data response: $response');

      if (response != null && response['quizInfo'] != null) {
        final quizInfo = response['quizInfo'] as Map<String, dynamic>;
        debugPrint('📦 [Home] Quiz info: $quizInfo');

        if (quizInfo['stream'] != null) {
          setState(() {
            _userStream = quizInfo['stream'].toString();
          });
          debugPrint('✅ [Home] User stream loaded: $_userStream');
        } else {
          debugPrint('⚠️ [Home] No stream found in quizInfo');
        }

        // Load degrees from quiz info
        if (quizInfo['degree'] != null) {
          if (quizInfo['degree'] is List) {
            setState(() {
              _userDegrees = (quizInfo['degree'] as List)
                  .map((item) => item.toString().toLowerCase())
                  .toList();
            });
          } else {
            setState(() {
              _userDegrees = [quizInfo['degree'].toString().toLowerCase()];
            });
          }
          debugPrint('✅ [Home] User degrees loaded: $_userDegrees');
        } else {
          debugPrint('⚠️ [Home] No degree found in quizInfo');
        }
      } else {
        debugPrint('⚠️ [Home] No quiz data found for user');
      }
    } catch (e) {
      debugPrint('❌ [Home] Error loading quiz stream: $e');
    }
  }

  /// Load mentors from Supabase
  Future<void> _loadMentors() async {
    try {
      debugPrint('🔍 [Home] Loading mentors from Supabase...');
      final response = await Supabase.instance.client
          .from('mentor')
          .select()
          .order('rating', ascending: false)
          .limit(10);

      debugPrint('✅ [Home] Mentors loaded: ${response.length} mentors found');

      if (mounted) {
        setState(() {
          mentors = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('❌ [Home] Error loading mentors: $e');
      // Keep the default mentors if loading fails
    }
  }

  /// Load colleges from Supabase
  Future<void> _loadColleges() async {
    try {
      debugPrint('🔍 [Home] Loading colleges from Supabase...');
      debugPrint(
        '🔍 [Home] Quiz done: $_isQuizDone, User stream: $_userStream, User degrees: $_userDegrees',
      );

      // Load user's colleges with diverse selection for dashboard
      final response = await Supabase.instance.client
          .from('colleges')
          .select()
          .eq('user_id', _userId)
          .limit(30);

      debugPrint('✅ [Home] Raw response: $response');
      debugPrint('✅ [Home] Response type: ${response.runtimeType}');

      debugPrint('✅ [Home] Colleges loaded: ${response.length} colleges found');

        if (mounted) {
          List<Map<String, dynamic>> allColleges = response
              .map((item) {
                try {
                  return Map<String, dynamic>.from(item as Map);
                } catch (e) {
                  debugPrint('Error converting item: $e');
                  return <String, dynamic>{};
                }
              })
              .where((college) => college.isNotEmpty)
              .toList();

          // If quiz is done and stream/degrees are available, filter and sort colleges
          debugPrint(
            '🔍 [Home] Quiz status check: isQuizDone=$_isQuizDone, userStream="$_userStream", userDegrees=$_userDegrees',
          );

          if (_isQuizDone &&
              (_userStream.isNotEmpty || _userDegrees.isNotEmpty)) {
            debugPrint(
              '🎯 [Home] Filtering colleges for stream: $_userStream, degrees: $_userDegrees',
            );

            // Split into matching and non-matching colleges
            List<Map<String, dynamic>> matchingColleges = [];
            List<Map<String, dynamic>> otherColleges = [];

            for (var college in allColleges) {
              final bestSuitForRaw = college['career'];
              final streamLower = _userStream.toLowerCase();

              // Handle best_suit_for as either List or String
              List<String> bestSuitForList = [];
              if (bestSuitForRaw is List) {
                bestSuitForList = bestSuitForRaw
                    .map((item) => item.toString().toLowerCase())
                    .toList();
              } else if (bestSuitForRaw != null) {
                bestSuitForList = [bestSuitForRaw.toString().toLowerCase()];
              }

              debugPrint(
                '🔍 Checking college: ${college['name']}, career: $bestSuitForList',
              );

              // Check if any item in best_suit_for matches the stream OR degrees
              bool matches = false;
              String matchReason = '';

              // Check against stream if available
              if (_userStream.isNotEmpty) {
                for (var suitItem in bestSuitForList) {
                  // Direct match
                  if (suitItem.contains(streamLower) ||
                      streamLower.contains(suitItem)) {
                    matches = true;
                    matchReason =
                        'stream match: "$suitItem" with "$streamLower"';
                    break;
                  }

                  // Word-by-word matching
                  final streamWords = streamLower.split(' ');
                  final suitWords = suitItem.split(' ');

                  for (var streamWord in streamWords) {
                    if (streamWord.length > 2 &&
                        suitItem.contains(streamWord)) {
                      matches = true;
                      matchReason = 'stream word "$streamWord" in "$suitItem"';
                      break;
                    }
                  }

                  if (matches) break;

                  for (var suitWord in suitWords) {
                    if (suitWord.length > 2 && streamLower.contains(suitWord)) {
                      matches = true;
                      matchReason = 'suit word "$suitWord" in stream';
                      break;
                    }
                  }

                  if (matches) break;
                }
              }

              // Check against degrees if not already matched
              if (!matches && _userDegrees.isNotEmpty) {
                for (var degree in _userDegrees) {
                  for (var suitItem in bestSuitForList) {
                    if (suitItem.contains(degree) ||
                        degree.contains(suitItem)) {
                      matches = true;
                      matchReason = 'degree match: "$degree" with "$suitItem"';
                      break;
                    }

                    // Check degree abbreviations (e.g., "btech" matches "b.tech")
                    String degreeClean = degree
                        .replaceAll('.', '')
                        .replaceAll(' ', '');
                    String suitClean = suitItem
                        .replaceAll('.', '')
                        .replaceAll(' ', '');

                    if (degreeClean.contains(suitClean) ||
                        suitClean.contains(degreeClean)) {
                      matches = true;
                      matchReason =
                          'degree abbreviation match: "$degreeClean" with "$suitClean"';
                      break;
                    }
                  }
                  if (matches) break;
                }
              }

              if (matches) {
                matchingColleges.add(college);
                debugPrint('✅ MATCHED: ${college['name']} ($matchReason)');
              } else {
                otherColleges.add(college);
                debugPrint('❌ NO MATCH: ${college['name']}');
              }
            }

            // Combine: matching colleges first, then others
            allColleges = [...matchingColleges, ...otherColleges];
            debugPrint(
              '✅ [Home] Filtered: ${matchingColleges.length} matching, ${otherColleges.length} others',
            );
          } else {
            debugPrint(
              '📋 [Home] Showing all colleges (quiz not done or no stream)',
            );
          }

          setState(() {
            colleges = allColleges;
          });
          debugPrint('✅ [Home] Colleges state updated: ${colleges.length} colleges');
        }
    } catch (e) {
      debugPrint('❌ [Home] Error loading colleges: $e');
      debugPrint('❌ [Home] Stack trace: ${StackTrace.current}');
      // Keep empty list if loading fails
    }
  }

  /// Load user profile data
  Future<void> _loadUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _userId = user.id;
        });

        // Get Google profile photo if available
        final userMetadata = user.userMetadata;
        if (userMetadata != null && userMetadata['avatar_url'] != null) {
          setState(() {
            _userPhotoUrl = userMetadata['avatar_url'];
          });
        }

        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (response != null && response['userName'] != null) {
          setState(() {
            _userName = response['userName'];
            _userInitial = response['userName'][0].toUpperCase();

            // Get user status (profession) and focus
            if (response['current_status'] != null) {
              _userStatus = response['current_status'];
            } else if (response['profession'] != null) {
              _userStatus = response['profession'];
            }

            if (response['mainFocus'] != null) {
              _userFocus = response['mainFocus'];
            } else if (response['focus'] != null) {
              _userFocus = response['focus'];
            }

            // Get quiz completion status
            if (response['isQuizDone'] != null) {
              _isQuizDone = response['isQuizDone'] == true;
            }
          });

          // Load quiz stream if quiz is done
          if (_isQuizDone) {
            await _loadQuizStream();
          }
        } else {
          setState(() {
            _userName = user.email?.split('@')[0] ?? 'User';
            _userInitial = _userName[0].toUpperCase();
          });
        }
      }
    } catch (e) {
      final user = Supabase.instance.client.auth.currentUser;
      setState(() {
        _userId = user?.id ?? '';
        _userName = user?.email?.split('@')[0] ?? 'User';
        _userInitial = _userName[0].toUpperCase();
      });
    }
  }

  /// Start automatic scrolling for hero banner carousel
  void _startAutoScroll() {
    _carouselTimer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentCarouselIndex + 1;
        if (nextPage > 3) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    HomePageState._refreshCallback = null;
    WidgetsBinding.instance.removeObserver(this);
    _carouselTimer?.cancel();
    _pageController.dispose();
    _careerBannerController.dispose();
    super.dispose();
  }

  // ============================================================================
  // BUILD METHOD - Main Widget Tree
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    /// Helper function to determine which page to display based on bottom nav selection
    Widget getBodyContent() {
      switch (_bottomNavIndex) {
        case 1: // Calendar Tab
          return CalendarPage();
        case 2: // Chat Tab
          return ChatPage();
        case 3: // Profile Tab (placeholder)
          return _buildProfilePage();
        default: // Home Tab (case 0)
          return RefreshIndicator(
            onRefresh: _refreshData,
            color: Color(0xFF5E9EF5),
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildTopSearchBar(),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        _buildWelcomeSection(),
                        SizedBox(height: 16),
                        _buildAIToolsCards(),
                        SizedBox(height: 16),
                        _buildRecommendedMentors(),
                        SizedBox(height: 20),
                        _buildCareerBanners(),
                        SizedBox(height: 20),
                        _buildDiscoverColleges(),
                        SizedBox(height: 80), // Extra space for bottom nav
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      drawer: Drawer(child: _buildSidebar()),
      body: SafeArea(
        top: false, // Top bar has its own padding
        child: getBodyContent(),
      ),
      bottomNavigationBar: SafeArea(
        child: _buildBottomNavigationBar(),
      ),
    );
  }

  // ============================================================================
  // SIDEBAR - Left Navigation Drawer
  // ============================================================================

  /// Build the sidebar navigation drawer with logo, menu items, and user profile
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: Color(0xFF1B2347),
      child: Column(
        children: [
          // ============================================================
          // SIDEBAR SECTION: Logo and Branding
          // ============================================================
          Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/clarioWhite.png',
                      height: 45,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'C',
                              style: TextStyle(
                                color: Color(0xFF1B2347),
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Reskill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Connect',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text('  •  ', style: TextStyle(color: Colors.white70)),
                    Text(
                      'Learn',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    Text('  •  ', style: TextStyle(color: Colors.white70)),
                    Text(
                      'Grow',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(
            color: Colors.white.withValues(alpha: 0.1),
            thickness: 1,
            height: 1,
          ),

          SizedBox(height: 12),

          // ============================================================
          // SIDEBAR SECTION: Navigation Menu Items
          // ============================================================
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0, false),
                Container(
                  margin: EdgeInsets.symmetric(vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.people_alt_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    title: Text(
                      'Mentor Connect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    dense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MentorConnectPage(),
                        ),
                      );
                    },
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    leading: Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    title: Text(
                      'Career Board',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 0,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CareerBoardPage(),
                        ),
                      );
                    },
                  ),
                ),
                _buildNavItem(Icons.route_rounded, 'My Tracks', 3, true),

                SizedBox(height: 12),

                // ============================================================
                // SIDEBAR SUBSECTION: AI Tools Dropdown Menu
                // ============================================================
                InkWell(
                  onTap: () {
                    setState(() {
                      _isAiToolsExpanded = !_isAiToolsExpanded;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 12,
                      right: 12,
                      top: 8,
                      bottom: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI TOOLS',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Icon(
                          _isAiToolsExpanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: Colors.white.withValues(alpha: 0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isAiToolsExpanded) ...[
                  // AI Career Coach - Navigate to CareerCoachPage
                  _buildSubNavItem(
                    Icons.school_rounded,
                    'AI Career Coach',
                    false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CareerCoachPage(),
                        ),
                      );
                    },
                  ),
                  // AI Roadmap Generator - Navigate to RoadmapPage
                  _buildSubNavItem(
                    Icons.map_rounded,
                    'AI Roadmap',
                    false,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RoadmapPage()),
                      );
                    },
                  ),
                  // Job Tracker - Coming soon
                  _buildSubNavItem(
                    Icons.work_outline_rounded,
                    'AI Job Tracker',
                    false,
                  ),
                  // Resume Maker - Pro feature
                  _buildSubNavItem(
                    Icons.description_outlined,
                    'AI Resume Maker',
                    true,
                  ),
                  // Interview Prep - Pro feature
                  _buildSubNavItem(
                    Icons.mic_outlined,
                    'AI Interview Prep',
                    true,
                  ),
                ],
              ],
            ),
          ),

          // ============================================================
          // SIDEBAR SECTION: Credits Card
          // ============================================================
          Container(
            margin: EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFCCE5FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Color(0xFF5E9EF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.credit_card_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Credits',
                            style: TextStyle(
                              color: Color(0xFF1B2347),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        '100',
                        style: TextStyle(
                          color: Color(0xFF1B2347),
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Top Up',
                            style: TextStyle(
                              color: Color(0xFF5E9EF5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF5E9EF5),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/card1.png',
                    width: 95,
                    height: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 95,
                        height: 65,
                        decoration: BoxDecoration(
                          color: Color(0xFF1B2347).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.credit_card,
                          color: Color(0xFF1B2347),
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ============================================================
          // SIDEBAR SECTION: User Profile Footer
          // ============================================================
          InkWell(
            onTap: () async {
              // Show logout confirmation dialog
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout'),
                  content: Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: Text('Logout'),
                    ),
                  ],
                ),
              );

              // If user confirmed, perform logout
              if (shouldLogout == true) {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(0xFF5E9EF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        _userInitial,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // SIDEBAR COMPONENTS - Navigation Items
  // ============================================================================

  /// Build a main navigation item for the sidebar
  /// [icon] - Icon to display
  /// [label] - Text label for the nav item
  /// [index] - Navigation index for selection state
  /// [isPro] - Whether this is a Pro feature (shows Pro badge)
  Widget _buildNavItem(IconData icon, String label, int index, bool isPro) {
    bool isSelected = _selectedNavIndex == index;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? Color(0xFF5E9EF5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isPro) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        onTap: () {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
    );
  }

  /// Build a sub-navigation item for expandable sections (e.g., AI Tools)
  /// [icon] - Icon to display
  /// [label] - Text label for the nav item
  /// [isPro] - Whether this is a Pro feature (shows Pro badge)
  /// [onTap] - Optional callback when item is tapped
  Widget _buildSubNavItem(
    IconData icon,
    String label,
    bool isPro, {
    VoidCallback? onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
        title: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (isPro) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B9D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        dense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        onTap: onTap ?? () {},
      ),
    );
  }

  // ============================================================================
  // TOP BAR - Search Bar with Hamburger Menu
  // ========================================================================  /// Build the new premium teal header from the design
  Widget _buildTopSearchBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF064D44), // Main Teal Color
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 50, 20, 24),
      child: Column(
        children: [
          // Unified Top Bar: Menu, Brand, Search, and Profile
          Row(
            children: [
              // Menu Toggle
              GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              // Brand Name
              const Text(
                'ReSkill',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              // Notification and Profile
              Row(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Color(0xFFFF5252), shape: BoxShape.circle),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _bottomNavIndex = 3;
                      });
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _userPhotoUrl != null 
                          ? Image.network(_userPhotoUrl!, width: 42, height: 42, fit: BoxFit.cover)
                          : Container(
                              width: 42,
                              height: 42,
                              color: Colors.white24,
                              child: Center(child: Text(_userInitial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Field in its own row below ReSkill
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search, color: Colors.white.withOpacity(0.5), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search mentors...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(bottom: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Row 3: Banner Carousel
          SizedBox(
            height: 210,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentCarouselIndex = index;
                });
              },
              children: [
                _buildModernBanner(
                  title: 'FIND YOUR DREAM JOB',
                  subtitle: 'Discover opportunities that match your career goals.',
                  image: 'assets/element5.png',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CareerBoardPage()));
                  },
                ),
                _buildModernBanner(
                  title: 'CONNECT WITH MENTORS',
                  subtitle: 'Get guidance from industry experts and professionals.',
                  image: 'assets/element1.png',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MentorConnectPage()));
                  },
                ),
                _buildModernBanner(
                  title: 'AI CAREER COACH',
                  subtitle: 'Get personalized career path recommendations.',
                  image: 'assets/element3.png',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const CareerCoachPage()));
                  },
                ),
                _buildModernBanner(
                  title: 'SKILL ROADMAPS',
                  subtitle: 'Step-by-step guides to master any new skill.',
                  image: 'assets/element4.png',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const RoadmapPage()));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _currentCarouselIndex == index ? 20 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _currentCarouselIndex == index ? Colors.white : Colors.white24,
              ),
            )),
          ),
        ],
      ),
    );
  }

  /// Build individual banner page for the hero carousel
  Widget _buildModernBanner({
    required String title,
    required String subtitle,
    required String image,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Explore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Image.asset(
              image,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_awesome, color: Colors.white38, size: 60),
            ),
          ),
        ],
      ),
    );
  }

  /// Deprecated, now integrated into header
  Widget _buildHeroBanner() {
    return const SizedBox.shrink();
  }

  /// Build individual banner page for the hero carousel
  /// [gradient] - Background gradient colors
  /// [title] - Main title text
  /// [subtitle] - Subtitle description
  /// [imagePath] - Path to the banner image
  /// [buttonColor] - Color for the CTA button
  /// [buttonText] - Text for the button
  /// [buttonIcon] - Icon for the button
  Widget _buildBannerPage({
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color buttonColor,
    required String buttonText,
    required IconData buttonIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left Content - White with slight color shade
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // White background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                ),
                // Light color in top corner
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          gradient[0].withValues(alpha: 0.15),
                          gradient[0].withValues(alpha: 0.05),
                          Colors.white.withValues(alpha: 0),
                        ],
                        radius: 0.8,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                      ),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B1B1B),
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 10),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF3B3B3B),
                          height: 1.4,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(buttonIcon, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right Image - Colored background
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: gradient[0],
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // WELCOME SECTION - User Greeting
  // ============================================================================

  /// Build the welcome section with user greeting
  /// Build the welcome greeting section for the user with dynamic action buttons
  Widget _buildWelcomeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Welcome, $_userName',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B2347),
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              // Restored Functionality Buttons
              if (!_isQuizDone)
                _buildActionButton(
                  'Quiz',
                  Icons.bolt,
                  const Color(0xFF5E9EF5),
                  () => QuizStartDialog.show(
                    context,
                    currentStatus: _userStatus,
                    mainFocus: _userFocus,
                    userName: _userName,
                    userId: _userId,
                    userAvatar: null,
                  ),
                )
              else if (_userFocus.toLowerCase() == 'choose career paths' || _userFocus.isEmpty)
                _buildActionButton(
                  'Plan Career',
                  Icons.auto_awesome,
                  const Color(0xFF5E9EF5),
                  () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const CareerCoachPage()));
                    _refreshData();
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF5E9EF5).withOpacity(0.3)),
                  ),
                  child: Text(
                    'Career: $_userFocus',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'AI Tools & Resources',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B2347),
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Build a 2x2 grid of AI tools cards
  Widget _buildAIToolsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'AI Career Coach',
                Icons.school_outlined,
                const Color(0xFFE0F2F1),
                const Color(0xFF00796B),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CareerCoachPage())),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolCard(
                'AI Roadmap Maker',
                Icons.map_outlined,
                const Color(0xFFE8EAF6),
                const Color(0xFF3F51B5),
                () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RoadmapPage())),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToolCard(
                'Interview Prep',
                Icons.assignment_outlined,
                const Color(0xFFFFF3E0),
                const Color(0xFFE65100),
                () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToolCard(
                'AI Skill Paths',
                Icons.menu_book_outlined,
                const Color(0xFFE1F5FE),
                const Color(0xFF0277BD),
                () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // RECOMMENDED MENTORS - Mentor Cards Carousel
  // ============================================================================

  Widget _buildRecommendedMentors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Recommended Mentors',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1B2347),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.group, color: Color(0xFF5E9EF5), size: 24),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 340, // Height for vertical cards
            child: mentors.isEmpty
                ? Center(
                    child: Text(
                      'No mentors available',
                      style: GoogleFonts.inter(color: Colors.grey[400]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mentors.length + 1,
                    itemBuilder: (context, index) {
                      if (index == mentors.length) {
                        return _buildViewMoreMentorCard();
                      }
                      return _buildMentorCard(mentors[index]);
                    },
                  ),
          ),
        ],
      );
    }


  Widget _buildViewMoreMentorCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MentorConnectPage(),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16, bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF5E9EF5).withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF5E9EF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'View More',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B2347),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find full list',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    // Solid soft colors for headers
    final headerColors = [
      const Color(0xFFFEF3C7), // Soft yellow/orange from photo
      const Color(0xFFFFD1DC), // Soft pink
      const Color(0xFFE2F9C0), // Soft green
      const Color(0xFFE0F2FE), // Soft blue
    ];
    final colorIndex = (mentor['id'] ?? 0).hashCode.abs() % headerColors.length;
    final headerColor = headerColors[colorIndex];
    
    final expertise = mentor['expertise'] as List? ?? [];
    final name = mentor['full_name']?.toString() ?? 'Mentor';
    final position = mentor['current_position']?.toString() ?? 'Professional';
    final rating = (mentor['rating'] ?? 5.0).toDouble();

    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header background with profile image
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  bottom: -30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.grey[100],
                        backgroundImage: mentor['avatar'] != null && mentor['avatar'].toString().isNotEmpty
                            ? (mentor['avatar'].toString().startsWith('assets/') 
                                ? AssetImage(mentor['avatar']) as ImageProvider
                                : NetworkImage(mentor['avatar']))
                            : null,
                        child: (mentor['avatar'] == null || mentor['avatar'].toString().isEmpty)
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'M',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          
          // Rating Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFFB300), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rating.toStringAsFixed(1),
                  style: GoogleFonts.inter(
                    color: const Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.star, color: Color(0xFFFFB300), size: 10),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1B2347),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          
          // Position
          Text(
            position,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF5E9EF5),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Expertise
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Expertise: ${expertise.take(3).join(', ')}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.grey[600],
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const Spacer(),

          // Book Session Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showConnectDialog(mentor),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5E9EF5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Book Session',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.videocam, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareerBanners() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView(
            controller: _careerBannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            children: [
              _buildCareerBanner(
                backgroundColor: Color(0xFFFFE5E5),
                borderColor: Color(0xFFFFCCCC),
                title:
                    "It's Time To Take Your Career To The Next Level And Shine!",
                titleColor: Color(0xFFD81B60),
                buttons: [
                  {'text': 'Check Job Listings', 'icon': Icons.mail_outline},
                  {'text': 'Check Courses', 'icon': Icons.book_outlined},
                ],
                buttonColor: Colors.white,
                buttonTextColor: Color(0xFF1B2347),
                imagePath: 'assets/element7.png',
                decorativeColor: Color(0xFFFF6B9D),
              ),
              _buildCareerBanner(
                backgroundColor: Color(0xFFFFF8DC),
                borderColor: Color(0xFFFFE4A0),
                title: "Prepare Well For Your Job Interviews.",
                titleColor: Color(0xFF1B2347),
                buttons: [
                  {'text': 'Job Tracker', 'icon': Icons.work_outline},
                  {'text': 'Interview Prep', 'icon': Icons.play_circle_outline},
                ],
                buttonColor: Color(0xFFFFB300),
                buttonTextColor: Colors.white,
                imagePath: 'assets/prep2.png',
                decorativeColor: Color(0xFFFFD54F),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            2,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBannerIndex == index
                    ? Color(0xFF5E9EF5)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCareerBanner({
    required Color backgroundColor,
    required Color borderColor,
    required String title,
    required Color titleColor,
    required List<Map<String, dynamic>> buttons,
    required Color buttonColor,
    required Color buttonTextColor,
    required String imagePath,
    required Color decorativeColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Stack(
        children: [
          // Decorative pattern
          Positioned(
            left: -30,
            top: -30,
            child: CustomPaint(
              size: Size(150, 150),
              painter: CirclePatternPainter(color: decorativeColor),
            ),
          ),
          Positioned(
            right: -30,
            bottom: -30,
            child: CustomPaint(
              size: Size(120, 120),
              painter: CirclePatternPainter(color: decorativeColor),
            ),
          ),

          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left side - Image
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 0, left: 12, right: 12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('Failed to load image: $imagePath');
                        debugPrint('Error: $error');
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Image not found',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Right side - Text and buttons
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: titleColor,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: buttons.map((btn) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: ElevatedButton.icon(
                                onPressed: () {},
                                icon: Icon(btn['icon'], size: 10),
                                label: Text(
                                  btn['text'],
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: buttonTextColor,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  elevation: 2,
                                  shadowColor: Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BOTTOM NAVIGATION BAR - Main App Navigation
  // ============================================================================

  /// Build the bottom navigation bar with Home, Calendar, Chat, Profile tabs
  /// Build the bottom navigation bar with customized styling
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(36),
          topRight: Radius.circular(36),
        ),
        child: BottomNavigationBar(
          currentIndex: _bottomNavIndex,
          onTap: (index) {
            setState(() {
              _bottomNavIndex = index;
            });
            // Refresh data when switching back to home tab (index 0)
            if (index == 0) {
              _refreshData();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF064D44),
          unselectedItemColor: Colors.grey[400],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.home_filled, 0),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.calendar_month, 1),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.chat_bubble_outline, 2),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: _buildNavIcon(Icons.person_outline, 3),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    bool isSelected = _bottomNavIndex == index;
    if (isSelected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF034D41),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      );
    }
    return Icon(icon, size: 24);
  }

  // ============================================================================
  // DISCOVER COLLEGES - College Cards Showcase
  // ============================================================================

  /// Build the discover colleges section with horizontal scrollable cards
  Widget _buildDiscoverColleges() {
    // Show quiz completion prompt if quiz is not done
    if (!_isQuizDone) {
      return Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 50),
          decoration: BoxDecoration(
            color: Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Color(0xFF5E9EF5).withValues(alpha: 0.3),
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Complete Your Quiz To Unlock Your Career Potential',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 50),
              // Center Icon
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFF5E9EF5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF5E9EF5).withValues(alpha: 0.2),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 42,
                  color: Color(0xFF5E9EF5),
                ),
              ),
              SizedBox(height: 50),
              // Get Started Button
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => QuizStartDialog(
                      currentStatus: _userStatus,
                      mainFocus: _userFocus,
                      userName: _userName,
                      userId: _userId,
                    ),
                  );
                },
                icon: Icon(Icons.show_chart, size: 20),
                label: Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5E9EF5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: Color(0xFF5E9EF5).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show colleges list if quiz is done
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Discover Colleges',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2347),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.apartment_rounded,
                    color: Color(0xFF5E9EF5),
                    size: 22,
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Color(0xFF5E9EF5),
                  side: BorderSide(color: Colors.grey[300]!, width: 1),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See All',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward, size: 10),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            'Discover top colleges nearby you',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: colleges.isEmpty
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xFF5E9EF5)),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: colleges.length,
                    itemBuilder: (context, index) {
                      try {
                        final college = colleges[index];
                        final collegeName =
                            college['name']?.toString() ??
                            'College Name';
                        final location =
                            college['location']?.toString() ?? 'India';
                        final fees = college['fees']?.toString() ?? 'N/A';
                        final placement =
                            college['placement']?.toString() ?? 'N/A';
                        final type = college['type']?.toString() ?? 'Institution';
                        final bestSuitFor =
                            college['career']?.toString() ?? 'N/A';

                        return _buildCollegeCard(
                          name: collegeName,
                          location: location,
                          fees: fees,
                          placement: placement,
                          type: type,
                          bestSuitFor: bestSuitFor,
                        );
                      } catch (e) {
                        debugPrint(
                          'Error building college card at index $index: $e',
                        );
                        return SizedBox.shrink();
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build individual college card
  /// [name] - College name
  /// [location] - College location
  /// [fees] - Fee structure
  /// [placement] - Placement package
  /// [type] - College type (government/private)
  /// [bestSuitFor] - Best suited for description
  Widget _buildCollegeCard({
    required String name,
    required String location,
    required String fees,
    required String placement,
    required String type,
    required String bestSuitFor,
  }) {
    return Container(
      width: 320,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // College Name
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2347),
                      height: 1.3,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // 1st Year Fees
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            size: 15,
                            color: Color(0xFF1B2347),
                          ),
                          SizedBox(width: 6),
                          Text(
                            '1st Year Fees',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1B2347),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        fees,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B2347),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Highest Placement
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 15,
                            color: Color(0xFF1B2347),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Highest Placement',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF1B2347),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        placement,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1B2347),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),

                  // Type
                  Row(
                    children: [
                      Icon(Icons.apartment, size: 15, color: Color(0xFF1B2347)),
                      SizedBox(width: 6),
                      Text(
                        type,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B2347),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14),

                  // Best suited for
                  Row(
                    children: [
                      Icon(Icons.school, size: 14, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        'Best suited for:',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1B2347),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Color(0xFF5E9EF5).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      bestSuitFor,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1B2347),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Decorative pattern image
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/static3.png',
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return SizedBox(
                    width: 100,
                    height: 80,
                    child: CustomPaint(
                      size: Size(100, 80),
                      painter: CollegePatternPainter(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Placeholder widgets - replace with actual implementations
class SlidingCards extends StatelessWidget {
  const SlidingCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text('Sliding Cards')),
    );
  }
}

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 800),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Welcome, User',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          ActionsButtons(),
        ],
      ),
    );
  }
}

class ActionsButtons extends StatelessWidget {
  const ActionsButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(onPressed: () {}, child: Text('Action 1')),
        SizedBox(width: 10),
        ElevatedButton(onPressed: () {}, child: Text('Action 2')),
      ],
    );
  }
}

class ActionBox extends StatelessWidget {
  const ActionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text('Action Box')),
    );
  }
}

class MentorsSection extends StatelessWidget {
  final List<Map<String, dynamic>> mentors;

  const MentorsSection({super.key, required this.mentors});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 1000),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey[300]!, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Recommended Mentors',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.people, color: Colors.blue),
                ],
              ),
              TextButton(onPressed: () {}, child: Text('View More')),
            ],
          ),
          SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mentors.length,
              itemBuilder: (context, index) {
                var mentor = mentors[index];
                return Container(
                  width: 250,
                  margin: EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.grey[300]!, blurRadius: 4),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.blue[200],
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 10,
                              left: 10,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: CircleAvatar(
                                radius: 40,
                                backgroundImage: AssetImage(mentor['avatar']),
                              ),
                            ),
                            Positioned(
                              left: 1 / 2 - 25,
                              bottom: 10,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.yellow),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${mentor['rating']}',
                                      style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 4),
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Text(
                              mentor['full_name'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              mentor['current_position'],
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Expertise: ${mentor['expertise'].join(', ')}',
                              style: TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(fontSize: 12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Book Session'),
                                  SizedBox(width: 4),
                                  Icon(Icons.screen_share, size: 14),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER CLASSES - Additional UI Components
// ============================================================================

// ============================================================================
// CUSTOM PAINTER - College Card Decorative Pattern
// ============================================================================

/// Custom painter for decorative wavy pattern on college cards
class CollegePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFF6B9D).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    // Draw diagonal wavy pattern
    final path = Path();
    path.moveTo(size.width * 0.3, size.height);
    path.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.8,
      size.width * 0.5,
      size.height * 0.85,
    );
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = Color(0xFFFF6B9D).withValues(alpha: 0.2);
    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height);
    path2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.75,
      size.width * 0.7,
      size.height * 0.8,
    );
    path2.lineTo(size.width, size.height * 0.4);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    paint.color = Color(0xFFFF6B9D).withValues(alpha: 0.25);
    final path3 = Path();
    path3.moveTo(size.width * 0.7, size.height);
    path3.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.7,
      size.width * 0.9,
      size.height * 0.75,
    );
    path3.lineTo(size.width, size.height * 0.3);
    path3.lineTo(size.width, size.height);
    path3.close();
    canvas.drawPath(path3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for decorative circle patterns on AI tool cards
class CirclePatternPainter extends CustomPainter {
  final Color color;

  CirclePatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw multiple concentric circles
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        i * 15.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================================
// PROFILE PAGE - User Profile with Logout
// ============================================================================

class _ProfilePageWidget extends StatefulWidget {
  @override
  State<_ProfilePageWidget> createState() => _ProfilePageWidgetState();
}

class _ProfilePageWidgetState extends State<_ProfilePageWidget> {
  Map<String, dynamic>? _userData;
  bool _loading = true;
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Get Google profile photo if available
        final userMetadata = user.userMetadata;
        if (userMetadata != null && userMetadata['avatar_url'] != null) {
          _profilePhotoUrl = userMetadata['avatar_url'];
        }

        // Load user data from users table
        final response = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        setState(() {
          _userData = response;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (_loading) {
      return Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(height: 40),

            // User Avatar with Google Photo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _profilePhotoUrl == null
                    ? LinearGradient(
                        colors: [Color(0xFF1B2347), Color(0xFF2D3A6F)],
                      )
                    : null,
                image: _profilePhotoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_profilePhotoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profilePhotoUrl == null
                  ? Center(
                      child: Text(
                        _userData?['userName']?.substring(0, 1).toUpperCase() ??
                            'U',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 24),

            // User Name
            Text(
              _userData?['userName'] ?? 'User',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2347),
              ),
            ),
            SizedBox(height: 8),

            // User Email
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),

            SizedBox(height: 40),

            // Profile Details Card
            Container(
              constraints: BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2347),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Email
                  _buildInfoRow(Icons.email, 'Email', user?.email ?? ''),

                  // Phone
                  if (_userData?['userPhone'] != null &&
                      _userData!['userPhone'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.phone,
                      'Phone',
                      _userData!['userPhone'],
                    ),
                  ],

                  // Current Status (Profession)
                  if (_userData?['current_status'] != null &&
                      _userData!['current_status'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.school,
                      'Current Status',
                      _userData!['current_status'],
                    ),
                  ],

                  // Institution
                  if (_userData?['institutionName'] != null &&
                      _userData!['institutionName'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.location_city,
                      'Institution',
                      _userData!['institutionName'],
                    ),
                  ],

                  // Main Focus (from quiz)
                  if (_userData?['mainFocus'] != null &&
                      _userData!['mainFocus'].toString().isNotEmpty &&
                      _userData!['mainFocus'].toString().toLowerCase() !=
                          'choose career paths') ...[
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.lightbulb_outline,
                      'Focus',
                      _userData!['mainFocus'],
                    ),
                  ],

                  // Career Path (if set)
                  if (_userData?['mainFocus'] != null &&
                      _userData!['mainFocus'].toString().isNotEmpty &&
                      _userData!['mainFocus'].toString().toLowerCase() !=
                          'choose career paths') ...[
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.work_outline,
                      'Career Path',
                      _userData!['mainFocus'],
                    ),
                  ],

                  // Quiz Status
                  SizedBox(height: 16),
                  _buildInfoRow(
                    Icons.quiz,
                    'Quiz Status',
                    _userData?['isQuizDone'] == true
                        ? 'Completed ✓'
                        : 'Not Completed',
                  ),

                  // Credits
                  if (_userData?['remainingCredits'] != null) ...[
                    SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.stars,
                      'Remaining Credits',
                      '${_userData!['remainingCredits']} / ${_userData!['totalCredits'] ?? 100}',
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 32),

            // Logout Button
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 500),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                },
                icon: Icon(Icons.logout),
                label: Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1B2347),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Color(0xFF1B2347)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, color: Color(0xFF1B2347)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Widget _buildProfilePage() {
  return _ProfilePageWidget();
}

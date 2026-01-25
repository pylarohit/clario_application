// ============================================================================
// HOME PAGE - Main Landing Screen
// ============================================================================
// This is the main home page of the Clario application that contains:
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
import 'chat_page.dart';

/// Main Home Page Widget
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================
  
  // Navigation state variables
  int _selectedNavIndex = 0;        // Sidebar navigation index
  int _bottomNavIndex = 0;          // Bottom navigation bar index
  bool _isAiToolsExpanded = false;  // AI Tools dropdown expansion state
  bool _isQuickActionsExpanded = false;
  
  // Carousel state variables
  int _currentCarouselIndex = 0;    // Current hero banner index
  int _currentBannerIndex = 0;      // Current career banner index
  
  // User profile data
  String _userName = 'User';
  String _userInitial = 'U';
  
  // Controllers
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late PageController _pageController;         // Hero banner page controller
  late PageController _careerBannerController; // Career banner page controller
  Timer? _carouselTimer;                       // Auto-scroll timer for hero banner

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
      'expertise': ['higher studies', 'career/path guidance', 'counseling & guidance'],
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
  // LIFECYCLE METHODS
  // ============================================================================
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _careerBannerController = PageController(initialPage: 0);
    _startAutoScroll();
    _loadUserProfile();
  }
  
  /// Load user profile data
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
            _userInitial = response['full_name'][0].toUpperCase();
          });
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
    Widget _getBodyContent() {
      switch (_bottomNavIndex) {
        case 1: // Calendar Tab
          return CalendarPage();
        case 2: // Chat Tab
          return ChatPage();
        case 3: // Profile Tab (placeholder)
          return _buildProfilePage();
        default: // Home Tab (case 0)
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildTopSearchBar(),
                SizedBox(height: 12),
                _buildHeroBanner(),
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
          );
      }
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFF5F7FA),
      drawer: Drawer(child: _buildSidebar()),
      body: _getBodyContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
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
                      'Clario',
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
                    Text('Connect', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('  •  ', style: TextStyle(color: Colors.white70)),
                    Text('Learn', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('  •  ', style: TextStyle(color: Colors.white70)),
                    Text('Grow', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          Divider(color: Colors.white.withOpacity(0.1), thickness: 1, height: 1),
          
          SizedBox(height: 12),

          // ============================================================
          // SIDEBAR SECTION: Navigation Menu Items
          // ============================================================
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0, false),
                _buildNavItem(Icons.people_alt_rounded, 'Mentor Connect', 1, false),
                _buildNavItem(Icons.bar_chart_rounded, 'Career Board', 2, false),
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
                    padding: EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI TOOLS',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Icon(
                          _isAiToolsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white.withOpacity(0.5),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isAiToolsExpanded) ...[
                  // AI Career Coach - Navigate to CareerCoachPage
                  _buildSubNavItem(Icons.school_rounded, 'AI Career Coach', false, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CareerCoachPage()),
                    );
                  }),
                  // AI Roadmap Generator - Navigate to RoadmapPage
                  _buildSubNavItem(Icons.map_rounded, 'AI Roadmap', false, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RoadmapPage()),
                    );
                  }),
                  // Job Tracker - Coming soon
                  _buildSubNavItem(Icons.work_outline_rounded, 'AI Job Tracker', false),
                  // Resume Maker - Pro feature
                  _buildSubNavItem(Icons.description_outlined, 'AI Resume Maker', true),
                  // Interview Prep - Pro feature
                  _buildSubNavItem(Icons.mic_outlined, 'AI Interview Prep', true),
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
                          color: Color(0xFF1B2347).withOpacity(0.2),
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
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
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
  Widget _buildSubNavItem(IconData icon, String label, bool isPro, {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
        title: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
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
  // ============================================================================
  
  /// Build the top search bar with menu button and search functionality
  Widget _buildTopSearchBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 45, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFF5E9EF5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.menu_rounded, color: Color(0xFF5E9EF5), size: 22),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 42,
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[500], size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search mentors......',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF1B2347),
                    size: 20,
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF6B9D),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5E9EF5), Color(0xFF4A7FD6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF5E9EF5).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'R',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // HERO BANNER - Carousel Section
  // ============================================================================
  
  /// Build the hero banner carousel with auto-scrolling cards
  Widget _buildHeroBanner() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.symmetric(horizontal: 12),
          height: 213,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF5E9EF5).withOpacity(0.3),
                blurRadius: 30,
                offset: Offset(0, 15),
              ),
            ],
          ),
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselIndex = index;
              });
            },
            children: [
              _buildBannerPage(
                gradient: [Color(0xFFE8C5E8), Color(0xFFE8C5E8)],
                title: 'Connect With Skilled Mentors',
                subtitle: 'Learn from industry experts who will guide you through your professional journey.',
                imagePath: 'assets/element7.png',
                buttonColor: Color(0xFFE673E6),
              ),
              _buildBannerPage(
                gradient: [Color(0xFFD4E4F7), Color(0xFFD4E4F7)],
                title: 'Find Your Dream Job Here',
                subtitle: 'Discover thousands of opportunities that match your skills and aspirations.',
                imagePath: 'assets/prep2.png',
                buttonColor: Color(0xFF7CB4F7),
              ),
              _buildBannerPage(
                gradient: [Color(0xFFFFF4CC), Color(0xFFFFF4CC)],
                title: 'Build Your Career Path',
                subtitle: 'Take control of your professional future with our comprehensive career-building tools.',
                imagePath: 'assets/element8.png',
                buttonColor: Color(0xFFFFD54F),
              ),
              _buildBannerPage(
                gradient: [Color(0xFFFFCDD2), Color(0xFFFFCDD2)],
                title: 'Turn Passion Into Profession',
                subtitle: 'Transform what you love into a successful career. Get guidance, resources, and opportunities.',
                imagePath: 'assets/element2.png',
                buttonColor: Color(0xFFFF8A95),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            4,
            (index) => Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentCarouselIndex == index
                    ? Color(0xFF5E9EF5)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build individual banner page for the hero carousel
  /// [gradient] - Background gradient colors
  /// [title] - Main title text
  /// [subtitle] - Subtitle description
  /// [imagePath] - Path to the banner image
  /// [buttonColor] - Color for the CTA button
  Widget _buildBannerPage({
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color buttonColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white,
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
                          gradient[0].withOpacity(0.15),
                          gradient[0].withOpacity(0.05),
                          Colors.white.withOpacity(0),
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
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
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
                      SizedBox(height: 14),
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
                              'Get Started',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
                )
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
              child: Padding(
                padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      );
                    },
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
  Widget _buildWelcomeSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Welcome, $_userName',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B2347),
            ),
          ),
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.bolt, size: 20),
              label: Text('Quiz', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF5E9EF5),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {},
              child: Text('Explore', style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF1B2347),
                side: BorderSide(color: Colors.grey[300]!),
                padding: EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAIToolsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isQuickActionsExpanded = !_isQuickActionsExpanded;
            });
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                ),
              ),
              Icon(
                _isQuickActionsExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: Color(0xFF5E9EF5),
                size: 28,
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // First Row - Always visible
        Row(
          children: [
            Expanded(
              child: _buildAIToolCard(
                icon: Icons.school,
                title: 'AI Career Coach',
                description: 'Unlock your potential with AI-guided career wisdom.',
                color: Color(0xFF5E9EF5),
                borderColor: Color(0xFF5E9EF5),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildAIToolCard(
                icon: Icons.map,
                title: 'AI Roadmap Maker',
                description: 'Chart your journey with a clear, personalized path..',
                color: Color(0xFFFFA726),
                borderColor: Color(0xFFFFA726),
              ),
            ),
          ],
        ),
        // Expandable Rows
        if (_isQuickActionsExpanded) ...[
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAIToolCard(
                  icon: Icons.people,
                  title: 'Connect Mentors',
                  description: 'Learn from mentors who\'ve walked the path before you.',
                  color: Color(0xFFE91E63),
                  borderColor: Color(0xFFE91E63),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAIToolCard(
                  icon: Icons.video_call,
                  title: 'Interview Prep',
                  description: 'Prepare for interviews with confidence.',
                  color: Color(0xFFFF9800),
                  borderColor: Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAIToolCard(
                  icon: Icons.dashboard,
                  title: 'Career Board',
                  description: 'Get Latest Industry insights, resources and opportunities',
                  color: Color(0xFF4CAF50),
                  borderColor: Color(0xFF4CAF50),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildAIToolCard(
                  icon: Icons.description,
                  title: 'AI Resume Maker',
                  description: 'Transform your resume into a recruiter-ready story.',
                  color: Color(0xFF9C27B0),
                  borderColor: Color(0xFF9C27B0),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAIToolCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      height: 90,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2347),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // RECOMMENDED MENTORS - Mentor Cards Carousel
  // ============================================================================
  
  /// Build the recommended mentors section with horizontal scroll
  Widget _buildRecommendedMentors() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                    'Recommended Mentors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2347),
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.people, color: Color(0xFF5E9EF5), size: 20),
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
                      'More',
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
          SizedBox(height: 10),
          Container(
            height: 280,
            child: mentors.isEmpty
                ? Center(
                    child: Text(
                      'No mentors available',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: mentors.length,
                    itemBuilder: (context, index) {
                      return _buildMentorCard(mentors[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor) {
    // Different gradient colors for variety
    final gradients = [
      [Color(0xFFFFB5D5), Color(0xFFFFD5E5)],
      [Color(0xFFFFE5A0), Color(0xFFFFF5C0)],
      [Color(0xFFB5D5FF), Color(0xFFD5E5FF)],
    ];
    final gradient = gradients[mentor['id'].hashCode % gradients.length];
    
    return Container(
      width: 200,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 0),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient header with profile picture
          Container(
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Profile picture
                Positioned(
                  bottom: -22,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: AssetImage(mentor['avatar']),
                        onBackgroundImageError: (exception, stackTrace) {},
                        child: Container(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 26),
          // Rating badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Color(0xFFFFB300), width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${mentor['rating']}',
                  style: TextStyle(
                    color: Color(0xFFFFB300),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                SizedBox(width: 3),
                Icon(Icons.star, color: Color(0xFFFFB300), size: 10),
              ],
            ),
          ),
          SizedBox(height: 5),
          // Name
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              mentor['full_name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF1B2347),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 2),
          // Position
          Text(
            mentor['current_position'],
            style: TextStyle(
              color: Color(0xFF5E9EF5),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 5),
          // Expertise
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12 ),
            child: Text(
              'Expertise: ${(mentor['expertise'] as List).join(', ')}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 1),
          // Book Session button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF5E9EF5),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Book Session',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.video_call, size: 18),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCareerBanners() {
    return Column(
      children: [
        Container(
          height: 170,
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
                title: "It's Time To Take Your Career To The Next Level And Shine!",
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
                        print('Failed to load image: $imagePath');
                        print('Error: $error');
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
                              style: TextStyle(fontSize: 10, color: Colors.grey),
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
                      SizedBox(height: 12),
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  elevation: 2,
                                  shadowColor: Colors.black.withOpacity(0.15),
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
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          setState(() {
            _bottomNavIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF5E9EF5),
        unselectedItemColor: Colors.grey[600],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // DISCOVER COLLEGES - College Cards Showcase
  // ============================================================================
  
  /// Build the discover colleges section with horizontal scrollable cards
  Widget _buildDiscoverColleges() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
                  Icon(Icons.apartment_rounded, color: Color(0xFF5E9EF5), size: 22),
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
          Container(
            height: 260,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCollegeCard(
                  name: 'DR BR AMBEDKAR NATIONAL INSTITUTE OF TECHNOLOGY - [NIT]',
                  location: 'Jalandhar, Punjab',
                  fees: '₹ 1,64,000',
                  placement: '₹ 52,00,000',
                  type: 'government',
                  courses: ['BE', 'B.TECH'],
                ),
                _buildCollegeCard(
                  name: 'THAPAR INSTITUTE OF ENGINEERING AND TECHNOLOGY - [THAPAR UNIVERSITY]',
                  location: 'Patiala, Punjab',
                  fees: '₹ 5,08,000',
                  placement: '₹ 1,23,00,000',
                  type: 'private',
                  courses: ['BE', 'B.TECH'],
                ),
                _buildCollegeCard(
                  name: 'KANYA MAHAVIDYALAYA - [KMV]',
                  location: 'Jalandhar, Punjab',
                  fees: '₹ 20,510',
                  placement: 'N/A',
                  type: 'private',
                  courses: ['B.SC'],
                ),
                _buildCollegeCard(
                  name: 'LOVELY PROFESSIONAL UNIVERSITY - [LPU]',
                  location: 'Jalandhar, Punjab',
                  fees: '₹ 1,50,000',
                  placement: '₹ 42,00,000',
                  type: 'private',
                  courses: ['BE'],
                ),
              ],
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
  Widget _buildCollegeCard({
    required String name,
    required String location,
    required String fees,
    required String placement,
    required String type,
    required List<String> courses,
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
            color: Colors.black.withOpacity(0.05),
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
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
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
                          Icon(Icons.account_balance_wallet, size: 15, color: Color(0xFF1B2347)),
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
                          Icon(Icons.trending_up, size: 15, color: Color(0xFF1B2347)),
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
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: courses.map((course) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: course == 'B.SC' ? Color(0xFF4CAF50) : Color(0xFFFF6B9D),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          course,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: course == 'B.SC' ? Color(0xFF4CAF50) : Color(0xFFFF6B9D),
                          ),
                        ),
                      );
                    }).toList(),
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
                  return Container(
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

  MentorsSection({required this.mentors});

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
          Container(
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
                                  color: Colors.white.withOpacity(0.25),
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
                                  color: Colors.white.withOpacity(0.3),
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
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Book Session'),
                                  SizedBox(width: 4),
                                  Icon(Icons.screen_share, size: 14),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                textStyle: TextStyle(fontSize: 12),
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
      ..color = Color(0xFFFF6B9D).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Draw diagonal wavy pattern
    final path = Path();
    path.moveTo(size.width * 0.3, size.height);
    path.quadraticBezierTo(
      size.width * 0.4, size.height * 0.8,
      size.width * 0.5, size.height * 0.85,
    );
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    paint.color = Color(0xFFFF6B9D).withOpacity(0.2);
    final path2 = Path();
    path2.moveTo(size.width * 0.5, size.height);
    path2.quadraticBezierTo(
      size.width * 0.6, size.height * 0.75,
      size.width * 0.7, size.height * 0.8,
    );
    path2.lineTo(size.width, size.height * 0.4);
    path2.lineTo(size.width, size.height);
    path2.close();
    canvas.drawPath(path2, paint);

    paint.color = Color(0xFFFF6B9D).withOpacity(0.25);
    final path3 = Path();
    path3.moveTo(size.width * 0.7, size.height);
    path3.quadraticBezierTo(
      size.width * 0.8, size.height * 0.7,
      size.width * 0.9, size.height * 0.75,
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
      ..color = color.withOpacity(0.15)
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
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        setState(() {
          _profile = response;
          _loading = false;
        });
      }
    } catch (e) {
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
            
            // User Avatar
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF1B2347), Color(0xFF2D3A6F)],
                ),
              ),
              child: Center(
                child: Text(
                  _profile?['full_name']?.substring(0, 1).toUpperCase() ?? 'U',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // User Name
            Text(
              _profile?['full_name'] ?? 'User',
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
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
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
                    color: Colors.black.withOpacity(0.05),
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
                  
                  if (_profile?['phone'] != null && _profile!['phone'].toString().isNotEmpty)
                    _buildInfoRow(Icons.phone, 'Phone', _profile!['phone']),
                  
                  if (_profile?['bio'] != null && _profile!['bio'].toString().isNotEmpty) ...[
                    SizedBox(height: 16),
                    _buildInfoRow(Icons.info_outline, 'Bio', _profile!['bio']),
                  ],
                  
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.email, 'Email', user?.email ?? ''),
                  
                  SizedBox(height: 16),
                  _buildInfoRow(Icons.fingerprint, 'User ID', user!.id.substring(0, 8) + '...'),
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
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1B2347),
                ),
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

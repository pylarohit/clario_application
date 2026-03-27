// ============================================================================
// MENTOR CONNECT PAGE - Main entry point for connecting with mentors
// ============================================================================
// Features:
// - Hero banner with promotional content
// - Video section showcasing mentor introductions
// - Searchable mentor grid with filtering
// - Responsive design for mobile, tablet, and desktop
// ============================================================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'mentor_detail_page.dart';

// Main StatefulWidget for Mentor Connect Page
class MentorConnectPage extends StatefulWidget {
  const MentorConnectPage({super.key});

  @override
  State<MentorConnectPage> createState() => _MentorConnectPageState();
}

class _MentorConnectPageState extends State<MentorConnectPage> {
  // ========== STATE VARIABLES ==========

  // Data storage
  List<Map<String, dynamic>> _mentors = []; // All mentors from database
  List<Map<String, dynamic>> _filteredMentors =
      []; // Filtered mentors based on search
  List<Map<String, dynamic>> _mentorVideos = []; // Mentors with video content

  // Loading states
  bool _isLoading = true; // Loading state for mentor list
  bool _isLoadingVideos = true; // Loading state for videos

  // Search functionality
  String _searchQuery = ''; // Current search query text
  final TextEditingController _searchController = TextEditingController();

  // Controllers for UI elements
  late PageController _pageController; // For banner carousel
  final ScrollController _scrollController =
      ScrollController(); // For main scroll

  // ========== RESPONSIVE BREAKPOINTS ==========
  // These values determine when layout should change for different screen sizes
  static const double mobileBreakpoint = 600.0; // Below 600px = mobile
  static const double tabletBreakpoint = 900.0; // 600-900px = tablet

  // ========== LIFECYCLE METHODS ==========

  @override
  void initState() {
    super.initState();
    _pageController = PageController(); // Initialize carousel controller
    _loadData(); // Load all data when page opens
  }

  // Load mentors and videos in parallel for better performance
  Future<void> _loadData() async {
    await Future.wait([_loadMentors(), _loadMentorVideos()]);
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _searchController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========== DATA LOADING METHODS ==========

  /// Loads all mentors from Supabase database
  /// Ordered by rating (highest first)
  Future<void> _loadMentors() async {
    try {
      if (mounted) setState(() => _isLoading = true);

      // Fetch mentors from database, sorted by rating
      final response = await Supabase.instance.client
          .from('mentors')
          .select()
          .order('rating', ascending: false);

      if (mounted) {
        setState(() {
          _mentors = List<Map<String, dynamic>>.from(response);
          _filteredMentors = _mentors; // Initially show all mentors
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle errors gracefully with retry option
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load mentors. Please try again.'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadMentors),
          ),
        );
      }
    }
  }

  /// Loads mentor videos from database
  /// Only fetches mentors who have valid video URLs
  /// Limited to 6 videos for performance
  Future<void> _loadMentorVideos() async {
    try {
      if (mounted) setState(() => _isLoadingVideos = true);

      // Fetch mentors with video URLs (excluding null values)
      final response = await Supabase.instance.client
          .from('mentors')
          .select('id, full_name, avatar, video_url')
          .not('video_url', 'is', null)
          .limit(6); // Limit to 6 for performance

      // Filter out invalid URLs (empty, 'null' string, non-http)
      final videosWithUrl = response.where((mentor) {
        final videoUrl = mentor['video_url']?.toString() ?? '';
        return videoUrl.isNotEmpty &&
            videoUrl.toLowerCase() != 'null' &&
            (videoUrl.startsWith('http://') || videoUrl.startsWith('https://'));
      }).toList();

      if (mounted) {
        setState(() {
          _mentorVideos = List<Map<String, dynamic>>.from(videosWithUrl);
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVideos = false);
      }
    }
  }

  // ========== SEARCH & FILTER METHODS ==========

  /// Filters mentors based on search query
  /// Searches in: name, position, and expertise
  void _filterMentors() {
    if (!mounted) return;

    setState(() {
      _filteredMentors = _mentors.where((mentor) {
        final query = _searchQuery.toLowerCase().trim();
        if (query.isEmpty) return true; // Show all if search is empty

        // Search fields
        final name = mentor['full_name']?.toString().toLowerCase() ?? '';
        final position =
            mentor['current_position']?.toString().toLowerCase() ?? '';
        final expertise =
            (mentor['expertise'] as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase())
                .join(' ') ??
            '';

        // Return true if query matches any field
        return name.contains(query) ||
            position.contains(query) ||
            expertise.contains(query);
      }).toList();
    });
  }

  // ========== UI BUILDING METHODS ==========
  // Banner Section

  /// Builds the promotional hero banner at the top
  /// Shows booking management promotional content
  Widget _buildHeroBanner(bool isMobile) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      constraints: BoxConstraints(
        minHeight: isMobile ? 160.0 : 180.0,
        maxHeight: isMobile ? 220.0 : 240.0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5E9EF5).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: Offset(0, 15),
          ),
        ],
      ),
      child: PageView(
        controller: _pageController,
        children: [
          _buildBannerPage(
            gradient: [Color(0xFFE8C5E8), Color(0xFFE8C5E8)],
            title: 'Manage all your Bookings Here ',
            subtitle:
                'Manage all your Bookings and get Insights on your progress.',
            imagePath: 'assets/element3.png',
            buttonColor: Color(0xFFE673E6),
          ),
        ],
      ),
    );
  }

  /// Builds individual banner page with content
  /// Layout: Text content on left (60%), Image on right (40%)
  Widget _buildBannerPage({
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required String imagePath,
    required Color buttonColor,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < mobileBreakpoint;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
          ),
          child: Row(
            children: [
              // ===== LEFT SIDE: Text Content (60% width) =====
              Expanded(
                flex: isMobile ? 6 : 5,
                child: Stack(
                  children: [
                    // White background layer
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          bottomLeft: Radius.circular(24),
                        ),
                      ),
                    ),
                    // Subtle gradient accent in top-left corner
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
                    // Main text content with responsive sizing
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 16 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Banner title - responsive font size
                          Flexible(
                            child: Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B1B1B),
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: isMobile ? 6 : 8),
                          // Banner subtitle - responsive font size
                          Flexible(
                            child: Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 10 : 12,
                                color: Color(0xFF3B3B3B),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: isMobile ? 10 : 14),
                          // Call-to-action button
                          ElevatedButton(
                            onPressed: () {
                              // TODO: Navigate to bookings page
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 6 : 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                              minimumSize: Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                Icon(
                                  Icons.arrow_forward,
                                  size: isMobile ? 10 : 12,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ===== RIGHT SIDE: Image Section (40% width) =====
              Expanded(
                flex: isMobile ? 4 : 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: gradient[0], // Colored background
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern layer
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomRight: Radius.circular(24),
                          ),
                          child: Image.asset(
                            'assets/static5.png', // Pattern background
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      // Foreground image layer
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: Image.asset(
                          imagePath, // Main promotional image
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            // Show placeholder icon if image fails to load
                            return Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: isMobile ? 50 : 80,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========== VIDEO SECTION ==========

  /// Builds the "Discover Mentors" video section
  /// Shows 2 videos on mobile, 3 on larger screens
  Widget _buildDiscoverMentorsSection(double screenWidth) {
    final isMobile = screenWidth < mobileBreakpoint;
    final videosToShow = isMobile ? 2 : 3; // Responsive video count

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with icon
          Row(
            children: [
              Icon(
                Icons.person_search,
                color: Color(0xFF5E9EF5),
                size: isMobile ? 20 : 24,
              ),
              SizedBox(width: 8),
              Text(
                'Discover Mentors',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2347),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Dynamic content based on loading state
          _isLoadingVideos
              ? _buildVideoLoadingShimmer(videosToShow) // Loading state
              : _mentorVideos.isEmpty
              ? _buildEmptyVideosState() // Empty state
              : _buildVideoGrid(screenWidth, videosToShow), // Videos
        ],
      ),
    );
  }

  /// Loading shimmer for video section
  /// Shows placeholder boxes while videos load
  Widget _buildVideoLoadingShimmer(int count) {
    return SizedBox(
      height: 180,
      child: Row(
        children: List.generate(
          count,
          (index) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: index < count - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Empty state when no mentor videos are available
  Widget _buildEmptyVideosState() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library_outlined, size: 40, color: Colors.grey[400]),
          SizedBox(height: 8),
          Text(
            'No mentor videos available yet',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// Builds horizontal row of video thumbnails
  Widget _buildVideoGrid(double screenWidth, int videosToShow) {
    return Row(
      children: _mentorVideos.take(videosToShow).map((video) {
        final index = _mentorVideos.indexOf(video);
        return Expanded(
          child: Container(
            // Add margin between videos (except last one)
            margin: EdgeInsets.only(right: index < videosToShow - 1 ? 8 : 0),
            child: AutoPlayVideoThumbnail(
              videoUrl: video['video_url']?.toString() ?? '',
              mentorName: video['full_name']?.toString() ?? 'Mentor',
            ),
          ),
        );
      }).toList(),
    );
  }

  // ========== MAIN BUILD METHOD ==========

  /// Main widget tree builder
  /// Creates responsive layout with banner, videos, and mentor grid
  @override
  Widget build(BuildContext context) {
    // Responsive calculations
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isTablet =
        screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;

    // Grid configuration based on screen size
    // Mobile: 2 columns, Tablet: 3 columns, Desktop: 4 columns
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final horizontalPadding = isMobile ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mentor Connect',
          style: GoogleFonts.inter(
            color: Color(0xFF1B2347),
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1B2347)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // ===== MAIN BODY =====
      body: RefreshIndicator(
        onRefresh: _loadData, // Pull-to-refresh functionality
        color: Color(0xFF5E9EF5),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // ===== SECTION 1: Hero Banner =====
            SliverToBoxAdapter(
              child: Column(
                children: [
                  SizedBox(height: 12),
                  _buildHeroBanner(isMobile),
                  SizedBox(height: 12),
                ],
              ),
            ),

            // ===== SECTION 2: Discover Mentors Videos =====            // ===== SECTION 2: Discover Mentors Videos =====
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildDiscoverMentorsSection(screenWidth),
                  SizedBox(height: 12),
                ],
              ),
            ),

            // ===== SECTION 3: Search & Filter Header =====
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section title
                    Row(
                      children: [
                        Text(
                          'Discover More By Category',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2347),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.school,
                          color: Color(0xFF5E9EF5),
                          size: isMobile ? 20 : 24,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Search bar and bookings button
                    _buildSearchAndFilterRow(isMobile),
                    SizedBox(height: 12),

                    // Results counter
                    Text(
                      '${_filteredMentors.length} ${_filteredMentors.length == 1 ? 'Mentor' : 'Mentors'} Found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Color(0xFFFF9800),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            // ===== SECTION 4: Mentor Grid =====
            _buildMentorGrid(crossAxisCount, horizontalPadding, isMobile),
          ],
        ),
      ),
    );
  }

  // ========== SEARCH BAR & FILTER SECTION ==========

  /// Builds search field with bookings button
  Widget _buildSearchAndFilterRow(bool isMobile) {
    return Row(
      children: [
        // Search text field
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              _searchQuery = value;
              _filterMentors(); // Filter results as user types
            },
            decoration: InputDecoration(
              hintText: 'Search mentors, expertise...',
              hintStyle: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600], size: 20),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        // My Bookings Button
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('My Bookings - Coming Soon'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: Icon(Icons.bookmark_outline, size: isMobile ? 16 : 18),
          label: Text(
            isMobile ? 'Bookings' : 'My Bookings',
            style: GoogleFonts.inter(fontSize: isMobile ? 12 : 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF5E9EF5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMentorGrid(
    int crossAxisCount,
    double horizontalPadding,
    bool isMobile,
  ) {
    if (_isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF5E9EF5)),
              SizedBox(height: 16),
              Text(
                'Loading mentors...',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredMentors.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'No mentors available'
                    : 'No mentors found',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              if (_searchQuery.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildMentorCard(_filteredMentors[index], isMobile),
          ),
          childCount: _filteredMentors.length,
        ),
      ),
    );
  }

  Widget _buildMentorCard(Map<String, dynamic> mentor, bool isMobile) {
    final expertise = mentor['expertise'] as List? ?? [];
    final name = mentor['full_name']?.toString() ?? 'Mentor';
    final position = mentor['current_position']?.toString() ?? 'Professional';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MentorDetailPage(mentor: mentor),
        ),
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: isMobile ? 180 : 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  topLeft: Radius.circular(24),
                ),
                child: (mentor['avatar'] != null && mentor['avatar'].toString().isNotEmpty)
                    ? Image.network(
                        mentor['avatar'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[100],
                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: const Icon(Icons.person, size: 40, color: Colors.grey),
                      ),
              ),
            ),
            // Right Side: Info and Actions
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 15 : 17,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text('🇬🇧', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      position,
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 10 : 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Helping with:',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Expertise Chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: expertise.take(2).map((item) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.toString(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _showConnectDialog(mentor),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5367FF),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Connect',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
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
    ),
  );
}

  Widget _buildProfileAvatar(Map<String, dynamic> mentor, bool isMobile) {
    // Keep internal helper to prevent build errors elsewhere, though not used in row design
    return const SizedBox.shrink();
  }

  Widget _buildAvatarFallback(String initial, double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: Text(
        initial,
        style: GoogleFonts.inter(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  void _showConnectDialog(Map<String, dynamic> mentor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MentorDetailPage(mentor: mentor)),
    );
  }
}

// Auto-playing video thumbnail widget
class AutoPlayVideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final String mentorName;

  const AutoPlayVideoThumbnail({
    super.key,
    required this.videoUrl,
    required this.mentorName,
  });

  @override
  State<AutoPlayVideoThumbnail> createState() => _AutoPlayVideoThumbnailState();
}

class _AutoPlayVideoThumbnailState extends State<AutoPlayVideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _showControls = false;
  bool _hasError = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (_isDisposed) return;

    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _controller!.initialize();

      if (_isDisposed || !mounted) {
        _controller?.dispose();
        return;
      }

      _controller!.setLooping(true);
      _controller!.setVolume(0.0);
      await _controller!.play();

      if (mounted && !_isDisposed) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposed) {
        setState(() {
          _hasError = true;
          _isInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller != null && mounted) {
      setState(() {
        _controller!.value.isPlaying
            ? _controller!.pause()
            : _controller!.play();
      });
    }
  }

  void _toggleMute() {
    if (_controller != null && mounted) {
      setState(() {
        _controller!.setVolume(_controller!.value.volume == 0.0 ? 1.0 : 0.0);
      });
    }
  }

  void _onTap() {
    if (!mounted) return;

    setState(() => _showControls = !_showControls);

    if (_showControls) {
      Future.delayed(Duration(seconds: 3), () {
        if (mounted && _showControls) {
          setState(() => _showControls = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 11,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Player or Error/Loading State
            if (_hasError)
              _buildErrorState()
            else if (!_isInitialized)
              _buildLoadingState()
            else
              VideoPlayer(_controller!),

            // Tap detection layer
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                child: Container(color: Colors.transparent),
              ),
            ),

            // Controls overlay
            if (_showControls && _isInitialized && !_hasError)
              _buildControlsOverlay(),

            // Mentor name at bottom
            if (_isInitialized && !_hasError) _buildMentorNameLabel(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text(
              'Video unavailable',
              style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5E9EF5)),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: _controller!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                onTap: _togglePlayPause,
              ),
              SizedBox(width: 16),
              _buildControlButton(
                icon: _controller!.value.volume == 0.0
                    ? Icons.volume_off
                    : Icons.volume_up,
                onTap: _toggleMute,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Color(0xFF5E9EF5), size: 28),
      ),
    );
  }

  Widget _buildMentorNameLabel() {
    return Positioned(
      bottom: 8,
      left: 8,
      right: 8,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          widget.mentorName,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

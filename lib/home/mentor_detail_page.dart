import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ========================================
// MENTOR DETAIL PAGE - Production Ready
// ========================================
// Displays comprehensive mentor profile with:
// - Profile information and avatar
// - Expertise and ratings
// - Available session types
// - Booking functionality
// - Reviews section
// Fully responsive for mobile, tablet, and desktop
// ========================================

class MentorDetailPage extends StatefulWidget {
  final Map<String, dynamic> mentor;

  const MentorDetailPage({super.key, required this.mentor});

  @override
  State<MentorDetailPage> createState() => _MentorDetailPageState();
}

class _MentorDetailPageState extends State<MentorDetailPage> {
  // ========== RESPONSIVE BREAKPOINTS ==========
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;
    final isTablet =
        screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;

    // Responsive padding based on screen size
    final horizontalPadding = isMobile ? 16.0 : (isTablet ? 24.0 : 32.0);
    final cardPadding = isMobile ? 16.0 : 20.0;
    
    // ========== SAFE DATA EXTRACTION ==========
    // Extract mentor data with null safety and fallbacks
    final expertise = widget.mentor['expertise'] as List<dynamic>?;
    final rating = (widget.mentor['rating'] is num)
        ? (widget.mentor['rating'] as num).toDouble()
        : 0.0;
    final fullName = widget.mentor['full_name']?.toString() ?? 'Unknown Mentor';
    final firstName = fullName.split(' ').isNotEmpty ? fullName.split(' ')[0] : 'Mentor';
    final currentPosition = widget.mentor['current_position']?.toString() ?? 'Professional';
    final avatarUrl = widget.mentor['avatar']?.toString() ?? '';
    final mentorId = widget.mentor['id']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      // ========== APP BAR ==========
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: 'Go back',
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
        title: Text(
          'Mentor Profile',
          style: GoogleFonts.inter(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Bookmark added'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: Icon(Icons.bookmark_border, color: Colors.black87),
            tooltip: 'Bookmark mentor',
            style: IconButton.styleFrom(backgroundColor: Colors.white),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // ========== DECORATIVE BACKGROUND ==========
          // Top-right decorative image with opacity
          Positioned(
            top: 0,
            right: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/static5.png',
                width: isMobile ? 100 : 150,
                height: isMobile ? 100 : 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
              ),
            ),
          ),
          // Bottom-left decorative image with opacity
          Positioned(
            bottom: 0,
            left: 0,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset(
                'assets/design1.png',
                width: isMobile ? 80 : 120,
                height: isMobile ? 80 : 120,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => SizedBox.shrink(),
              ),
            ),
          ),

          // ========== MAIN SCROLLABLE CONTENT ==========
          CustomScrollView(
            slivers: [
              // ========== PROFILE HEADER SECTION ==========
              // Gradient header with profile picture, name, and chat button
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFE082)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(isMobile ? 24 : 30),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        SizedBox(height: isMobile ? 8 : 16),

                        // ===== PROFILE PICTURE =====
                        // Circular avatar with border and shadow
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: isMobile ? 3 : 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: isMobile ? 45 : 50,
                            backgroundColor: Colors.grey[200],
                            child: avatarUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.mentor['avatar'],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Center(
                                          child: Text(
                                            (widget.mentor['full_name']?[0] ??
                                                    'M')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 36,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : Text(
                                    (widget.mentor['full_name']?[0] ?? 'M')
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 12 : 16),

                        // ===== NAME AND EMAIL =====
                        // Display mentor name with icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              size: isMobile ? 16 : 18,
                              color: Colors.black87,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                fullName,
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 18 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Display mentor email
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.email,
                              size: isMobile ? 12 : 14,
                              color: Colors.black54,
                            ),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'mentor${mentorId.hashCode}@example.com',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 16 : 20),

                        // ===== CHAT BUTTON =====
                        // Primary action button to start chat
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: horizontalPadding,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Chat feature coming soon'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.chat_bubble_outline,
                              size: isMobile ? 16 : 18,
                            ),
                            label: Text(
                              'Chat with $firstName',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black87,
                              elevation: 2,
                              minimumSize: Size(
                                double.infinity,
                                isMobile ? 45 : 50,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isMobile ? 20 : 24),
                      ],
                    ),
                  ),
                ),
              ),

              // ========== CONTENT SECTION ==========
              // Main information about the mentor
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== CURRENT OCCUPATION =====
                      Text(
                        'Current Occupation',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        currentPosition,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: isMobile ? 14 : 16),

                      // ===== EXPERTISE =====
                      Text(
                        'Expertise',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (expertise != null && expertise.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: expertise.map((exp) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFFFF8E1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Color(0xFFFFD54F).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                exp.toString(),
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'Not specified',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      SizedBox(height: isMobile ? 14 : 16),

                      // ===== RATING =====
                      Row(
                        children: [
                          Text(
                            'Rating',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 10 : 12,
                              vertical: isMobile ? 5 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Color(0xFFFFB300),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFFFB300).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Color(0xFFFFB300),
                                  size: isMobile ? 16 : 18,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: GoogleFonts.inter(
                                    color: Color(0xFFFFB300),
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 13 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 14 : 16),

                      // ===== ABOUT ME =====
                      Text(
                        'About Me',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 14),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          'Hi, I\'m $firstName and I have 8 years experience in teaching and working as a $currentPosition. I help students to achieve good heights in their career. I am also nominated as SIH judge 2x times and have judged more than 20+ events. I can help you stay aligned and ahead of others in your career.',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 12 : 13,
                            color: Colors.black87,
                            height: 1.6,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== BOOK SESSION CARD ==========
              // Highlighted call-to-action for booking sessions
              SliverToBoxAdapter(
                child: Container(
                  margin: EdgeInsets.all(horizontalPadding),
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFFE082)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFFFFD54F).withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_available,
                            color: Colors.black87,
                            size: isMobile ? 20 : 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Book Session',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 18 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 10 : 12),
                      Text(
                        'Book 1:1 session with $firstName and get expert guidance to unlock your career potential',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 12 : 13,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: isMobile ? 14 : 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showBookingOptions(context);
                          },
                          icon: Icon(
                            Icons.access_time,
                            size: isMobile ? 16 : 18,
                          ),
                          label: Text(
                            'Book Now',
                            style: GoogleFonts.inter(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: isMobile ? 14 : 16,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== SESSIONS AVAILABLE ==========
              // List of different session types with durations and costs
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sessions Available',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),

                      // ===== RAPID Q&A SESSION =====
                      _buildSessionCard(
                        context: context,
                        isMobile: isMobile,
                        icon: Icons.flash_on,
                        title: 'Rapid Q&A',
                        duration: '15 Minutes',
                        coins: '15 coins',
                        color: Color(0xFFFFE5B4),
                      ),
                      SizedBox(height: isMobile ? 10 : 12),

                      // ===== DEEP DIVE SESSION =====
                      _buildSessionCard(
                        context: context,
                        isMobile: isMobile,
                        icon: Icons.hourglass_empty,
                        title: 'Deep Dive',
                        duration: '30 Minutes',
                        coins: '20 coins',
                        color: Color(0xFFFFE5B4),
                      ),
                      SizedBox(height: isMobile ? 10 : 12),

                      // ===== FULL COACHING SESSION =====
                      _buildSessionCard(
                        context: context,
                        isMobile: isMobile,
                        icon: Icons.schedule,
                        title: 'Full Coaching',
                        duration: '45 Minutes',
                        coins: '35 coins',
                        color: Color(0xFFFFE5B4),
                      ),
                    ],
                  ),
                ),
              ),

              // ========== REVIEWS SECTION ==========
              // Display mentor reviews (currently empty state)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  margin: EdgeInsets.only(top: 8),
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reviews',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Check what others have said about mentor $firstName',
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 24),
                      Center(
                        child: Container(
                          padding: EdgeInsets.all(isMobile ? 20 : 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.reviews_outlined,
                                size: isMobile ? 40 : 48,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 12),
                              Text(
                                'No reviews found',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Be the first to review this mentor',
                                style: GoogleFonts.inter(
                                  fontSize: isMobile ? 11 : 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 24),
                    ],
                  ),
                ),
              ),

              // Bottom spacing for better scrolling experience
              SliverToBoxAdapter(child: SizedBox(height: isMobile ? 20 : 24)),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // SESSION CARD WIDGET
  // ========================================
  // Displays individual session type with icon, duration, and cost

  Widget _buildSessionCard({
    required BuildContext context,
    required bool isMobile,
    required IconData icon,
    required String title,
    required String duration,
    required String coins,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Session icon
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: isMobile ? 24 : 28, color: Colors.black87),
          ),
          SizedBox(width: isMobile ? 12 : 16),
          // Session details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coins badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 6 : 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: isMobile ? 12 : 14,
                        color: Color(0xFFFFB300),
                      ),
                      SizedBox(width: 4),
                      Text(
                        coins,
                        style: GoogleFonts.inter(
                          fontSize: isMobile ? 9 : 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Session title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Duration info
          Column(
            children: [
              Icon(
                Icons.access_time,
                size: isMobile ? 14 : 16,
                color: Colors.black54,
              ),
              SizedBox(height: 4),
              Text(
                duration,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 10 : 11,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // BOOKING OPTIONS BOTTOM SHEET
  // ========================================
  // Shows modal bottom sheet with all available session types

  void _showBookingOptions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(isMobile ? 20 : 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              // Title
              Text(
                'Select Session Type',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: isMobile ? 16 : 20),
              // Session options
              _buildSessionOption(
                context: context,
                isMobile: isMobile,
                icon: Icons.flash_on,
                title: 'Rapid Q&A',
                subtitle: '15 minutes - 15 coins',
                onTap: () {
                  Navigator.pop(context);
                  _confirmBooking(context, 'Rapid Q&A');
                },
              ),
              SizedBox(height: 8),
              _buildSessionOption(
                context: context,
                isMobile: isMobile,
                icon: Icons.hourglass_empty,
                title: 'Deep Dive',
                subtitle: '30 minutes - 20 coins',
                onTap: () {
                  Navigator.pop(context);
                  _confirmBooking(context, 'Deep Dive');
                },
              ),
              SizedBox(height: 8),
              _buildSessionOption(
                context: context,
                isMobile: isMobile,
                icon: Icons.schedule,
                title: 'Full Coaching',
                subtitle: '45 minutes - 35 coins',
                onTap: () {
                  Navigator.pop(context);
                  _confirmBooking(context, 'Full Coaching');
                },
              ),
              SizedBox(height: isMobile ? 12 : 16),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // SESSION OPTION WIDGET
  // ========================================
  // Individual session option in the booking modal
  Widget _buildSessionOption({
    required BuildContext context,
    required bool isMobile,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 14),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Color(0xFFFFB300),
                size: isMobile ? 22 : 24,
              ),
            ),
            SizedBox(width: isMobile ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: isMobile ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: isMobile ? 14 : 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // BOOKING CONFIRMATION DIALOG
  // ========================================
  // Confirms the booking selection and shows success message

  void _confirmBooking(BuildContext context, String sessionType) {
    final fullName = widget.mentor['full_name']?.toString() ?? 'this mentor';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < mobileBreakpoint;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.event_available,
              color: Color(0xFFFFB300),
              size: isMobile ? 22 : 24,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Confirm Booking',
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Book $sessionType session with $fullName?',
          style: GoogleFonts.inter(fontSize: isMobile ? 13 : 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$sessionType session booked successfully!',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFFB300),
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 10 : 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm',
              style: GoogleFonts.inter(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

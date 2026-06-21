import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MentorAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  final BoxShape shape;
  final double? width;
  final double? height;
  final BoxFit fit;

  const MentorAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24.0,
    this.shape = BoxShape.circle,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  // Premium harmonized gradient list for initials fallback
  static const List<List<Color>> _avatarGradients = [
    [Color(0xFF5E9EF5), Color(0xFF8EC5FC)], // Premium Blue
    [Color(0xFFEC4899), Color(0xFFF472B6)], // Rose / Pink
    [Color(0xFF8B5CF6), Color(0xFFA78BFA)], // Violet
    [Color(0xFF10B981), Color(0xFF34D399)], // Emerald / Mint
    [Color(0xFFF59E0B), Color(0xFFFBBF24)], // Amber / Gold
    [Color(0xFFEF4444), Color(0xFFF87171)], // Coral / Red
    [Color(0xFF06B6D4), Color(0xFF22D3EE)], // Cyan
    [Color(0xFF6366F1), Color(0xFF818CF8)], // Indigo
  ];

  List<Color> _getGradientForName(String name) {
    if (name.isEmpty) return _avatarGradients[0];
    final int index = name.hashCode.abs() % _avatarGradients.length;
    return _avatarGradients[index];
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'M';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final double actualWidth = width ?? radius * 2;
    final double actualHeight = height ?? radius * 2;
    final String cleanUrl = avatarUrl?.toString().trim() ?? '';

    // Initials fallback widget
    Widget buildFallback() {
      final colors = _getGradientForName(name);
      return Container(
        width: actualWidth,
        height: actualHeight,
        decoration: BoxDecoration(
          shape: shape,
          borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(16) : null,
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          _getInitials(name),
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (actualWidth * 0.38).clamp(10.0, 36.0),
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    if (cleanUrl.isEmpty || cleanUrl.toLowerCase() == 'null') {
      return buildFallback();
    }

    final bool isAsset = cleanUrl.startsWith('assets/');

    final Widget imageWidget = isAsset
        ? Image.asset(
            cleanUrl,
            width: actualWidth,
            height: actualHeight,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('⚠️ MentorAvatar error loading asset: $cleanUrl');
              return buildFallback();
            },
          )
        : Image.network(
            cleanUrl,
            width: actualWidth,
            height: actualHeight,
            fit: fit,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('⚠️ MentorAvatar error loading network image: $cleanUrl');
              return buildFallback();
            },
          );

    return Container(
      width: actualWidth,
      height: actualHeight,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(16) : null,
      ),
      child: shape == BoxShape.circle
          ? ClipOval(
              clipper: const _CircleClipper(),
              child: imageWidget,
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageWidget,
            ),
    );
  }
}

class _CircleClipper extends CustomClipper<Rect> {
  const _CircleClipper();

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width, size.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => false;
}

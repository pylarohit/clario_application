import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumLoadingIndicator extends StatefulWidget {
  final String? message;
  final double height;

  const PremiumLoadingIndicator({
    super.key,
    this.message,
    this.height = 120.0,
  });

  @override
  State<PremiumLoadingIndicator> createState() => _PremiumLoadingIndicatorState();
}

class _PremiumLoadingIndicatorState extends State<PremiumLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;
  int _phraseIndex = 0;

  final List<String> _loadingPhrases = [
    'Curating the best options for you...',
    'Connecting with top industry sources...',
    'Analyzing your preferences...',
    'Polishing the details...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Rotate encouraging/interactive phrases every 2.5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _loadingPhrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Three bouncing glowing circles
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  // Phase delay for wave effect
                  final delay = index * 0.25;
                  // Calculate sine wave offset (-1.0 to 1.0)
                  final value = math.sin((_controller.value * 2 * math.pi) - delay);
                  // Translate to bounce offset (0 to 12 pixels up)
                  final bounce = (value + 1) * 6;
                  // Dynamic opacity and scale
                  final opacity = 0.5 + (value + 1) * 0.25; // 0.5 to 1.0
                  final scale = 0.85 + (value + 1) * 0.075; // 0.85 to 1.0

                  return Transform.translate(
                    offset: Offset(0, -bounce),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF5E9EF5).withOpacity(opacity),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF5E9EF5).withOpacity(0.3 * opacity),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: Offset(0, bounce / 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 20),
          // Fade-switching interactive message
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: Text(
              widget.message ?? _loadingPhrases[_phraseIndex],
              key: ValueKey<String>(widget.message ?? _loadingPhrases[_phraseIndex]),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SKELETON PULSE SHIMMER LOADER
// -------------------------------------------------------------
class PulseSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const PulseSkeleton({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 12.0,
  });

  @override
  State<PulseSkeleton> createState() => _PulseSkeletonState();
}

class _PulseSkeletonState extends State<PulseSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

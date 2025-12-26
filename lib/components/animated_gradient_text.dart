import 'package:flutter/material.dart';

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final List<Color> colors;

  const AnimatedGradientText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(seconds: 3),
    this.colors = const [Colors.white70, Colors.white, Colors.white70],
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: widget.colors[0],
      end: widget.colors[1],
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              _colorAnimation.value ?? widget.colors[0],
              widget.colors[1],
              _colorAnimation.value ?? widget.colors[0],
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            widget.text,
            textAlign: TextAlign.center,
            style: widget.style?.copyWith(color: Colors.white) ??
                  const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}
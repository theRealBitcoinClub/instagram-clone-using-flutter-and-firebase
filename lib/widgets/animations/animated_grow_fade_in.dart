import 'package:flutter/material.dart';

class AnimatedGrowFadeIn extends StatefulWidget {
  final Widget child;
  final bool show; // Controls visibility and triggers the animation
  final Duration duration;
  final Duration delay;
  final Curve sizeCurve;
  final Curve fadeCurve;
  final AlignmentGeometry alignment; // For AnimatedSize, typically Alignment.topCenter for growing downwards

  const AnimatedGrowFadeIn({
    Key? key,
    required this.child,
    required this.show,
    this.duration = const Duration(milliseconds: 300),
    this.delay = Duration.zero,
    this.sizeCurve = Curves.fastOutSlowIn, // A common curve for size changes
    this.fadeCurve = Curves.easeIn,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  State<AnimatedGrowFadeIn> createState() => _AnimatedGrowFadeInState();
}

class _AnimatedGrowFadeInState extends State<AnimatedGrowFadeIn> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: widget.duration, value: widget.show ? 1.0 : 0.0);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: widget.fadeCurve));
  }

  @override
  void didUpdateWidget(AnimatedGrowFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      // Apply delay only when transitioning from hidden to shown
      if (widget.show) {
        if (widget.delay == Duration.zero) {
          _animationController.forward();
        } else {
          Future.delayed(widget.delay, () {
            if (mounted) {
              _animationController.forward();
            }
          });
        }
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedSize(
        duration: widget.duration,
        curve: widget.sizeCurve,
        alignment: widget.alignment,
        child: widget.show ? widget.child : Container(width: double.infinity),
      ),
    );
  }
}

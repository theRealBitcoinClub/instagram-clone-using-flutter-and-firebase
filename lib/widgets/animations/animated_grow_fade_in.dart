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
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      // Initial value depends on initial 'show' state to prevent flicker
      value: widget.show ? 1.0 : 0.0,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: widget.fadeCurve));

    // No need to explicitly start animation here, `didUpdateWidget` will handle it
    // based on the 'show' property. If initially true, controller is already at 1.0.
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
    // We use a SizedBox with height 0 when not shown to make AnimatedSize work correctly
    // from a zero-size state.
    // The FadeTransition wraps the AnimatedSize to control opacity.
    // AnimatedSize needs a child that has intrinsic dimensions.

    // The core idea:
    // When widget.show is false, we want the "effective" child of AnimatedSize to be Size.zero height
    // When widget.show is true, we want it to be the actual widget.child

    return FadeTransition(
      opacity: _fadeAnimation,
      child: AnimatedSize(
        duration: widget.duration,
        curve: widget.sizeCurve,
        alignment: widget.alignment,
        // vsync is needed for AnimatedSize if its child changes size frequently,
        // but here the TickerProvider is mainly for the FadeTransition.
        // For AnimatedSize, the duration and curve are primary.
        // We ensure a TickerProvider is available via SingleTickerProviderStateMixin.
        // Child is the actual content when 'show' is true, or an empty container when false
        // to animate from/to zero height.
        child: widget.show
            ? widget
                  .child // Show the actual child when visible
            // When not shown, we want AnimatedSize to shrink to 0 height.
            // A simple Container with no specific height might not achieve this as smoothly.
            // Using a KeyedSubtree or a more explicit zero-sized widget can help.
            // Or ensure the child itself handles its "empty" state appropriately.
            // Let's ensure the child of AnimatedSize is *always present* but its content changes.
            // The simplest is to ensure the widget.child itself might become empty or have zero height.
            // However, for a generic wrapper, we explicitly provide a zero-height widget when hidden.
            : Container(width: double.infinity), // Occupy width, but zero height for AnimatedSize to shrink
      ),
    );
  }
}

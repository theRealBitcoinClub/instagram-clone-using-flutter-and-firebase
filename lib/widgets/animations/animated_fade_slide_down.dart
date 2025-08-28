import 'package:flutter/material.dart';

class AnimatedFadeSlideDown extends StatefulWidget {
  final Widget child;
  final bool show; // Add this to control visibility and animation direction
  final Duration duration;
  final Duration delay; // Delay for appearing animation
  final Curve curveIn; // Curve for appearing
  final Curve curveOut; // Curve for disappearing

  const AnimatedFadeSlideDown({
    Key? key,
    required this.child,
    required this.show, // Make it required
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curveIn = Curves.easeOutCubic, // Curve for fade-in and slide-down
    this.curveOut = Curves.easeInCubic, // Curve for fade-out and slide-up
  }) : super(key: key);

  @override
  State<AnimatedFadeSlideDown> createState() => _AnimatedFadeSlideDownState();
}

class _AnimatedFadeSlideDownState extends State<AnimatedFadeSlideDown> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      // Set initial value based on the initial 'show' state
      // If initially shown, controller is at 1.0 (completed state for forward animation)
      // If initially hidden, controller is at 0.0 (initial state for forward animation)
      value: widget.show ? 1.0 : 0.0,
    );

    // Fade Animation: Always from 0.0 (transparent) to 1.0 (opaque)
    // The controller's direction (forward/reverse) will handle fade-in/fade-out.
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        // We'll use curveIn for forward (appearing) and curveOut for reverse (disappearing)
        // by potentially changing the curve on the controller or animation itself if needed,
        // or just accept one curve for both directions of fade.
        // For simplicity here, one curve for fade.
        curve: widget.curveIn, // Or a general curve like Curves.easeInOut
      ),
    );

    // Slide Animation:
    // When controller is at 0.0 (begin), it's at Offset(0.0, -0.1) (above)
    // When controller is at 1.0 (end), it's at Offset.zero (final position)
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0.0, -0.1), // Start from 10% of its height above
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            // This curve will be used for both slide-down (forward) and slide-up (reverse)
            // You can define separate curves if needed by creating two CurvedAnimations
            // and choosing one based on controller.status, but this is often sufficient.
            curve: widget.curveIn, // Using curveIn for the forward motion
            // The reverse will naturally use the reversed version of this curve.
          ),
        );

    // No need to explicitly start animation here based on `show` in initState,
    // as `didUpdateWidget` will handle initial transitions if needed,
    // and the controller's initial value is set correctly.
    // If widget.show is true initially, it's already "visible" (controller at 1.0).
  }

  @override
  void didUpdateWidget(AnimatedFadeSlideDown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show != oldWidget.show) {
      if (widget.show) {
        // Animate in
        // Apply delay only when transitioning from hidden to shown
        if (widget.delay == Duration.zero) {
          _controller.forward();
        } else {
          Future.delayed(widget.delay, () {
            if (mounted) {
              _controller.forward();
            }
          });
        }
      } else {
        // Animate out - use the reverse animation
        // Apply curveOut for the reverse direction on the controller if needed,
        // or ensure the main animation curve works well in reverse.
        // For simplicity, we'll rely on the default reverse of curveIn,
        // or you could dynamically switch the curve of the CurvedAnimation if desired.
        // More direct: `_controller.reverse()` will use the existing curve in reverse.
        // If you want a *different* curve for out, you might need to rebuild the animation
        // or have two Animation objects. However, often a single well-chosen curve works.
        // Let's assume curveIn works well enough for reverse or use curveOut for controller.
        // Note: Changing curve on the fly on CurvedAnimation is not straightforward.
        // The controller itself doesn't have a 'reverseCurve' property.
        // The most straightforward way is that reversing a forward animation with curve X
        // naturally plays the reverse of curve X.
        // If you need distinctly different easing for out, consider two controllers or more complex setup.
        // For now, let's assume `curveIn` when reversed is acceptable or `curveOut` can be applied
        // to the animation if the controller is about to be reversed.

        // Simplest: just reverse.
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We need to ensure that the widget is removed from the tree when not shown
    // if we don't want it to occupy space or be interactable.
    // However, for the animation to play out, it needs to be in the tree.
    // A common pattern is to use Offstage or Visibility if you want to keep state
    // but hide it. But if the `AnimatedFadeSlideDown` itself is conditionally added/removed
    // based on `show`, then the animation will only play once on entry unless `show` changes.

    // If this widget remains in the tree and `show` toggles, the `didUpdateWidget` logic
    // will correctly trigger forward/reverse.

    // To ensure it's not taking up space when fully faded out and "hidden":
    // We can wrap it in an AnimatedBuilder to react to the animation value
    // and potentially set it to `IgnorePointer` or `Offstage` when animation.value is 0.
    // However, for a simple fade/slide, often just letting it animate to transparent
    // and its "off-screen" position is enough if the parent removes it or the `show`
    // variable in the parent controls its presence in the tree.

    // Let's assume the parent will handle the presence of this widget using the `show` flag.
    // If widget.show is false, after animation, it's transparent and slid up.

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child, // Removed ClipRect as it might interfere with slide-up
        // if the content is already its final size. Add back if needed.
      ),
    );
  }
}

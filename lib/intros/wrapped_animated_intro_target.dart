// wrapped_animated_intro_target.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'intro_enums.dart';
import 'intro_state_notifier.dart';

class WrappedAnimatedIntroTarget extends ConsumerStatefulWidget {
  final Widget child;
  final IntroType introType;
  final IntroStep introStep;
  final VoidCallback? onTap;
  final Duration animationDuration;
  final double animationScale;
  final bool? doNotAnimate;

  const WrappedAnimatedIntroTarget({
    Key? key,
    required this.child,
    required this.introType,
    required this.introStep,
    this.doNotAnimate,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.animationScale = 1.1,
  }) : super(key: key);

  @override
  ConsumerState<WrappedAnimatedIntroTarget> createState() => _WrappedAnimatedIntroTargetState();
}

class _WrappedAnimatedIntroTargetState extends ConsumerState<WrappedAnimatedIntroTarget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: widget.animationDuration, vsync: this);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.animationScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.6).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _startAnimationIfNeeded();
  }

  void _startAnimationIfNeeded() {
    final introState = ref.read(introStateNotifierProvider)[widget.introType];
    if (_shouldAnimate(introState)) {
      _controller.repeat(reverse: true);
    }
  }

  bool _shouldAnimate(IntroState? introState) {
    if (introState == null || introState.isCompleted) return false;
    return introState.currentStep.id == widget.introStep.id && !introState.isStepTriggered(widget.introStep);
  }

  void _handleTap() {
    // Always trigger the intro action first
    ref.read(introStateNotifierProvider.notifier).triggerIntroAction(widget.introType, widget.introStep, context);

    // Then execute the custom onTap callback if provided
    widget.onTap?.call();
  }

  @override
  void didUpdateWidget(WrappedAnimatedIntroTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startAnimationIfNeeded();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final introState = ref.watch(introStateNotifierProvider)[widget.introType];
        final shouldAnimate = widget.doNotAnimate ?? _shouldAnimate(introState);

        if (shouldAnimate && !_controller.isAnimating) {
          _controller.repeat(reverse: true);
        } else if (!shouldAnimate && _controller.isAnimating) {
          _controller.stop();
          _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
        }

        final theme = Theme.of(context);
        final Color backgroundColor = shouldAnimate ? theme.colorScheme.onSurface : Colors.transparent;
        final Color contentColor = shouldAnimate ? theme.colorScheme.surface : Colors.transparent;

        Widget animatedContent = AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: shouldAnimate ? _scaleAnimation.value : 1.0,
              child: Opacity(
                opacity: shouldAnimate ? _opacityAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: _getChildBorderRadius(),
                    boxShadow: shouldAnimate
                        ? [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.4), blurRadius: 10, spreadRadius: 2)]
                        : null,
                  ),
                  child: shouldAnimate
                      ? ColorFiltered(colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn), child: widget.child)
                      : widget.child,
                ),
              ),
            );
          },
        );

        return Material(
          color: Colors.transparent,
          type: MaterialType.transparency,
          child: InkWell(
            onTap: _handleTap,
            borderRadius: _getChildBorderRadius(),
            splashColor: theme.splashColor,
            highlightColor: theme.highlightColor,
            child: animatedContent,
          ),
        );
        // Always wrap with GestureDetector to handle the intro action
        return GestureDetector(onTap: _handleTap, behavior: HitTestBehavior.opaque, child: animatedContent);
      },
    );
  }

  BorderRadius _getChildBorderRadius() {
    // Simple logic for common widget types
    if (widget.child is Icon || widget.child is IconButton) {
      return BorderRadius.circular(50);
    }
    return BorderRadius.circular(8);
  }
}

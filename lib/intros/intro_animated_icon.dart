// intro_animated_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'intro_enums.dart';
import 'intro_state_notifier.dart';

class IntroAnimatedIcon extends ConsumerStatefulWidget {
  final IconData icon;
  final double size;
  final IntroType introType;
  final IntroStep introStep;
  final VoidCallback? onTap;
  final color;
  final bool isIconButton; // Whether to wrap in IconButton
  final EdgeInsetsGeometry padding;

  const IntroAnimatedIcon({
    Key? key,
    required this.icon,
    required this.introType,
    required this.introStep,
    this.color,
    this.size = 24.0,
    this.onTap,
    this.isIconButton = false,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  ConsumerState<IntroAnimatedIcon> createState() => _IntroAnimatedIconState();
}

class _IntroAnimatedIconState extends ConsumerState<IntroAnimatedIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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

    // Only animate if this is the current step AND it hasn't been triggered yet
    return introState.currentStep.id == widget.introStep.id && !introState.isStepTriggered(widget.introStep);
  }

  @override
  void didUpdateWidget(IntroAnimatedIcon oldWidget) {
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
        final shouldAnimate = _shouldAnimate(introState);

        // Start or stop animation based on current state
        if (shouldAnimate && !_controller.isAnimating) {
          _controller.repeat(reverse: true);
        } else if (!shouldAnimate && _controller.isAnimating) {
          _controller.stop();
          _controller.animateTo(0.0, duration: const Duration(milliseconds: 300));
        }

        final theme = Theme.of(context);
        final Color backgroundColor = shouldAnimate ? theme.colorScheme.onSurface : Colors.transparent;
        final Color iconColor = shouldAnimate ? theme.colorScheme.surface : widget.color ?? theme.colorScheme.onPrimary;

        Widget iconWidget = AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: shouldAnimate ? _scaleAnimation.value : 1.0,
              child: Opacity(opacity: shouldAnimate ? _opacityAnimation.value : 1.0, child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              boxShadow: shouldAnimate
                  ? [BoxShadow(color: theme.colorScheme.onSurface.withOpacity(0.4), blurRadius: 10, spreadRadius: 3)]
                  : null,
            ),
            padding: widget.padding,
            child: Icon(widget.icon, color: iconColor, size: widget.size),
          ),
        );

        // Wrap with GestureDetector if onTap is provided
        if (widget.onTap != null) {
          iconWidget = GestureDetector(onTap: widget.onTap, child: iconWidget);
        }

        // Wrap with IconButton if requested
        if (widget.isIconButton) {
          return IconButton(onPressed: widget.onTap, icon: iconWidget, iconSize: widget.size + widget.padding.vertical);
        }

        return iconWidget;
      },
    );
  }
}

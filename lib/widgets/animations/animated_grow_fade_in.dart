import 'package:flutter/material.dart';

class AnimGrowFade extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration growDuration;
  final Duration fadeDuration;
  final Duration delay;
  final Curve growCurve;
  final Curve fadeCurve;
  final AlignmentGeometry alignment;

  const AnimGrowFade({
    Key? key,
    required this.child,
    required this.show,
    this.growDuration = const Duration(milliseconds: 400),
    this.fadeDuration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 10),
    this.growCurve = Curves.fastOutSlowIn,
    this.fadeCurve = Curves.easeIn,
    this.alignment = Alignment.topCenter,
  }) : super(key: key);

  @override
  State<AnimGrowFade> createState() => _AnimGrowFadeState();
}

class _AnimGrowFadeState extends State<AnimGrowFade> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _hasAnimatedIn = false;
  bool _shouldShowContent = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(vsync: this, duration: widget.fadeDuration);

    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: widget.fadeCurve);

    if (widget.show) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    if (_hasAnimatedIn) return;

    void startFade() {
      setState(() {
        _shouldShowContent = true;
      });

      Future.delayed(widget.fadeDuration, () {
        if (mounted) {
          _fadeController.forward();
          _hasAnimatedIn = true;
        }
      });
    }

    if (widget.delay == Duration.zero) {
      startFade();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted && widget.show) {
          startFade();
        }
      });
    }
  }

  @override
  void didUpdateWidget(AnimGrowFade oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.show != oldWidget.show) {
      if (widget.show) {
        _startAnimation();
      } else {
        _fadeController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _shouldShowContent = false;
              _hasAnimatedIn = false;
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: widget.growDuration,
      curve: widget.growCurve,
      alignment: widget.alignment,
      child: _shouldShowContent ? FadeTransition(opacity: _fadeAnimation, child: widget.child) : const SizedBox.shrink(),
    );
  }
}

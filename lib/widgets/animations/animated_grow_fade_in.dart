import 'package:flutter/material.dart';

class AnimGrowFade extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: growDuration + fadeDuration,
      switchInCurve: Curves.linear,
      switchOutCurve: Curves.linear,
      transitionBuilder: (Widget child, Animation<double> animation) {
        final totalDuration = growDuration + fadeDuration;
        final growEndPoint = growDuration.inMilliseconds / totalDuration.inMilliseconds;
        final fadeStartPoint = growEndPoint * 0.3;

        final growAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(0.0, growEndPoint, curve: growCurve),
        );

        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Interval(fadeStartPoint, 1.0, curve: fadeCurve),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: SizeTransition(sizeFactor: growAnimation, axisAlignment: _getAxisAlignment(alignment), child: child),
        );
      },
      child: show ? child : const SizedBox.shrink(),
    );
  }

  double _getAxisAlignment(AlignmentGeometry alignment) {
    final resolvedAlignment = alignment.resolve(TextDirection.ltr);
    switch (resolvedAlignment.x) {
      case -1.0:
        return -1.0;
      case 1.0:
        return 1.0;
      default:
        return 0.0;
    }
  }
}

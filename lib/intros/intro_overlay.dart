// intro_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/utils/snackbar.dart';

import 'intro_enums.dart';
import 'intro_state_notifier.dart';

class IntroOverlay extends ConsumerStatefulWidget {
  final IntroType introType;
  final VoidCallback onComplete;

  const IntroOverlay({Key? key, required this.introType, required this.onComplete}) : super(key: key);

  @override
  ConsumerState<IntroOverlay> createState() => _IntroOverlayState();
}

class _IntroOverlayState extends ConsumerState<IntroOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    final notifier = ref.read(introStateNotifierProvider.notifier);
    final currentState = ref.read(introStateNotifierProvider)[widget.introType];

    if (currentState == null || currentState.isCompleted) {
      widget.onComplete();
      return;
    }

    if (currentState.isStepTriggered(currentState.currentStep)) {
      // Move to next step
      notifier.manuallyAdvanceStep(widget.introType, context);
    } else {
      // Show hint that user needs to perform the action
      showSnackBar("Tap the suggested action to continue!", type: SnackbarType.info);
      return;
    }

    // Check if intro completed after advancing
    final updatedState = ref.read(introStateNotifierProvider)[widget.introType];
    if (updatedState?.isCompleted == true) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final introState = ref.watch(introStateNotifierProvider)[widget.introType];

    if (introState == null || introState.isCompleted) {
      return const SizedBox.shrink();
    }

    final content = introState.currentStep.content;
    final displayText = introState.isStepTriggered(introState.currentStep) ? content.triggeredText : content.initText;

    return GestureDetector(
      onTap: _nextStep,
      child: Scaffold(
        backgroundColor: Colors.black.withAlpha(222),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) {
              return Opacity(opacity: _opacityAnimation.value, child: child);
            },
            child: _buildStepContent(content, introState, displayText),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(IntroContent content, IntroState introState, String displayText) {
    final screenSize = MediaQuery.of(context).size;
    final absolutePosition = content.target.getAbsolutePosition(screenSize);
    final steps = widget.introType.steps.toList();
    final currentIndex = steps.indexOf(introState.currentStep);

    return Stack(
      children: [
        // _buildHighlight(absolutePosition, content.target),
        _buildTextContent(displayText, currentIndex, steps.length),
        _buildFingerPointer(absolutePosition, content.target),
      ],
    );
  }

  // Widget _buildHighlight(Offset position, IntroTarget target) {
  //   return Stack(
  //     children: [
  //       Container(color: Colors.black.withOpacity(0.7)),
  //       Positioned(
  //         left: position.dx - target.width / 2,
  //         top: position.dy - target.height / 2,
  //         child: Container(
  //           width: target.width,
  //           height: target.height,
  //           decoration: BoxDecoration(
  //             color: Colors.transparent,
  //             shape: BoxShape.circle,
  //             boxShadow: [BoxShadow(color: Colors.white.withOpacity(0.2), spreadRadius: 4, blurRadius: 10)],
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildTextContent(String displayText, int currentIndex, int totalSteps) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            Text(
              displayText,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Text(
              "Touch where the arrow indicates to continue",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerPointer(Offset position, IntroTarget target) {
    return Positioned(
      left: position.dx - 30,
      top: position.dy - 30,
      child: Transform.rotate(
        angle: target.rotation,
        child: const Icon(Icons.arrow_circle_up_sharp, size: 90, color: Colors.white),
      ),
    );
  }
}

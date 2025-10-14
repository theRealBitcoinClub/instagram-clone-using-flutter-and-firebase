// intro_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../provider/translation_service.dart';
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

    // Start pre-translation for NEXT steps only after initial build
    context.afterBuild(refreshUI: false, () {
      Future.delayed(Duration(seconds: 3), () {
        _preTranslateNextSteps();
      });
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Pre-translate only the NEXT steps (not current step)
  Future<void> _preTranslateNextSteps() async {
    final introState = ref.read(introStateNotifierProvider)[widget.introType];
    if (introState == null) return;

    final steps = widget.introType.steps.toList();
    final currentIndex = steps.indexOf(introState.currentStep);

    // Pre-translate only future steps
    for (int i = currentIndex + 1; i < steps.length; i++) {
      final step = steps[i];
      await ref.read(autoTranslationTextProvider(step.content.initText).future);
      await ref.read(autoTranslationTextProvider(step.content.triggeredText).future);
    }
  }

  void _nextStep() {
    final notifier = ref.read(introStateNotifierProvider.notifier);
    final currentState = ref.read(introStateNotifierProvider)[widget.introType];

    if (currentState == null || currentState.isCompleted) {
      widget.onComplete();
      return;
    }

    if (currentState.isStepTriggered(currentState.currentStep)) {
      notifier.manuallyAdvanceStep(widget.introType, context);
    } else {
      ref.read(snackbarServiceProvider).showTranslatedSnackBar("Tap the suggested action to continue!", type: SnackbarType.info);
      return;
    }

    final updatedState = ref.read(introStateNotifierProvider)[widget.introType];
    if (updatedState?.isCompleted == true) {
      widget.onComplete();
    }
  }

  void _skipIntro() {
    final notifier = ref.read(introStateNotifierProvider.notifier);
    notifier.skipIntro(widget.introType);
    widget.onComplete();
    ref.read(snackbarServiceProvider).showTranslatedSnackBar("Intro skipped", type: SnackbarType.info);
  }

  @override
  Widget build(BuildContext context) {
    final introState = ref.watch(introStateNotifierProvider)[widget.introType];

    if (introState == null || introState.isCompleted) {
      return const SizedBox.shrink();
    }

    final content = introState.currentStep.content;
    bool stepTriggered = introState.isStepTriggered(introState.currentStep);
    final displayText = stepTriggered ? content.triggeredText : content.initText;

    return GestureDetector(
      onTap: _nextStep,
      child: Scaffold(
        backgroundColor: Colors.black.withAlpha(222),
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) => Opacity(opacity: _opacityAnimation.value, child: child),
            child: _buildStepContent(introState, displayText, stepTriggered),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent(IntroState introState, String displayText, bool stepTriggered) {
    final screenSize = MediaQuery.of(context).size;
    final content = introState.currentStep.content;
    final absolutePosition = content.target.getAbsolutePosition(screenSize);
    final steps = widget.introType.steps.toList();
    final currentIndex = steps.indexOf(introState.currentStep);

    return Stack(
      children: [
        _buildTextContent(displayText, currentIndex, steps.length),
        if (!stepTriggered) _buildFingerPointer(absolutePosition, content.target, stepTriggered),
        _buildSkipButton(),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 200,
      child: Center(
        child: _AnimatedTranslationText(
          text: "Skip Intro",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.1),
          child: (text) => OutlinedButton(
            onPressed: _skipIntro,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white, width: 2),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.black.withOpacity(0.5),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(String displayText, int currentIndex, int totalSteps) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 300,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            // Animated Display Text
            _AnimatedTranslationText(
              text: displayText,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Step Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalSteps,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: currentIndex == index ? Colors.white : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Animated Subline
            _AnimatedTranslationText(
              text: "Touch where the arrow indicates to continue",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerPointer(Offset position, IntroTarget target, hasTriggered) {
    return Positioned(
      left: position.dx - 30,
      top: position.dy - 30,
      child: Transform.rotate(
        angle: target.rotation,
        child: const Icon(Icons.arrow_upward_rounded, size: 72, color: Colors.white),
      ),
    );
  }
}

// Reusable animated text widget for smooth translations
class _AnimatedTranslationText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Widget Function(String text)? child;

  const _AnimatedTranslationText({required this.text, this.style, this.textAlign, this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final translatedText = ref.watch(autoTranslationTextProvider(text));

    return translatedText.when(
      data: (translated) => _AnimatedTextSwitcher(text: translated, style: style, textAlign: textAlign, child: child),
      loading: () => _AnimatedTextSwitcher(text: text, style: style, textAlign: textAlign, child: child),
      error: (error, stack) => _AnimatedTextSwitcher(text: text, style: style, textAlign: textAlign, child: child),
    );
  }
}

// Handles the actual animation between text changes
class _AnimatedTextSwitcher extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Widget Function(String text)? child;

  const _AnimatedTextSwitcher({required this.text, this.style, this.textAlign, this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Scale out + fade out then scale in + fade in
        final scaleTween = Tween<double>(begin: 0.8, end: 1.0);
        final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

        return ScaleTransition(
          scale: scaleTween.animate(
            CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
            ),
          ),
          child: FadeTransition(
            opacity: fadeTween.animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
              ),
            ),
            child: child,
          ),
        );
      },
      child: child != null
          ? child!(text)
          : Text(
              key: ValueKey(text), // Important: triggers animation when text changes
              text,
              style: style,
              textAlign: textAlign,
            ),
    );
  }
}

// intro_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/provider/translation_service.dart';
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
  String _subline = "Touch where the arrow indicates to continue";
  String _actionText = "Tap the suggested action to continue!";
  String _skipText = "Skip Intro";

  // Add this method to pre-translate all step texts
  Future<void> _preTranslateStepTexts() async {
    final steps = widget.introType.steps;
    for (final step in steps) {
      // Pre-translate both initText and triggeredText
      await ref.read(autoTranslationTextProvider(step.content.initText).future);
      await ref.read(autoTranslationTextProvider(step.content.triggeredText).future);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _loadTranslations();
    context.afterLayout(refreshUI: false, () {
      Future.delayed(Duration(milliseconds: 3000), () {
        _preTranslateStepTexts();
      });
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadTranslations() async {
    await _getTranslatedSubline();
    await _getTranslatedActionText();
    await _getTranslatedSkipText();
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
      ref.read(snackbarServiceProvider).showTranslatedSnackBar(_actionText, type: SnackbarType.info);
      return;
    }

    // Check if intro completed after advancing
    final updatedState = ref.read(introStateNotifierProvider)[widget.introType];
    if (updatedState?.isCompleted == true) {
      widget.onComplete();
    }
  }

  void _skipIntro() {
    final notifier = ref.read(introStateNotifierProvider.notifier);
    notifier.skipIntro(widget.introType);
    widget.onComplete();

    // Show confirmation message
    ref.read(snackbarServiceProvider).showTranslatedSnackBar("Intro skipped", type: SnackbarType.info);
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
        _buildTextContent(displayText, currentIndex, steps.length),
        _buildFingerPointer(absolutePosition, content.target),
        _buildSkipButton(), // Add skip button
      ],
    );
  }

  Widget _buildSkipButton() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 200, // Position above the text content
      child: Consumer(
        builder: (context, ref, child) {
          final translatedSkipText = ref.watch(autoTranslationTextProvider(_skipText));
          return translatedSkipText.when(
            data: (translation) => _buildSkipButtonContent(translation),
            loading: () => _buildSkipButtonContent(_skipText),
            error: (error, stack) => _buildSkipButtonContent(_skipText),
          );
        },
      ),
    );
  }

  Widget _buildSkipButtonContent(String buttonText) {
    return Center(
      child: OutlinedButton(
        onPressed: _skipIntro,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black.withOpacity(0.5),
        ),
        child: Text(buttonText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1.1)),
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
            // Translated Display Text
            Consumer(
              builder: (context, ref, child) {
                final translatedDisplayText = ref.watch(autoTranslationTextProvider(displayText));
                return translatedDisplayText.when(
                  data: (translation) => Text(
                    translation,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  loading: () => LinearProgressIndicator(),
                  error: (error, stack) => Text(
                    displayText,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Step Indicators
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
            // Translated Subline
            Consumer(
              builder: (context, ref, child) {
                final translatedSubline = ref.watch(autoTranslationTextProvider(_subline));
                return translatedSubline.when(
                  data: (translation) => Text(
                    translation,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                  loading: () => LinearProgressIndicator(),
                  error: (error, stack) => Text(
                    _subline,
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                );
              },
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

  Future<void> _getTranslatedSubline() async {
    final translation = await ref.read(autoTranslationTextProvider(_subline).future);
    if (mounted) {
      setState(() {
        _subline = translation;
      });
    }
  }

  Future<void> _getTranslatedActionText() async {
    final translation = await ref.read(autoTranslationTextProvider(_actionText).future);
    if (mounted) {
      setState(() {
        _actionText = translation;
      });
    }
  }

  Future<void> _getTranslatedSkipText() async {
    final translation = await ref.read(autoTranslationTextProvider(_skipText).future);
    if (mounted) {
      setState(() {
        _skipText = translation;
      });
    }
  }
}

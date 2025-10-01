// translation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/provider/translation_service.dart';

import '../../memo/model/memo_model_post.dart';
import '../animations/animated_grow_fade_in.dart';
import 'language_selector_widget.dart';

class TranslationWidget extends ConsumerStatefulWidget {
  final MemoModelPost post;
  final AnimationController translationSectionController;
  final Animation<double> translationSectionAnimation;
  final AnimationController textFadeController;
  final Animation<double> textFadeAnimation;
  final String originalText;

  const TranslationWidget({
    Key? key,
    required this.post,
    required this.originalText,
    required this.translationSectionController,
    required this.translationSectionAnimation,
    required this.textFadeController,
    required this.textFadeAnimation,
  }) : super(key: key);

  @override
  _TranslationWidgetState createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends ConsumerState<TranslationWidget> {
  @override
  void initState() {
    // context.afterBuild(refreshUI: true, () {});
    context.afterLayoutAsync(refreshUI: true, () async {
      // Initialize translation
      final service = ref.read(translationServiceProvider);
      await service.detectLanguageWithFlow(widget.originalText, context);
      // service.translateTextWithFlow(originalText: widget.originalText, post: widget.post, context: context, onTextChanged: _animateTextChange);
    });
    super.initState();
  }

  void _animateTextChange(String newText) {
    widget.textFadeController.reverse().then((_) {
      widget.post.text = newText;
      widget.textFadeController.forward();
    });
  }

  Future<void> _showLanguageSelector(BuildContext context, WidgetRef ref, isTranslating) async {
    final translationService = ref.read(translationServiceProvider);
    // bool isTranslating = ref.watch(isTranslatingProvider);

    if (isTranslating) return; // Prevent opening dialog during translation

    final selectedLangCode = await LanguageSelectorWidget.showLanguageSelector(context: context);
    if (selectedLangCode != null) {
      await translationService.handleLanguageSelection(
        selectedLangCode: selectedLangCode,
        originalText: widget.originalText,
        context: context,
        onTextChanged: _animateTextChange,
        post: widget.post,
        ref: ref,
      );
    }
  }

  Widget _buildTargetLanguageSelector(BuildContext context, WidgetRef ref, isTranslating, targetLanguage) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return GestureDetector(
      onTap: isTranslating ? null : () => _showLanguageSelector(context, ref, isTranslating),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: isTranslating ? theme.colorScheme.surface.withOpacity(0.5) : theme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 3),
            Text(
              "${targetLanguage.flag}  ${targetLanguage.name}",
              style: textTheme.bodyMedium?.copyWith(
                color: isTranslating ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: isTranslating ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      children: [
        LinearProgressIndicator(
          minHeight: 4,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildErrorText(BuildContext context) {
    return Column(
      children: [
        Text(
          'Unsupported language, publish text as is or cancel to retry',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    bool languageDetectionFailed = ref.watch(languageDetectionFailedProvider);
    bool isAutoDetecting = ref.watch(isAutoDetectingProvider);
    bool isTranslating = ref.watch(isTranslatingProvider);
    Language targetLanguage = ref.watch(targetLanguageProvider);
    print("\n\n\nLANGUAGE WIDGET STATE:");
    print("\n\n\nLANGUAGE WIDGET STATE languageDetectionFailed: $languageDetectionFailed");
    print("\n\n\nLANGUAGE WIDGET STATE isAutoDetecting: $isAutoDetecting");
    print("\n\n\nLANGUAGE WIDGET STATE isTranslating: $isTranslating");
    var showSelector = !languageDetectionFailed && !isAutoDetecting;
    print("\n\n\nLANGUAGE WIDGET STATE showSelector: $showSelector");
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // // Test 1: Simple visibility
        // if (showSelector) ...[
        //   Column(
        //     children: [
        //       Text("DEBUG: Selector should be visible"),
        //       Row(children: [_buildTargetLanguageSelector(context, ref, isTranslating, targetLanguage)]),
        //       const SizedBox(height: 0),
        //     ],
        //   ),
        // ],
        AnimGrowFade(
          show: showSelector,
          child: Column(
            children: [
              Row(children: [_buildTargetLanguageSelector(context, ref, isTranslating, targetLanguage)]),
              const SizedBox(height: 6),
            ],
          ),
        ),
        AnimGrowFade(show: languageDetectionFailed && !isAutoDetecting, child: _buildErrorText(context)),
        AnimGrowFade(show: isTranslating || isAutoDetecting, child: _buildProgressIndicator(context)),
      ],
    );
  }
}

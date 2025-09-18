// translation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/publish_options_provider.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../../memo/model/memo_model_post.dart';
import 'language_selector_widget.dart';

class TranslationWidget extends ConsumerStatefulWidget {
  final MemoModelPost post;
  final AnimationController translationSectionController;
  final Animation<double> translationSectionAnimation;
  final AnimationController textFadeController;
  final Animation<double> textFadeAnimation;
  final AnimationController buttonFadeController;
  final Animation<double> buttonFadeAnimation;
  final VoidCallback onTextChanged;

  const TranslationWidget({
    Key? key,
    required this.post,
    required this.translationSectionController,
    required this.translationSectionAnimation,
    required this.textFadeController,
    required this.textFadeAnimation,
    required this.buttonFadeController,
    required this.buttonFadeAnimation,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  _TranslationWidgetState createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends ConsumerState<TranslationWidget> {
  late String _originalText;
  late bool _isFirstTargetSelection;
  late bool _isUpdatingTargetLanguage;

  @override
  void initState() {
    super.initState();
    _originalText = widget.post.text ?? '';
    _isFirstTargetSelection = true;
    _isUpdatingTargetLanguage = false;
  }

  void _animateTextChange(String newText) {
    widget.textFadeController.reverse().then((_) {
      setState(() {
        widget.post.text = newText;
      });
      widget.onTextChanged();
      widget.textFadeController.forward();
    });
  }

  void _resetTranslation() {
    widget.buttonFadeController.reverse().then((_) {
      ref.read(translatedTextProvider.notifier).state = null;
      _animateTextChange(_originalText);

      final currentPublishOptions = ref.read(publishOptionsProvider);
      ref.read(publishOptionsProvider.notifier).state = PublishOptions(
        showTranslationWidget: currentPublishOptions.showTranslationWidget,
        publishInBothLanguages: false,
        originalText: null,
        originalLanguage: null,
        targetLanguage: null,
      );

      widget.buttonFadeController.forward();
    });
  }

  void _translateText() async {
    final targetLang = ref.read(targetLanguageProvider);
    final translationService = ref.read(translationServiceProvider);

    ref.read(isTranslatingProvider.notifier).state = true;

    try {
      // Auto-detect source language
      final translationService = ref.read(translationServiceProvider);
      final detectedLangCode = await translationService.detectLanguage(_originalText);
      final detectedLang = availableLanguages.firstWhere((lang) => lang.code == detectedLangCode, orElse: () => availableLanguages[0]);

      final translated = await translationService.translateText(text: _originalText, from: detectedLang.code, to: targetLang.code);

      ref.read(translatedTextProvider.notifier).state = translated;

      ref.read(publishOptionsProvider.notifier).state = PublishOptions(
        showTranslationWidget: true,
        publishInBothLanguages: ref.read(publishOptionsProvider).publishInBothLanguages,
        originalText: _originalText,
        originalLanguage: detectedLang,
        targetLanguage: targetLang,
      );

      widget.buttonFadeController.reverse().then((_) {
        _animateTextChange(translated);
        widget.buttonFadeController.forward();
      });
    } catch (e) {
      showSnackBar("Translation failed: ${e.toString()}", context, type: SnackbarType.error);
    } finally {
      ref.read(isTranslatingProvider.notifier).state = false;
    }
  }

  Future<void> _showLanguageSelector() async {
    final isTranslating = ref.read(isTranslatingProvider);
    if (isTranslating) return; // Prevent opening dialog during translation

    final selectedLangCode = await LanguageSelectorWidget.showLanguageSelector(context: context);
    if (selectedLangCode != null && mounted) {
      final selectedLang = availableLanguages.firstWhere(
        (lang) => lang.code == selectedLangCode,
        orElse: () => availableLanguages[1], // Default to first non-auto language
      );

      _isUpdatingTargetLanguage = true;
      ref.read(targetLanguageProvider.notifier).state = selectedLang;
      _isUpdatingTargetLanguage = false;

      // Trigger translation immediately when language is selected
      if (ref.read(publishOptionsProvider).showTranslationWidget) {
        _translateText();
      }
    }
  }

  Widget _buildTargetLanguageSelector() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final targetLang = ref.watch(targetLanguageProvider);
    final isTranslating = ref.watch(isTranslatingProvider);

    return GestureDetector(
      onTap: isTranslating ? null : _showLanguageSelector,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
          color: isTranslating ? theme.colorScheme.surface.withOpacity(0.5) : theme.colorScheme.surface,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              targetLang.name,
              style: textTheme.bodyMedium?.copyWith(
                color: isTranslating ? theme.colorScheme.onSurface.withOpacity(0.5) : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
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

  Widget _buildProgressIndicator() {
    final isTranslating = ref.watch(isTranslatingProvider);

    if (!isTranslating) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: LinearProgressIndicator(
        minHeight: 2,
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final publishOptions = ref.watch(publishOptionsProvider);
    final isTranslating = ref.watch(isTranslatingProvider);

    if (widget.post.text == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: publishOptions.showTranslationWidget,
              onChanged: isTranslating
                  ? null // Disable checkbox during translation to prevent state conflicts
                  : (value) {
                      final newValue = value ?? false;
                      ref.read(publishOptionsProvider.notifier).state = publishOptions.copyWith(showTranslationWidget: newValue);

                      if (newValue) {
                        widget.translationSectionController.forward();
                        // Trigger translation immediately when checkbox is checked
                        _translateText();
                      } else {
                        widget.translationSectionController.reverse();
                        _resetTranslation();
                      }
                    },
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isTranslating
                  ? null // Disable during translation
                  : () {
                      if (!publishOptions.showTranslationWidget) {
                        final newValue = true;
                        ref.read(publishOptionsProvider.notifier).state = publishOptions.copyWith(showTranslationWidget: newValue);
                        widget.translationSectionController.forward();
                        _translateText();
                      } else {
                        _showLanguageSelector();
                      }
                    },
              child: Text(
                'Translate to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isTranslating ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildTargetLanguageSelector(),
          ],
        ),
        const SizedBox(width: 8),
        _buildProgressIndicator(),
        const SizedBox(width: 8),
      ],
    );
  }
}

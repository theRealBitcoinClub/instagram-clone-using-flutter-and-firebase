// translation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/publish_options_provider.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../../memo/model/memo_model_post.dart';
import '../animations/animated_grow_fade_in.dart';
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
  late Language? _detectedLanguage;
  late bool _languageDetectionFailed;

  @override
  void initState() {
    super.initState();
    _originalText = widget.post.text ?? '';
    _detectedLanguage = null;
    _languageDetectionFailed = false;

    // Auto-detect language on init
    _detectLanguage();
  }

  Future<void> _detectLanguage() async {
    if (_originalText.isEmpty) return;

    try {
      final translationService = ref.read(translationServiceProvider);
      final detectedLangCode = await translationService.detectLanguage(_originalText);
      if (detectedLangCode == "error") {
        showSnackBar("Error on translation request", context, type: SnackbarType.error);
        _languageDetectionFailed = true;
        return;
      }

      setState(() {
        _detectedLanguage = availableLanguages.firstWhere((lang) => lang.code == detectedLangCode, orElse: () => availableLanguages[0]);
        _languageDetectionFailed = false;
      });

      if (_detectedLanguage != availableLanguages[0])
        showSnackBar("Detected language: ${_detectedLanguage!.name}", context, type: SnackbarType.success);

      // Set initial target language to detected language (showTranslationWidget = false)
      if (_detectedLanguage != null && _detectedLanguage!.code != 'auto') {
        ref.read(targetLanguageProvider.notifier).state = _detectedLanguage!;
        ref.read(publishOptionsProvider.notifier).state = ref.read(publishOptionsProvider).copyWith(showTranslationWidget: false);
      } else {
        _languageDetectionFailed = true;
        showSnackBar("Unsupported language detected", context, type: SnackbarType.info);
      }
    } catch (e) {
      setState(() {
        _languageDetectionFailed = true;
        _detectedLanguage = null;
      });
    }
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
      final translated = await translationService.translateText(text: _originalText, from: _detectedLanguage?.code, to: targetLang.code);

      ref.read(translatedTextProvider.notifier).state = translated;

      ref.read(publishOptionsProvider.notifier).state = PublishOptions(
        showTranslationWidget: true,
        publishInBothLanguages: ref.read(publishOptionsProvider).publishInBothLanguages,
        originalText: _originalText,
        originalLanguage: _detectedLanguage,
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

      ref.read(targetLanguageProvider.notifier).state = selectedLang;

      // Update showTranslationWidget based on whether the selected language matches detected language
      final shouldShowTranslationWidget = _detectedLanguage == null || selectedLang.code != _detectedLanguage!.code;

      ref.read(publishOptionsProvider.notifier).state = ref
          .read(publishOptionsProvider)
          .copyWith(showTranslationWidget: shouldShowTranslationWidget);

      // Trigger translation immediately if languages are different
      if (shouldShowTranslationWidget) {
        _translateText();
      } else {
        // Reset to original text if going back to detected language
        _resetTranslation();
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
            const SizedBox(width: 4),
            Text(
              targetLang.flag + "  " + targetLang.name,
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

    return LinearProgressIndicator(
      minHeight: 2,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
      borderRadius: BorderRadius.circular(2),
    );
  }

  Widget _buildErrorText() {
    return Text(
      'Unsupported language, publish text as is or cancel to retry',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
    );
  }

  Widget _buildDetectedLanguageInfo() {
    if (_detectedLanguage == null) return const SizedBox.shrink();

    return Text(
      'Original language: ${_detectedLanguage!.name}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTranslating = ref.watch(isTranslatingProvider);

    if (widget.post.text == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedGrowFadeIn(
          show: !_languageDetectionFailed,
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: [
              Row(children: [_buildTargetLanguageSelector()]),
              const SizedBox(height: 8),
            ],
          ),
        ),

        // Show detected language info or error message
        AnimatedGrowFadeIn(
          show: _detectedLanguage != null && !_languageDetectionFailed,
          duration: const Duration(milliseconds: 300),
          child: _buildDetectedLanguageInfo(),
        ),

        AnimatedGrowFadeIn(show: _languageDetectionFailed, duration: const Duration(milliseconds: 300), child: _buildErrorText()),

        const SizedBox(height: 4),
        AnimatedGrowFadeIn(show: isTranslating, duration: const Duration(milliseconds: 300), child: _buildProgressIndicator()),
      ],
    );
  }
}

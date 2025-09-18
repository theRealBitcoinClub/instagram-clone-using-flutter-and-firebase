// translation_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/publish_options_provider.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../../memo/model/memo_model_post.dart';

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
  late bool _isFirstSourceSelection;
  late bool _isUpdatingSourceLanguage;

  @override
  void initState() {
    super.initState();
    _originalText = widget.post.text ?? '';
    _isFirstSourceSelection = true;
    _isUpdatingSourceLanguage = false;
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
    final sourceLang = ref.read(sourceLanguageProvider);
    final targetLang = ref.read(targetLanguageProvider);
    final translationService = ref.read(translationServiceProvider);

    // final excludePatterns = [
    //   if (widget.post.topicId != null) widget.post.topicId!,
    //   ...widget.post.tagIds,
    // ].where((pattern) => pattern.isNotEmpty).toList();

    ref.read(isTranslatingProvider.notifier).state = true;

    try {
      final translated = await translationService.translateText(
        text: _originalText,
        from: sourceLang.code == 'auto' ? null : sourceLang.code,
        to: targetLang.code,
        // excludePatterns: excludePatterns,
      );

      ref.read(translatedTextProvider.notifier).state = translated;

      var detectedLang;
      if (sourceLang.code == 'auto') {
        final detectedLangCode = await translationService.detectLanguage(_originalText);
        detectedLang = availableLanguages.firstWhere(
          (lang) => lang.code == detectedLangCode,
          orElse: () => availableLanguages[0], //return AUTO if undetected
        );

        _isUpdatingSourceLanguage = true;
        ref.read(sourceLanguageProvider.notifier).state = detectedLang;
        _isUpdatingSourceLanguage = false;
      }

      final currentSourceLang = sourceLang.code == 'auto' ? detectedLang : sourceLang;

      ref.read(publishOptionsProvider.notifier).state = PublishOptions(
        showTranslationWidget: true,
        publishInBothLanguages: ref.read(publishOptionsProvider).publishInBothLanguages,
        originalText: _originalText,
        originalLanguage: currentSourceLang,
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

  Widget _buildTranslationToggle() {
    final publishOptions = ref.watch(publishOptionsProvider);

    return Row(
      children: [
        Checkbox(
          value: publishOptions.showTranslationWidget,
          onChanged: (value) {
            final newValue = value ?? false;
            ref.read(publishOptionsProvider.notifier).state = publishOptions.copyWith(showTranslationWidget: newValue);

            if (newValue) {
              widget.translationSectionController.forward();
            } else {
              widget.translationSectionController.reverse();
              _resetTranslation();
              // if (ref.read(translatedTextProvider) != null) {
              //   _resetTranslation();
              // }
            }
          },
        ),
        const SizedBox(width: 8),
        Expanded(child: Text('Translate this post', style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }

  Widget _buildTranslationRow() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final isTranslating = ref.watch(isTranslatingProvider);
    final hasTranslation = ref.watch(translatedTextProvider) != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Source', style: textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Consumer(
                    builder: (context, ref, child) {
                      final sourceLang = ref.watch(sourceLanguageProvider);
                      return DropdownButtonFormField<Language>(
                        value: sourceLang,
                        isExpanded: true,
                        items: availableLanguages.map((Language language) {
                          return DropdownMenuItem<Language>(
                            value: language,
                            child: Text(language.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (Language? newValue) {
                          if (newValue != null) {
                            ref.read(sourceLanguageProvider.notifier).state = newValue;

                            if (!_isUpdatingSourceLanguage && widget.post.text?.isNotEmpty == true) {
                              if (_isFirstSourceSelection) {
                                _translateText();
                                _isFirstSourceSelection = false;
                              } else {
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) {
                                    _translateText();
                                  }
                                });
                              }
                            }
                          }
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Target', style: textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Consumer(
                    builder: (context, ref, child) {
                      final targetLang = ref.watch(targetLanguageProvider);
                      return DropdownButtonFormField<Language>(
                        value: targetLang,
                        isExpanded: true,
                        items: availableLanguages.where((lang) => lang.code != 'auto').map((Language language) {
                          return DropdownMenuItem<Language>(
                            value: language,
                            child: Text(language.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (Language? newValue) {
                          if (newValue != null) {
                            ref.read(targetLanguageProvider.notifier).state = newValue;
                          }
                        },
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            SizedBox(
              width: 100,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 48,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: hasTranslation
                          ? SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                key: const ValueKey('reset_button'),
                                onPressed: _resetTranslation,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: theme.colorScheme.errorContainer,
                                  foregroundColor: theme.colorScheme.onErrorContainer,
                                ),
                                child: const Text('RESET'),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                key: const ValueKey('translate_button'),
                                onPressed: isTranslating ? null : _translateText,
                                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                                child: isTranslating
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('LANG'),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.post.text != null) _buildTranslationToggle(),
        if (widget.post.text != null && ref.read(publishOptionsProvider).showTranslationWidget)
          FadeTransition(
            opacity: widget.translationSectionAnimation,
            child: Column(children: [_buildTranslationRow()]),
          ),
      ],
    );
  }
}

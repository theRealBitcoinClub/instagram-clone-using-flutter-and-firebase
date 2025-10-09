// animated_translated_text.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../../expandable_text_custom.dart';
import '../../main.dart';
import '../../provider/translation_cache.dart';
import '../../widgets/animations/animated_grow_fade_in.dart';

class AnimatedTranslatedText extends ConsumerStatefulWidget {
  final MemoModelPost post;
  final String originalText;
  final bool doTranslate;
  final TextStyle? style;
  final int maxLines;
  final String expandText;
  final String collapseText;
  final Color linkColor;
  final TextStyle? hashtagStyle;
  final Function(String)? onHashtagTap;
  final TextStyle? mentionStyle;
  final TextStyle? urlStyle;
  final Function(String)? onUrlTap;
  final String? prefixText;
  final TextStyle? prefixStyle;
  final Function()? onPrefixTap;

  const AnimatedTranslatedText({
    Key? key,
    required this.post,
    required this.originalText,
    required this.doTranslate,
    this.style,
    this.maxLines = 5,
    this.expandText = ' show more',
    this.collapseText = 'show less',
    this.linkColor = Colors.blue,
    this.hashtagStyle,
    this.onHashtagTap,
    this.mentionStyle,
    this.urlStyle,
    this.onUrlTap,
    this.prefixText,
    this.prefixStyle,
    this.onPrefixTap,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedTranslatedText> createState() => _AnimatedTranslatedTextState();
}

class _AnimatedTranslatedTextState extends ConsumerState<AnimatedTranslatedText> {
  String _currentText = '';
  bool _showTranslated = false;
  bool _isTranslating = false;
  PostTranslationParams? _currentParams;

  @override
  void initState() {
    super.initState();
    _currentText = widget.originalText;
    _showTranslated = false;
    _isTranslating = true;
    _currentParams = PostTranslationParams(
      post: widget.post,
      doTranslate: widget.doTranslate,
      // text: widget.originalText,
      // context: context,
      languageCode: "fake",
    );
    // context.afterBuild(() {
    //   _startTranslation();
    // }, refreshUI: true);
  }

  // void _startTranslation() {
  //   // If translation is disabled, we're done
  //   if (!widget.doTranslate || widget.originalText.trim().isEmpty) {
  //     return;
  //   }
  //
  //   final currentLanguage = ref.read(languageCodeProvider); // Get current language
  //
  //   // Always show original text first
  //   setState(() {
  //     _currentText = widget.originalText;
  //     _showTranslated = false;
  //     _isTranslating = true;
  //     _currentParams = PostTranslationParams(
  //       post: widget.post,
  //       doTranslate: widget.doTranslate,
  //       text: widget.originalText,
  //       context: context,
  //       languageCode: currentLanguage,
  //     );
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // Watch language changes to trigger re-translation
    final currentLanguage = ref.watch(languageCodeProvider);

    // Watch the translation provider in the build method - this is crucial for Riverpod reactivity
    // if (_currentParams != null && widget.doTranslate && widget.originalText.trim().isNotEmpty) {
    if (_currentParams!.languageCode != currentLanguage) {
      _currentParams = PostTranslationParams(
        post: widget.post,
        doTranslate: widget.doTranslate,
        // text: widget.originalText,
        // context: context,
        languageCode: currentLanguage,
      );
      _isTranslating = true;
    }

    final translationAsync = ref.watch(postTranslationViewerProvider(_currentParams!));

    translationAsync.when(
      data: (translatedText) {
        // Use post-frame callback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // if (translatedText != widget.originalText) {
            // Only animate if the text actually changed
            setState(() {
              _currentText = translatedText;
              _showTranslated = true;
              _isTranslating = false;
            });
            // showSnackBar("SUCCESS TRANSLATING POST: ${widget.postId}", type: SnackbarType.success);
            // } else if (_isTranslating) {
            //   setState(() {
            //     _isTranslating = false;
            //   });
            // }
          }
        });
      },
      loading: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_isTranslating) {
            setState(() {
              _isTranslating = true;
            });
          }
        });
      },
      error: (error, stack) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showSnackBar("Translation error: $error", type: SnackbarType.error);
            setState(() {
              _isTranslating = false;
            });
            // showSnackBar("ERROR TRANSLATING POST: ${widget.postId}", type: SnackbarType.error);
          }
        });
      },
    );
    // }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading indicator
        if (_isTranslating)
          const Padding(
            padding: EdgeInsets.only(bottom: 6, top: 6),
            child: LinearProgressIndicator(minHeight: 1),
            // Row(
            //   children: [
            //     SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 1.5)),
            //     SizedBox(width: 8),
            //     Text('Translating...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            //   ],
            // ),
          ),

        // Animated text content
        AnimGrowFade(
          show: true, // Always show, we handle content switching internally
          child: _buildTextContent(),
        ),
      ],
    );
  }

  Widget _buildTextContent() {
    return ExpandableTextCustom(
      _currentText,
      expandText: widget.expandText,
      collapseText: widget.collapseText,
      maxLines: widget.maxLines,
      linkColor: widget.linkColor,
      style: widget.style,
      hashtagStyle: widget.hashtagStyle,
      onHashtagTap: widget.onHashtagTap,
      mentionStyle: widget.mentionStyle,
      urlStyle: widget.urlStyle,
      onUrlTap: widget.onUrlTap,
      prefixText: widget.prefixText,
      prefixStyle: widget.prefixStyle,
      onPrefixTap: widget.onPrefixTap,
    );
  }
}

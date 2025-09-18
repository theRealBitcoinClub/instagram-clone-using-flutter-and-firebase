import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/add/tip_information_card.dart';
import 'package:mahakka/widgets/add/translation_widget.dart';

import '../../memo/model/memo_model_post.dart';
import '../../memo/model/memo_model_user.dart';
import '../../provider/draft_post_provider.dart';
import '../../provider/publish_options_provider.dart';
import '../../provider/translation_service.dart';
import '../../provider/user_provider.dart';
import '../../screens/add/imgur_media_widget.dart';
import '../../screens/add/ipfs_media_widget.dart';
import '../../screens/add/odysee_media_widget.dart';
import '../../screens/add/youtube_media_widget.dart';
import '../hashtag_display_widget.dart';
import '../profile/settings_widget.dart';
import 'delete_confirmation_dialog.dart';

// Assuming you have a userProvider defined elsewhere
// final userProvider = StateProvider<MemoModelUser>((ref) => MemoModelUser());

class PublishConfirmationActivity extends ConsumerStatefulWidget {
  final MemoModelPost post;

  const PublishConfirmationActivity({Key? key, required this.post}) : super(key: key);

  static Future<bool?> show(BuildContext context, {required MemoModelPost post}) {
    return Navigator.of(context).push<bool?>(MaterialPageRoute(builder: (context) => PublishConfirmationActivity(post: post)));
  }

  @override
  _PublishConfirmationActivityState createState() => _PublishConfirmationActivityState();
}

class _PublishConfirmationActivityState extends ConsumerState<PublishConfirmationActivity> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late bool _isNewPost;
  late String _originalText;

  // ADD THESE NEW ANIMATION CONTROLLERS
  late AnimationController _textFadeController;
  late Animation<double> _textFadeAnimation;
  // Add this new animation controller for button transitions
  late AnimationController _buttonFadeController;
  late Animation<double> _buttonFadeAnimation;
  late bool _isFirstSourceSelection; // ADD THIS FLAG
  late bool _isUpdatingSourceLanguage; // ADD THIS FLAG

  // ADD TRANSLATION SECTION FADE ANIMATION CONTROLLER
  late AnimationController _translationSectionController;
  late Animation<double> _translationSectionAnimation;

  final detectedLanguageProvider = StateProvider<Language?>((ref) => null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _originalText = widget.post.text ?? '';
    _isUpdatingSourceLanguage = false; // INITIALIZE THE FLAG
    _isFirstSourceSelection = true; // INITIALIZE THE FLAG
    _translationSectionController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _translationSectionAnimation = CurvedAnimation(
      parent: _translationSectionController,
      curve: Curves.easeInOut,
    ); // Start with translation section visible if hasTranslation is true
    if (ref.read(publishOptionsProvider).showTranslationWidget) {
      _translationSectionController.forward();
    }
    // ADD TEXT FADE ANIMATION CONTROLLER
    _textFadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _textFadeAnimation = CurvedAnimation(parent: _textFadeController, curve: Curves.easeInOut);

    // ADD BUTTON FADE ANIMATION CONTROLLER
    _buttonFadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _buttonFadeAnimation = CurvedAnimation(parent: _buttonFadeController, curve: Curves.easeInOut);

    // Initialize temporary values with user's current settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider)!;
      user.temporaryTipAmount = user.tipAmountEnum;
      user.temporaryTipReceiver = user.tipReceiver;

      // ADD THIS: Start text fade-in animation after the main animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _textFadeController.forward();
          _buttonFadeController.forward();
        }
      });
    });

    _isNewPost = ref.read(userProvider)!.id == widget.post.creator!.id;

    _controller.forward();
  }

  @override
  void dispose() {
    // DISPOSE TEXT FADE CONTROLLER
    _textFadeController.dispose();
    _translationSectionController.dispose(); // ADD THIS
    _buttonFadeController.dispose(); // ADD THIS
    _controller.dispose();
    super.dispose();
  }

  // ADD THIS NEW METHOD FOR ANIMATED TEXT TRANSITION
  void _animateTextChange(String newText) {
    // First fade out
    _textFadeController.reverse().then((_) {
      // Change text while invisible
      setState(() {
        widget.post.text = newText;
      });
      // Then fade back in
      _textFadeController.forward();
    });
  }

  void _increaseTipAmount() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipAmount ?? user.tipAmountEnum;
    final values = TipAmount.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex < values.length - 1) {
      setState(() {
        user.temporaryTipAmount = values[currentIndex + 1];
      });
      showSnackBar("Changed Tip Amount for this Post!", context, type: SnackbarType.success);
    } else {
      showSnackBar("It is already the maximum!", context, type: SnackbarType.info);
    }
  }

  void _decreaseTipAmount() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipAmount ?? user.tipAmountEnum;
    final values = TipAmount.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex > 0) {
      setState(() {
        user.temporaryTipAmount = values[currentIndex - 1];
      });
      showSnackBar("Changed Tip Amount for this Post!", context, type: SnackbarType.success);
    } else {
      showSnackBar("It is already the minimum!", context, type: SnackbarType.info);
    }
  }

  void _nextTipReceiver() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipReceiver ?? user.tipReceiver;
    final values = TipReceiver.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex < values.length - 1) {
      setState(() {
        user.temporaryTipReceiver = values[currentIndex + 1];
      });
      showSnackBar("Changed Tip Receiver for this Post!", context, type: SnackbarType.success);
    } else {
      showSnackBar("It is already the last option!", context, type: SnackbarType.info);
    }
  }

  void _previousTipReceiver() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipReceiver ?? user.tipReceiver;
    final values = TipReceiver.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex > 0) {
      setState(() {
        user.temporaryTipReceiver = values[currentIndex - 1];
      });
      showSnackBar("Changed Tip Receiver for this Post!", context, type: SnackbarType.success);
    } else {
      showSnackBar("It is already the first option!", context, type: SnackbarType.info);
    }
  }

  String _getTipAmountDisplay(TipAmount amount) {
    final formattedValue = amount.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return "$formattedValue satoshis";
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        theme: Theme.of(context),
        onCancel: () {
          // ref.read(draftPostProvider) = widget.post;
          _resetTranslation();
          // ref.read(userProvider)!.temporaryTipReceiver = null;
          // ref.read(userProvider)!.temporaryTipAmount = null;
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop(false);
        },
        onContinue: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showTipSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsWidget(initialTab: SettingsTab.tips),
    );
  }

  void _onSendPost() async {
    try {
      //TODO remove the original and translated new properties of MemoModelPost to use draft post provider exclusively
      //TODO make sure to properly integrate that in add_screen as the publication is not happening here
      // final publishOptions = ref.read(publishOptionsProvider);
      // final translatedText = ref.read(translatedTextProvider);
      // final draftPost = ref.read(draftPostProvider);
      //
      // // Use the draft post if available, otherwise use widget.post
      // final postToPublish = draftPost ?? widget.post;
      //
      // // If publishing in both languages, add the original text to the post
      // if (publishOptions.publishInBothLanguages && translatedText != null) {
      //   // Add original text and language info to your post model
      //   // You'll need to extend your MemoModelPost to include these fields
      //   widget.post.originalText = _originalText;
      //   widget.post.originalLanguage = publishOptions.originalLanguage?.code;
      //   widget.post.translatedLanguage = publishOptions.targetLanguage?.code;
      // }

      Navigator.of(context).pop(true);
    } catch (e) {
      Navigator.of(context).pop(false);
    }
  }

  // MODIFY THE _translateText METHOD
  // void _translateText() async {
  //   final sourceLang = ref.read(sourceLanguageProvider);
  //   final targetLang = ref.read(targetLanguageProvider);
  //   final translationService = ref.read(translationServiceProvider);
  //
  //   // Get patterns to exclude (topicId and tagIds)
  //   final excludePatterns = [
  //     if (widget.post.topicId != null) widget.post.topicId!,
  //     ...widget.post.tagIds,
  //   ].where((pattern) => pattern.isNotEmpty).toList();
  //
  //   ref.read(isTranslatingProvider.notifier).state = true;
  //
  //   try {
  //     final translated = await translationService.translateText(
  //       text: _originalText,
  //       from: sourceLang.code == 'auto' ? null : sourceLang.code,
  //       to: targetLang.code,
  //       // excludePatterns: excludePatterns,
  //     );
  //
  //     ref.read(translatedTextProvider.notifier).state = translated;
  //
  //     // Handle auto-detection
  //     if (sourceLang.code == 'auto') {
  //       // Assuming your translation service returns detected language
  //       // You'll need to modify your translation service to return this info
  //       final detectedLangCode = await translationService.detectLanguage(_originalText);
  //       final detectedLang = availableLanguages.firstWhere(
  //         (lang) => lang.code == detectedLangCode,
  //         orElse: () => const Language(code: 'en', name: 'English'),
  //       );
  //
  //       ref.read(detectedLanguageProvider.notifier).state = detectedLang;
  //
  //       // Update source language dropdown to show detected language
  //       // but don't trigger another translation
  //       _isUpdatingSourceLanguage = true;
  //       ref.read(sourceLanguageProvider.notifier).state = detectedLang;
  //       _isUpdatingSourceLanguage = false;
  //     }
  //
  //     // Update publish options with original and translated text info
  //     final currentSourceLang = sourceLang.code == 'auto' ? ref.read(detectedLanguageProvider) : sourceLang;
  //
  //     ref.read(publishOptionsProvider.notifier).state = PublishOptions(
  //       hasTranslation: true, // Set hasTranslation to true
  //       publishInBothLanguages: ref.read(publishOptionsProvider).publishInBothLanguages,
  //       originalText: _originalText,
  //       originalLanguage: currentSourceLang,
  //       targetLanguage: targetLang,
  //     );
  //
  //     // Animate button transition and text change together
  //     _buttonFadeController.reverse().then((_) {
  //       // Use the animated text change method
  //       _animateTextChange(translated);
  //       // Then fade back in
  //       _buttonFadeController.forward();
  //     });
  //   } catch (e) {
  //     showSnackBar("Translation failed: ${e.toString()}", context, type: SnackbarType.error);
  //   } finally {
  //     ref.read(isTranslatingProvider.notifier).state = false;
  //   }
  // }

  // ADD THIS METHOD TO BUILD THE TRANSLATION TOGGLE CHECKBOX
  // Widget _buildTranslationToggle() {
  //   final publishOptions = ref.watch(publishOptionsProvider);
  //
  //   return Row(
  //     children: [
  //       Checkbox(
  //         value: publishOptions.hasTranslation,
  //         onChanged: (value) {
  //           final newValue = value ?? false;
  //           ref.read(publishOptionsProvider.notifier).state = publishOptions.copyWith(hasTranslation: newValue);
  //
  //           // Animate the translation section in or out
  //           if (newValue) {
  //             _translationSectionController.forward();
  //           } else {
  //             _translationSectionController.reverse();
  //             // Reset translation if user disables translations
  //             if (ref.read(translatedTextProvider) != null) {
  //               _resetTranslation();
  //             }
  //           }
  //         },
  //       ),
  //       const SizedBox(width: 8),
  //       Expanded(child: Text('Translate this post', style: Theme.of(context).textTheme.bodyMedium)),
  //     ],
  //   );
  // }

  void _resetTranslation() {
    ref.read(draftPostProvider.notifier).state = widget.post;
    // Animate button transition
    ref.read(translatedTextProvider.notifier).state = null;
    // Get current state to preserve hasTranslation
    final currentPublishOptions = ref.read(publishOptionsProvider);

    // Create a fresh options object with only hasTranslation preserved
    ref.read(publishOptionsProvider.notifier).state = PublishOptions(
      showTranslationWidget: currentPublishOptions.showTranslationWidget, // Keep the same value
      publishInBothLanguages: false, // Reset to default
      originalText: null, // Reset to default
      originalLanguage: null, // Reset to default
      targetLanguage: null, // Reset to default
    );
  }

  // Widget _buildTranslationRow() {
  //   final theme = Theme.of(context);
  //   final colorScheme = theme.colorScheme;
  //   final textTheme = theme.textTheme;
  //
  //   final isTranslating = ref.watch(isTranslatingProvider);
  //   final hasTranslation = ref.watch(translatedTextProvider) != null;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Row(
  //         children: [
  //           // Source language dropdown
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Source', style: textTheme.labelSmall),
  //                 const SizedBox(height: 4),
  //                 Consumer(
  //                   builder: (context, ref, child) {
  //                     final sourceLang = ref.watch(sourceLanguageProvider);
  //                     return DropdownButtonFormField<Language>(
  //                       value: sourceLang,
  //                       isExpanded: true,
  //                       items: availableLanguages.map((Language language) {
  //                         return DropdownMenuItem<Language>(
  //                           value: language,
  //                           child: Text(language.name, overflow: TextOverflow.ellipsis),
  //                         );
  //                       }).toList(),
  //                       // In the source language dropdown onChanged handler:
  //                       onChanged: (Language? newValue) {
  //                         if (newValue != null) {
  //                           ref.read(sourceLanguageProvider.notifier).state = newValue;
  //
  //                           // Only auto-translate if we're not programmatically updating the source language
  //                           if (!_isUpdatingSourceLanguage && widget.post.text?.isNotEmpty == true) {
  //                             // For first selection, translate immediately
  //                             if (_isFirstSourceSelection) {
  //                               _translateText();
  //                               _isFirstSourceSelection = false;
  //                             } else {
  //                               // For subsequent changes, use a small delay to avoid rapid translations
  //                               Future.delayed(const Duration(milliseconds: 300), () {
  //                                 if (mounted) {
  //                                   _translateText();
  //                                 }
  //                               });
  //                             }
  //                           }
  //                         }
  //                       },
  //                       decoration: InputDecoration(
  //                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //
  //           const SizedBox(width: 12),
  //
  //           // Target language dropdown
  //           Expanded(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 Text('Target', style: textTheme.labelSmall),
  //                 const SizedBox(height: 4),
  //                 Consumer(
  //                   builder: (context, ref, child) {
  //                     final targetLang = ref.watch(targetLanguageProvider);
  //                     return DropdownButtonFormField<Language>(
  //                       value: targetLang,
  //                       isExpanded: true,
  //                       items: availableLanguages.where((lang) => lang.code != 'auto').map((Language language) {
  //                         return DropdownMenuItem<Language>(
  //                           value: language,
  //                           child: Text(language.name, overflow: TextOverflow.ellipsis),
  //                         );
  //                       }).toList(),
  //                       onChanged: (Language? newValue) {
  //                         if (newValue != null) {
  //                           ref.read(targetLanguageProvider.notifier).state = newValue;
  //                         }
  //                       },
  //                       decoration: InputDecoration(
  //                         contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  //                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //
  //           const SizedBox(width: 12),
  //
  //           // Button container with fixed width
  //           SizedBox(
  //             width: 100, // Fixed width for both buttons
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 20), // Align with dropdowns
  //                 SizedBox(
  //                   height: 48,
  //                   child: AnimatedSwitcher(
  //                     duration: const Duration(milliseconds: 300),
  //                     transitionBuilder: (Widget child, Animation<double> animation) {
  //                       return FadeTransition(opacity: animation, child: child);
  //                     },
  //                     child: hasTranslation
  //                         ? SizedBox(
  //                             width: double.infinity, // Expand to fill parent
  //                             child: ElevatedButton(
  //                               key: const ValueKey('reset_button'),
  //                               onPressed: _resetTranslation,
  //                               style: ElevatedButton.styleFrom(
  //                                 minimumSize: const Size.fromHeight(48), // Ensure consistent height
  //                                 backgroundColor: colorScheme.errorContainer,
  //                                 foregroundColor: colorScheme.onErrorContainer,
  //                               ),
  //                               child: const Text('RESET'),
  //                             ),
  //                           )
  //                         : SizedBox(
  //                             width: double.infinity, // Expand to fill parent
  //                             child: ElevatedButton(
  //                               key: const ValueKey('translate_button'),
  //                               onPressed: isTranslating ? null : _translateText,
  //                               style: ElevatedButton.styleFrom(
  //                                 minimumSize: const Size.fromHeight(48), // Ensure consistent height
  //                               ),
  //                               child: isTranslating
  //                                   ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
  //                                   : const Text('LANG'),
  //                             ),
  //                           ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //       const SizedBox(height: 16),
  //     ],
  //   );
  // }
  //
  // // ADD THIS METHOD TO BUILD THE CHECKBOX
  // Widget _buildPublishOptions() {
  //   final publishOptions = ref.watch(publishOptionsProvider);
  //   //TODO ALWAYS RESET THE VALUE ON INIT OR LEAVE IT AS IT WAS IN THE LAST PUBLICATION?
  //   // ref.read(publishOptionsProvider.notifier).state = publishOptions.copyWith(publishInBothLanguages: false);
  //   final hasTranslation = ref.watch(translatedTextProvider) != null;
  //
  //   return Column(
  //     children: [
  //       const SizedBox(height: 16),
  //       Row(
  //         children: [
  //           Checkbox(
  //             value: publishOptions.publishInBothLanguages,
  //             onChanged: hasTranslation
  //                 ? (value) {
  //                     ref.read(publishOptionsProvider.notifier).state = publishOptions.copyWith(publishInBothLanguages: value);
  //                   }
  //                 : null, // Disable if no translation available
  //           ),
  //           const SizedBox(width: 8),
  //           Expanded(child: Text('Publish in both original and translated languages', style: Theme.of(context).textTheme.bodyMedium)),
  //         ],
  //       ),
  //       if (publishOptions.publishInBothLanguages && hasTranslation) ...[
  //         const SizedBox(height: 8),
  //         Text(
  //           'Your post will be published in both ${publishOptions.originalLanguage?.name ?? 'original'} and ${publishOptions.targetLanguage?.name ?? 'translated'} languages.',
  //           style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  //         ),
  //       ],
  //     ],
  //   );
  // }

  Widget _buildMediaPreview(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    final post = widget.post;
    // post.imgurUrl = post.imgurUrl ?? ref.read(imgurUrlProvider);
    // post.youtubeId = post.youtubeId ?? ref.read(youtubeVideoIdProvider);
    // post.ipfsCid = post.ipfsCid ?? ref.read(ipfsCidProvider);
    // post.videoUrl = post.videoUrl ?? ref.read(odyseeUrlProvider);

    if (post.imgurUrl?.isNotEmpty == true) {
      return ImgurMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, imgurUrl: post.imgurUrl!);
    }

    if (post.youtubeId?.isNotEmpty == true) {
      return YouTubeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, youtubeId: post.youtubeId!);
    }

    if (post.ipfsCid?.isNotEmpty == true) {
      return IpfsMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, ipfsCid: post.ipfsCid!);
    }

    if (post.videoUrl?.isNotEmpty == true) {
      return OdyseeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, videoUrl: post.videoUrl!);
    }

    if (post.imageUrl?.isNotEmpty == true) {
      return Image.network(
        post.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: theme.colorScheme.error),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final temporaryTipAmount = user.temporaryTipAmount ?? user.tipAmountEnum;

    var colorBottomBarIcon = colorScheme.onSurfaceVariant;
    String translatedText = ref.watch(translatedTextProvider) != null ? ref.read(translatedTextProvider)! : "";

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 50,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => _showDeleteConfirmation(),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.creator.profileIdShort, style: textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary)),
            Text(_getTipAmountDisplay(temporaryTipAmount), style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: colorScheme.onPrimary),
            onPressed: _onSendPost,
            tooltip: 'Confirm and Send',
          ),
        ],
        elevation: 4,
        shadowColor: colorScheme.shadow,
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ADD THE TRANSLATION TOGGLE CHECKBOX
              if (widget.post.text != null)
                TranslationWidget(
                  post: widget.post,
                  translationSectionController: _translationSectionController,
                  translationSectionAnimation: _translationSectionAnimation,
                  textFadeController: _textFadeController,
                  textFadeAnimation: _textFadeAnimation,
                  buttonFadeController: _buttonFadeController,
                  buttonFadeAnimation: _buttonFadeAnimation,
                  onTextChanged: () {
                    // Update draft post provider when text changes
                    // ref.read(draftPostProvider.notifier).state = widget.post;
                  },
                ),
              if (widget.post.text != null)
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Text(translatedText.isNotEmpty ? translatedText : widget.post.text!, style: textTheme.bodyLarge),
                ),
              const SizedBox(height: 12),
              if (widget.post.tagIds.isNotEmpty) HashtagDisplayWidget(hashtags: widget.post.tagIds, theme: theme),
              if (widget.post.tagIds.isNotEmpty) const SizedBox(height: 16),
              _buildMediaPreview(theme, colorScheme, textTheme),
              const SizedBox(height: 4),
              TipInformationCard(post: widget.post),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'CANCEL',
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.onError, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _onSendPost();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'SEND',
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        elevation: Theme.of(context).bottomAppBarTheme.elevation,
        shadowColor: Theme.of(context).colorScheme.shadow,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        height: Theme.of(context).bottomAppBarTheme.height,
        padding: Theme.of(context).bottomAppBarTheme.padding,
        // color: colorScheme.surface,
        // elevation: 8,
        // shadowColor: colorScheme.shadow,
        // surfaceTintColor: colorScheme.surfaceTint,
        // height: kBottomNavigationBarHeight + 16,
        // padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(size: 36, Icons.arrow_back, color: _isNewPost ? colorBottomBarIcon.withAlpha(111) : colorBottomBarIcon),
                onPressed: _isNewPost ? null : _previousTipReceiver,
                tooltip: 'Previous Receiver',
              ),
              IconButton(
                icon: Icon(size: 36, Icons.arrow_downward, color: colorBottomBarIcon),
                onPressed: _decreaseTipAmount,
                tooltip: 'Decrease Tip',
              ),
              IconButton(
                icon: Icon(size: 32, Icons.settings, color: colorBottomBarIcon),
                onPressed: _showTipSettings,
                tooltip: 'Tip Settings',
              ),
              IconButton(
                icon: Icon(size: 36, Icons.arrow_upward, color: colorBottomBarIcon),
                onPressed: _increaseTipAmount,
                tooltip: 'Increase Tip',
              ),
              IconButton(
                icon: Icon(size: 36, Icons.arrow_forward, color: _isNewPost ? colorBottomBarIcon.withAlpha(111) : colorBottomBarIcon),
                onPressed: _isNewPost ? null : _nextTipReceiver,
                tooltip: 'Next Receiver',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

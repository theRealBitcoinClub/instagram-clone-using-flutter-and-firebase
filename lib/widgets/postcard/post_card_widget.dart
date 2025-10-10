import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:mahakka/widgets/postcard/post_card_footer.dart';
import 'package:mahakka/widgets/preview_url_widget.dart';
import 'package:mahakka/widgets/unified_video_player.dart';

import '../../memo/base/text_input_verifier.dart';
import '../../memo/memo_reg_exp.dart';
import '../../provider/telegram_bot_publisher.dart';
import '../../provider/translation_service.dart';
import '../../providers/post_creator_provider.dart';
import '../../screens/add/add_post_providers.dart';
import '../add/publish_confirmation_activity.dart';
import '../unified_image_widget.dart';
import 'post_card_header.dart';
import 'postcard_animations.dart';

// Logging helper
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: PostCardWidget - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class PostCard extends ConsumerStatefulWidget {
  final MemoModelPost post;
  final VoidCallback? onShowSendButton; // Add callback parameter
  final int? index;

  const PostCard(this.post, {super.key, this.onShowSendButton, this.index}); // Update constructor

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  static const double _altImageHeight = 50.0;
  // static const int _maxTagsCounter = 3;
  // static const int _minTextLength = 20;
  bool _isAnimatingLikeConfirmation = false;
  bool _isSendingLikeTx = false;
  bool _isSendingReplyTx = false;
  bool _showInput = false;
  bool _showSend = false;
  bool _hasSelectedTopic = false;
  late List<bool> _selectedHashtags;
  late TextEditingController _textEditController;
  bool _showYouTubePlayer = false;
  bool _isAnimatingYouTube = false;
  bool _previousShowSendState = false; // Track previous state

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _initializeSelectedHashtags();
    _showYouTubePlayer = false;
    _isAnimatingYouTube = false;
    _previousShowSendState = _showSend;
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  void _initializeSelectedHashtags() {
    final int count = widget.post.tagIds.length > MemoVerifier.maxHashtags ? MemoVerifier.maxHashtags : widget.post.tagIds.length;
    _selectedHashtags = List<bool>.filled(count, false);
  }

  Widget _buildVideoWidget(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(color: colorScheme.surface, border: Border()),
        child: ClipRRect(
          child: UnifiedVideoPlayer(type: VideoPlayerType.generic, aspectRatio: 16 / 9, autoPlay: false, videoUrl: widget.post.videoUrl!),
        ),
      ),
    );
  }

  Widget _buildYouTubeWidget(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return GestureDetector(
      onDoubleTap: _toggleYouTubePlayer,
      onLongPress: _toggleYouTubePlayer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: _showYouTubePlayer ? 200.0 : 50.0,
        decoration: BoxDecoration(color: colorScheme.surface, border: Border()),
        child: ClipRRect(
          child: _showYouTubePlayer
              ? _buildYouTubePlayerWithOverlay(theme, colorScheme, textTheme)
              : _buildYouTubePlaceholder(theme, colorScheme, textTheme),
        ),
      ),
    );
  }

  bool _showOverlayHint = true;

  void _hideOverlayAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showYouTubePlayer) {
        setState(() {
          _showOverlayHint = false;
        });
      }
    });
  }

  Widget _buildYouTubePlayerWithOverlay(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Stack(
      children: [
        UnifiedVideoPlayer(
          type: VideoPlayerType.youtube,
          videoId: widget.post.youtubeId!,
          aspectRatio: 16 / 9,
          autoPlay: true,
          showControls: true,
          theme: theme,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        Positioned(
          top: 8,
          left: 8,
          child: AnimatedOpacity(
            opacity: (_isAnimatingYouTube || !_showOverlayHint) ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    "Long press to minimize",
                    style: textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYouTubePlaceholder(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      color: theme.colorScheme.primary.withAlpha(222),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_filled, color: theme.colorScheme.onPrimary, size: 32),
            const SizedBox(width: 8),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "YouTube Video",
                  style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w500),
                ),
                Text("Double tap to play", style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimary.withAlpha(222))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostMedia(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    String imgUrl = widget.post.imageUrl ?? widget.post.imgurUrl ?? "";
    var insets = EdgeInsets.fromLTRB(0, 6, 0, 9);

    if (widget.post.youtubeId != null && widget.post.youtubeId!.isNotEmpty) {
      return Padding(padding: insets, child: _buildYouTubeWidget(theme, colorScheme, textTheme));
    } else if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      return Padding(padding: insets, child: _buildVideoWidget(theme, colorScheme, textTheme));
    } else if (imgUrl.isNotEmpty) {
      return Padding(
        padding: insets,
        child: UnifiedImageWidget(
          imageUrl: imgUrl,
          sourceType: ImageSourceType.network,
          fitMode: ImageFitMode.contain,
          aspectRatio: 16 / 9,
          border: Border(),
          backgroundColor: colorScheme.surface,
          showLoadingProgress: true,
        ),
      );
    } else if (widget.post.ipfsCid != null && widget.post.ipfsCid!.isNotEmpty) {
      return Padding(
        padding: insets,
        child: UnifiedImageWidget(
          imageUrl: widget.post.ipfsCid!,
          sourceType: ImageSourceType.ipfs,
          fitMode: ImageFitMode.contain,
          // aspectRatio: 16 / 9,
          border: Border(),
          backgroundColor: colorScheme.surface,
          showLoadingProgress: true,
          errorWidget: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, color: colorScheme.onSurface.withAlpha(153), size: 36),
              const SizedBox(height: 8),
              Text("Error loading IPFS content", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text("${widget.post.ipfsCid}", style: textTheme.bodySmall!.copyWith(color: theme.colorScheme.onSurface)),
            ],
          ),
        ),
      );
    } else if ((!widget.post.hasMedia &&
        widget.post.text != null &&
        widget.post.text!.isNotEmpty &&
        (widget.post.hasUrlsInText || widget.post.urls.isNotEmpty))) {
      final validUrl = MemoRegExp.extractUrlsGenerously(widget.post.text!);
      if (widget.post.urls.isNotEmpty) {
        return Padding(
          padding: insets,
          child: PreviewUrlWidget(url: widget.post.urls[0].trim()),
        );
      } else if (validUrl.isNotEmpty) {
        return Padding(
          padding: insets,
          child: PreviewUrlWidget(url: validUrl[0].trim()),
        );
      } else {
        return _buildFallbackWidget(colorScheme);
      }
    } else {
      return _buildFallbackWidget(colorScheme);
    }
  }

  void _toggleYouTubePlayer() {
    if (_isAnimatingYouTube) return;

    setState(() {
      _isAnimatingYouTube = true;
      _showYouTubePlayer = !_showYouTubePlayer;
      _showOverlayHint = true;
    });

    if (_showYouTubePlayer) {
      _hideOverlayAfterDelay();
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isAnimatingYouTube = false;
        });
      }
    });
  }

  Widget _buildFallbackWidget(ColorScheme colorScheme) {
    return Divider(color: colorScheme.surfaceVariant.withAlpha(153), height: 9, thickness: 1);

    Container(
      height: _altImageHeight,
      color: colorScheme.surface,
      child: Center(
        child: Icon(Icons.article_outlined, color: colorScheme.onSurfaceVariant.withAlpha(123), size: _altImageHeight * 0.6),
      ),
    );
  }

  Stack _wrapInAnimationStack(ThemeData theme, Widget wrappedInAnimationWidget) {
    return Stack(
      alignment: Alignment.center,
      children: [
        wrappedInAnimationWidget,

        IgnorePointer(
          child: SendingAnimation(
            isSending: _isSendingLikeTx,
            mediaHeight: _getMediaHeight(),
            onEnd: () {
              // if (mounted) setState(() => _isSendingLikeTx = false);
            },
            theme: theme,
          ),
        ),

        IgnorePointer(
          child: LikeSucceededAnimation(
            isAnimating: _isAnimatingLikeConfirmation,
            mediaHeight: _getMediaHeight(),
            onEnd: () {
              if (mounted) setState(() => _isAnimatingLikeConfirmation = false);
            },
            theme: theme,
          ),
        ),
      ],
    );
  }

  double _getMediaHeight() {
    var post = widget.post;
    if (post.youtubeId != null && post.youtubeId!.isNotEmpty) {
      return _showYouTubePlayer ? 200.0 : 50.0;
    }

    if (post.videoUrl != null && post.videoUrl!.isNotEmpty ||
        post.imageUrl != null && post.imageUrl!.isNotEmpty ||
        post.ipfsCid != null && post.ipfsCid!.isNotEmpty ||
        (!post.hasMedia && post.hasUrlsInText)) {
      return 200.0;
    }

    return _altImageHeight * 2;
  }

  Future<void> _sendTipToCreator() async {
    if (!mounted) return;
    setState(() => _isSendingLikeTx = true);

    try {
      MemoAccountant account = ref.read(memoAccountantProvider);
      MemoAccountantResponse response = await account.publishLike(widget.post);
      if (!mounted) return;

      setState(() {
        _isSendingLikeTx = false;
      });

      if (response == MemoAccountantResponse.yes) {
        Future.delayed(Duration(milliseconds: 100), () {
          setState(() {
            _isAnimatingLikeConfirmation = true;
          });
        });
      } else {
        ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, response.message);
        showQrQuickDeposit(context);
        _logError("Accountant error during tip: ${response.name}", response);
      }
    } catch (e, s) {
      _logError("Error sending tip", e, s);
      if (mounted) {
        setState(() => _isSendingLikeTx = false);
        ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, "Failed to send tip. Please check your connection.");
      }
    }
  }

  void _onSelectTopic() {
    if (!mounted) return;
    setState(() {
      if (widget.post.topicId.startsWith("@")) widget.post.topicId = widget.post.topicId.substring(1);

      _hasSelectedTopic = !_hasSelectedTopic;
      if (_hasSelectedTopic) {
        _textEditController.text = _textEditController.text.replaceAll("@${widget.post.topicId}", "").trim();
        _textEditController.text = "@${widget.post.topicId} ${_textEditController.text}";
      } else {
        _textEditController.text = _textEditController.text.replaceAll("@${widget.post.topicId}", "").trim();
      }
      _showInput = _hasSelectedTopic || _selectedHashtags.any((selected) => selected);
      _evaluateShowSendButton(_textEditController.text);
    });
  }

  void _onInputText(String value) {
    if (!mounted) return;

    if (value.contains("@@")) _textEditController.text = value.replaceAll("@@", "@");

    if (value.contains("##")) _textEditController.text = value.replaceAll("##", "#");

    if (value.contains('\n')) {
      _textEditController.text = value.replaceAll("\n", "");
      if (_showSend) {
        _onSend();
      }
      return;
    }

    setState(() {
      final currentTextHashtags = MemoRegExp.extractHashtags(value);
      final currentTextHashtagsLower = currentTextHashtags.map((tag) => tag.toLowerCase()).toSet();

      for (int i = 0; i < _selectedHashtags.length && i < widget.post.tagIds.length; i++) {
        _selectedHashtags[i] = currentTextHashtagsLower.contains(widget.post.tagIds[i].toLowerCase());
      }
      _evaluateShowSendButton(value);
    });
  }

  void _onSelectHashtag(int index) {
    if (!mounted || index < 0 || index >= widget.post.tagIds.length) return;

    setState(() {
      _selectedHashtags[index] = !_selectedHashtags[index];
      final String currentText = _textEditController.text;
      String newText = currentText;

      for (int i = 0; i < widget.post.tagIds.length; i++) {
        final String hashtag = widget.post.tagIds[i];
        if (i >= MemoVerifier.maxHashtags) continue;
        if (!_selectedHashtags[i]) {
          final RegExp hashtagRegex = RegExp(r'(^|\s)' + RegExp.escape(hashtag) + r'(\s|$)', caseSensitive: false);
          newText = newText.replaceAll(hashtagRegex, ' ');
        }
      }

      newText = newText.replaceAll(RegExp(r'\s+'), ' ').trim();

      for (int i = 0; i < widget.post.tagIds.length; i++) {
        final String hashtag = widget.post.tagIds[i];
        if (i >= MemoVerifier.maxHashtags) continue;
        if (_selectedHashtags[i]) {
          final RegExp hashtagRegex = RegExp(r'(^|\s)' + RegExp.escape(hashtag) + r'(\s|$)', caseSensitive: false);
          if (!hashtagRegex.hasMatch(newText)) {
            newText = newText.isEmpty ? hashtag : '$newText $hashtag';
          }
        }
      }

      _textEditController.text = newText;
      _textEditController.selection = TextSelection.fromPosition(TextPosition(offset: _textEditController.text.length));

      _showInput = _hasSelectedTopic || _selectedHashtags.any((selected) => selected);
      _evaluateShowSendButton(_textEditController.text);
    });
  }

  void _evaluateShowSendButton(String currentText) {
    String textWithoutTopicNorTags = currentText;
    for (String tag in widget.post.tagIds) {
      textWithoutTopicNorTags = textWithoutTopicNorTags.replaceAll(tag, "").trim();
    }

    textWithoutTopicNorTags = textWithoutTopicNorTags.replaceAll(widget.post.topicId, "").trim();

    bool hasAnySelectedOrOtherHashtagsInText = _selectedHashtags.any((s) => s);
    if (!hasAnySelectedOrOtherHashtagsInText) {
      hasAnySelectedOrOtherHashtagsInText = MemoRegExp.extractHashtags(currentText).isNotEmpty;
    }

    final bool meetsLengthRequirement =
        textWithoutTopicNorTags.length >= MemoVerifier.minPostLength && currentText.length <= MemoVerifier.maxPostLength;

    final bool newShowSendState = _hasSelectedTopic ? meetsLengthRequirement : hasAnySelectedOrOtherHashtagsInText && meetsLengthRequirement;

    if (newShowSendState != _showSend) {
      setState(() {
        _showSend = newShowSendState;
      });

      // Trigger the callback when showSend changes from false to true
      if (_showSend && !_previousShowSendState && widget.onShowSendButton != null) {
        widget.onShowSendButton!();
      }
      _previousShowSendState = _showSend;
    }
  }

  void _onSend({bool isRepost = false}) async {
    if (isRepost && !widget.post.hasMedia) return;

    if (!mounted) return;
    final String textToSend = _textEditController.text.trim();
    final verifier = MemoVerifierDecorator(textToSend)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyNoTopicNorTag)
        .addValidator(InputValidators.verifyOffensiveWords);

    final result = verifier.getResult();
    if (result != MemoVerificationResponse.valid) {
      _showVerificationResponse(result, context, null);
      return;
    }

    if (isRepost) {
      ref.read(imgurUrlProvider.notifier).state = widget.post.imgurUrl ?? "";
      ref.read(youtubeVideoIdProvider.notifier).state = widget.post.youtubeId ?? "";
      ref.read(ipfsCidProvider.notifier).state = widget.post.ipfsCid ?? "";
      ref.read(odyseeUrlProvider.notifier).state = widget.post.videoUrl ?? "";
    }

    MemoModelPost postCopy = widget.post.copyWith(
      videoUrl: isRepost ? widget.post.videoUrl : "",
      imageUrl: isRepost ? widget.post.imageUrl : "",
      ipfsCid: isRepost ? widget.post.ipfsCid : "",
      imgurUrl: isRepost ? widget.post.imgurUrl : "",
      youtubeId: isRepost ? widget.post.youtubeId : "",
      text: textToSend,
      created: DateTime.now().toUtc().toString(),
      urls: MemoRegExp.extractUrls(textToSend),
      tagIds: MemoRegExp.extractHashtags(textToSend),
      topicId: MemoRegExp.extractTopics(textToSend).isNotEmpty ? MemoRegExp.extractTopics(textToSend).first : null,
    );

    postCopy.parseUrlsTagsTopicClearText();

    setState(() => _isSendingReplyTx = true);

    try {
      if (_hasSelectedTopic) {
        await _publishReplyTopic(postCopy);
      } else {
        await _publishReplyHashtags(postCopy);
      }
    } catch (e, s) {
      _logError("Error during reply publication", e, s);
      if (mounted) {
        ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, "Failed to publish reply $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingReplyTx = false);
      }
    }
  }

  void _onCancel() {
    if (!mounted) return;
    setState(() => _clearInputs());
  }

  void _clearAndConfetti() {
    if (!mounted) return;
    setState(() {
      MemoConfetti().launch(context);
      _clearInputs();
    });
  }

  void _clearInputs() {
    _textEditController.clear();
    _hasSelectedTopic = false;
    _showSend = false;
    _showInput = false;
    _initializeSelectedHashtags();
  }

  Future<void> _publishReplyTopic(MemoModelPost postCopy) async {
    bool? shouldPublish = await _showConfirmationActivity(postCopy);

    if (!mounted || shouldPublish != true) return;

    postCopy = ref.read(postCreationTranslationProvider).applyTranslationAndAppendMediaUrl(post: postCopy, ref: ref);
    postCopy.appendUrlsTagsTopicToText();

    var result = await ref.read(postRepositoryProvider).publishReplyTopic(postCopy);
    if (!mounted) return;
    _showVerificationResponse(result, context, postCopy);
  }

  Future<void> _publishReplyHashtags(MemoModelPost postCopy) async {
    bool? shouldPublish = await _showConfirmationActivity(postCopy);

    if (!mounted || shouldPublish != true) return;

    postCopy = ref.read(postCreationTranslationProvider).applyTranslationAndAppendMediaUrl(post: postCopy, ref: ref);
    postCopy.appendUrlsTagsTopicToText();

    var result = await ref.read(postRepositoryProvider).publishReplyHashtags(postCopy);
    if (!mounted) return;
    _showVerificationResponse(result, context, postCopy);
  }

  Future<bool?> _showConfirmationActivity(MemoModelPost postCopy) async {
    final bool? shouldPublish = await PublishConfirmationActivity.show(context, post: postCopy, isPostCreationNotReply: false);
    return shouldPublish;
  }

  void _showVerificationResponse(dynamic result, BuildContext ctx, MemoModelPost? postCopy) {
    String message = "";
    bool success = false;

    if (result is MemoVerificationResponse) {
      message = result.message;
      if (result == MemoVerificationResponse.valid) {
        success = true;
      }
    } else if (result is MemoAccountantResponse) {
      message = result.message;
      if (result == MemoAccountantResponse.yes) {
        success = true;
      } else {
        showQrQuickDeposit(ctx);
      }
    } else {
      message = "An unexpected error occurred during verification.";
      _logError("Unknown verification response type: ${result.runtimeType}", result);
    }

    if (success) {
      _clearAndConfetti();
      ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.success, message);
      ref.read(telegramBotPublisherProvider).publishPost(postText: postCopy!.text!);
    } else if (message.isNotEmpty && mounted) {
      ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, message);
    }
    ref.read(translationServiceProvider).resetTranslationStateAfterPublish();
  }

  void showQrQuickDeposit(BuildContext ctx) {
    showQrCodeDialog(ctx: ctx, user: ref.read(userProvider), memoOnly: true, withDelay: true);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    final creatorAsyncValue = ref.watch(postCreatorProvider(widget.post.creatorId));

    return creatorAsyncValue.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (creator) {
        widget.post.creator = creator;

        return _wrapInAnimationStack(
          theme,
          Card(
            color: theme.cardColor,
            margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 0.0),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 3),
                if (_isSendingLikeTx) AnimGrowFade(show: _isSendingLikeTx, child: LinearProgressIndicator(minHeight: 1.5)),
                PostCardHeader(post: widget.post, onLikePostTipCreator: _sendTipToCreator, index: widget.index),
                _buildPostMedia(theme, colorScheme, textTheme),
                PostCardFooter(
                  post: widget.post,
                  textEditController: _textEditController,
                  showInput: _showInput,
                  showSend: _showSend,
                  hasSelectedTopic: _hasSelectedTopic,
                  selectedHashtags: _selectedHashtags,
                  onInputText: _onInputText,
                  onSelectHashtag: _onSelectHashtag,
                  onSelectTopic: _onSelectTopic,
                  onSend: _onSend,
                  onCancel: _onCancel,
                  // maxTagsCounter: MemoVerifier.maxHashtags,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => SizedBox(),
      error: (error, stackTrace) => Center(child: Text('An error occurred: $error')),
    );
  }
}

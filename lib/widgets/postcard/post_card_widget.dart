// widgets/post_card_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/post_cache_repository.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/cached_unified_image_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:mahakka/widgets/postcard/post_card_footer.dart';
import 'package:mahakka/widgets/preview_url_widget.dart';
import 'package:mahakka/widgets/unified_video_player.dart';

import '../../memo/base/text_input_verifier.dart';
import '../../memo/memo_reg_exp.dart';
import '../../provider/telegram_bot_publisher.dart';
import '../../providers/post_creator_provider.dart';
import '../../url_utils.dart';
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
  const PostCard(this.post, {super.key});

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  static const double _altImageHeight = 50.0;
  static const int _maxTagsCounter = 3;
  static const int _minTextLength = 20;
  bool _isAnimatingLike = false;
  bool _isSendingTx = false;
  bool _showInput = false;
  bool _showSend = false;
  bool _hasSelectedTopic = false;
  late List<bool> _selectedHashtags;
  late TextEditingController _textEditController;
  bool hasRegisteredAsUser = false;
  bool _showYouTubePlayer = false;
  bool _isAnimatingYouTube = false;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _initializeSelectedHashtags();
    _showYouTubePlayer = false;
    _isAnimatingYouTube = false;
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  void _initializeSelectedHashtags() {
    final int count = widget.post.tagIds.length > _maxTagsCounter ? _maxTagsCounter : widget.post.tagIds.length;
    _selectedHashtags = List<bool>.filled(count, false);
  }

  Widget _buildVideoWidget(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          // borderRadius: BorderRadius.circular(12),
          border: Border(),
          // border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          // borderRadius: BorderRadius.circular(11.5),
          child: UnifiedVideoPlayer(
            type: VideoPlayerType.generic,
            aspectRatio: 16 / 9,
            autoPlay: false,
            videoUrl: widget.post.videoUrl!, // Pass the video URL
          ),
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
        decoration: BoxDecoration(
          color: colorScheme.surface,
          // borderRadius: BorderRadius.circular(12),
          // border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
          border: Border(),
        ),
        child: ClipRRect(
          // borderRadius: BorderRadius.circular(11.5),
          child: _showYouTubePlayer
              ? _buildYouTubePlayerWithOverlay(theme, colorScheme, textTheme)
              : _buildYouTubePlaceholder(theme, colorScheme, textTheme),
        ),
      ),
    );
  }

  // Add this variable to your state
  bool _showOverlayHint = true;

  // Add this method to hide overlay after delay
  void _hideOverlayAfterDelay() {
    Future.delayed(const Duration(seconds: 15), () {
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
        // YouTube Player
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
                    "Long press near video corner to minimize",
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

    // Priority: YouTube Video > Other Video > Image > IPFS > Link Preview > Fallback
    if (widget.post.youtubeId != null && widget.post.youtubeId!.isNotEmpty) {
      return _buildYouTubeWidget(theme, colorScheme, textTheme);
    } else if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      return _buildVideoWidget(theme, colorScheme, textTheme);
    } else if (imgUrl.isNotEmpty) {
      return CachedUnifiedImageWidget(
        imageUrl: imgUrl,
        sourceType: ImageSourceType.network,
        fitMode: ImageFitMode.contain,
        aspectRatio: 16 / 9,
        // borderRadius: BorderRadius.circular(12),
        border: Border(),
        // border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        backgroundColor: colorScheme.surface,
        showLoadingProgress: true,
      );
    } else if (widget.post.ipfsCid != null && widget.post.ipfsCid!.isNotEmpty) {
      return CachedUnifiedImageWidget(
        imageUrl: widget.post.ipfsCid!,
        sourceType: ImageSourceType.ipfs,
        fitMode: ImageFitMode.contain,
        aspectRatio: 16 / 9,
        border: Border(),
        // borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        backgroundColor: colorScheme.surface,
        showLoadingProgress: true,
        errorWidget: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, color: colorScheme.error, size: 36),
            const SizedBox(height: 8),
            Text("Error loading IPFS content", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
            const SizedBox(height: 8),
            Text("CID: ${widget.post.ipfsCid}", style: textTheme.bodySmall),
          ],
        ),
      );
    } else if ((!widget.post.hasMedia && widget.post.hasUrlsInText)) {
      final validUrl = UrlUtils.getFirstValidUrl(MemoRegExp.extractUrlsWithHttpsAlways(widget.post.text));
      if (validUrl != null) {
        return PreviewUrlWidget(url: validUrl);
      } else {
        return _buildFallbackWidget(colorScheme);
      }
    } else {
      return _buildFallbackWidget(colorScheme);
    }
  }

  void _toggleYouTubePlayer() {
    if (_isAnimatingYouTube) return; // Prevent rapid toggling during animation

    setState(() {
      _isAnimatingYouTube = true;
      _showYouTubePlayer = !_showYouTubePlayer;
      _showOverlayHint = true; // Reset overlay visibility when toggling
    });

    if (_showYouTubePlayer) {
      _hideOverlayAfterDelay(); // Start hiding timer
    }
    // Reset animation state after animation completes
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isAnimatingYouTube = false;
        });
      }
    });
  }

  // Save post with cached previews to both local cache and remote storage
  Future<void> _savePostWithCachedPreviews() async {
    try {
      final postService = ref.read(postServiceProvider);
      final cacheRepository = ref.read(postCacheRepositoryProvider);

      // Save to local cache
      await cacheRepository.savePosts([widget.post]);

      // Save to remote storage (Firestore)
      await postService.savePost(widget.post);

      print("Post cached previews updated successfully");
    } catch (e) {
      _logError("Failed to save post with cached previews", e);
    }
  }

  Widget _buildFallbackWidget(ColorScheme colorScheme) {
    return Container(
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
        SendingAnimation(
          isSending: _isSendingTx,
          mediaHeight: _getMediaHeight(),
          onEnd: () {
            if (mounted) setState(() => _isSendingTx = false);
          },
          theme: theme,
        ),
        LikeSucceededAnimation(
          isAnimating: _isAnimatingLike,
          mediaHeight: _getMediaHeight(),
          onEnd: () {
            if (mounted) setState(() => _isAnimatingLike = false);
          },
          theme: theme,
        ),
      ],
    );
  }

  double _getMediaHeight() {
    // For YouTube, use current height (animated between 50 and 200)
    var post = widget.post;
    if (post.youtubeId != null && post.youtubeId!.isNotEmpty) {
      return _showYouTubePlayer ? 200.0 : 50.0;
    }

    // For other media types, use fixed height
    if (post.videoUrl != null && post.videoUrl!.isNotEmpty ||
        post.imageUrl != null && post.imageUrl!.isNotEmpty ||
        post.ipfsCid != null && post.ipfsCid!.isNotEmpty ||
        (!post.hasMedia && post.hasUrlsInText)) {
      return 200.0;
    }

    return _altImageHeight * 2; // Height for fallback
  }

  Future<void> _sendTipToCreator() async {
    if (!mounted) return;
    setState(() => _isSendingTx = true);

    try {
      MemoAccountant account = ref.read(memoAccountantProvider);
      MemoAccountantResponse response = await account.publishLike(widget.post);
      if (!mounted) return;

      setState(() {
        _isSendingTx = false;
        if (response == MemoAccountantResponse.yes) {
          _isAnimatingLike = true;
        } else {
          showQrQuickDeposit(context);
          showSnackBar(type: SnackbarType.info, response.message, context);
          _logError("Accountant error during tip: ${response.name}", response);
        }
      });
    } catch (e, s) {
      _logError("Error sending tip", e, s);
      if (mounted) {
        setState(() => _isSendingTx = false);
        showSnackBar(type: SnackbarType.error, "Failed to send tip. Please check your connection.", context);
      }
    }
  }

  void _onSelectTopic() {
    if (!mounted) return;
    setState(() {
      _hasSelectedTopic = !_hasSelectedTopic;
      if (_hasSelectedTopic) {
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
    // Check if the text contains a newline character (Enter key was pressed)
    if (value.contains('\n')) {
      _textEditController.text = value.replaceAll("\n", "");
      // Enter key was pressed - trigger send action if conditions are met
      if (_showSend) {
        _onSend();
      }
      return; // Exit early since we handled the Enter key
    }
    setState(() {
      final currentTextHashtags = MemoRegExp.extractHashtags(value);
      for (int i = 0; i < _selectedHashtags.length && i < widget.post.tagIds.length; i++) {
        _selectedHashtags[i] = currentTextHashtags.contains(widget.post.tagIds[i]);
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
        if (!_selectedHashtags[i]) {
          final RegExp hashtagRegex = RegExp(r'(^|\s)' + RegExp.escape(hashtag) + r'(\s|$)', caseSensitive: false);
          newText = newText.replaceAll(hashtagRegex, ' ');
        }
      }

      newText = newText.replaceAll(RegExp(r'\s+'), ' ').trim();

      for (int i = 0; i < widget.post.tagIds.length; i++) {
        final String hashtag = widget.post.tagIds[i];
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
    String textWithoutKnownHashtags = currentText;
    for (String tag in widget.post.tagIds) {
      textWithoutKnownHashtags = textWithoutKnownHashtags.replaceAll(tag, "").trim();
    }

    bool hasAnySelectedOrOtherHashtagsInText = _selectedHashtags.any((s) => s);
    if (!hasAnySelectedOrOtherHashtagsInText) {
      hasAnySelectedOrOtherHashtagsInText = MemoRegExp.extractHashtags(currentText).isNotEmpty;
    }

    final bool meetsLengthRequirement = textWithoutKnownHashtags.length >= _minTextLength && currentText.length <= MemoVerifier.maxPostLength;

    if (_hasSelectedTopic) {
      _showSend = meetsLengthRequirement;
    } else {
      _showSend = hasAnySelectedOrOtherHashtagsInText && meetsLengthRequirement;
    }
  }

  void _onSend() async {
    if (!mounted) return;
    final String textToSend = _textEditController.text.trim();
    final verifier = MemoVerifierDecorator(textToSend)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyNoTopicNorTag)
        .addValidator(InputValidators.verifyOffensiveWords);

    final result = verifier.getResult();
    if (result != MemoVerificationResponse.valid) {
      _showVerificationResponse(result, context);
      return;
    }

    MemoModelPost postCopy = widget.post.copyWith(
      videoUrl: "",
      imageUrl: "",
      ipfsCid: "",
      imgurUrl: "",
      youtubeId: "",
      text: textToSend,
      tagIds: MemoRegExp.extractHashtags(textToSend),
      topicId: MemoRegExp.extractTopics(textToSend).isNotEmpty ? MemoRegExp.extractTopics(textToSend).first : null,
    );

    setState(() => _isSendingTx = true);

    try {
      if (_hasSelectedTopic) {
        await _publishReplyTopic(postCopy);
      } else {
        await _publishReplyHashtags(postCopy);
      }
    } catch (e, s) {
      _logError("Error during reply publication", e, s);
      if (mounted) {
        showSnackBar(type: SnackbarType.error, "Failed to publish reply $e", context);
      }
    } finally {
      // ref.read(userProvider)!.temporaryTipReceiver = null;
      // ref.read(userProvider)!.temporaryTipAmount = null;
      if (mounted) {
        setState(() => _isSendingTx = false);
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

    var result = await ref.read(postRepositoryProvider).publishReplyTopic(postCopy);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  Future<void> _publishReplyHashtags(MemoModelPost postCopy) async {
    bool? shouldPublish = await _showConfirmationActivity(postCopy);

    if (!mounted || shouldPublish != true) return;

    var result = await ref.read(postRepositoryProvider).publishReplyHashtags(postCopy);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  Future<bool?> _showConfirmationActivity(MemoModelPost postCopy) async {
    // Show confirmation dialog
    final bool? shouldPublish = await PublishConfirmationActivity.show(context, post: postCopy);
    return shouldPublish;
  }

  void _showVerificationResponse(dynamic result, BuildContext ctx) {
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
      showSnackBar(type: SnackbarType.success, message, ctx);
      ref.read(telegramBotPublisherProvider).publishPost(postText: widget.post.text!);
    } else if (message.isNotEmpty && mounted) {
      showSnackBar(type: SnackbarType.error, message, ctx);
    }
  }

  void showQrQuickDeposit(BuildContext ctx) {
    showQrCodeDialog(context: ctx, theme: Theme.of(context), user: ref.read(userProvider), memoOnly: true);
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
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 5),
                PostCardHeader(post: widget.post, onLikePostTipCreator: _sendTipToCreator),
                // Media section that handles all types including link preview
                SizedBox(height: 7),
                _buildPostMedia(theme, colorScheme, textTheme),
                SizedBox(height: 5),
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
                  maxTagsCounter: _maxTagsCounter,
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

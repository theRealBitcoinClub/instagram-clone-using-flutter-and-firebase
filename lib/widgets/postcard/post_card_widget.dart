import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:mahakka/widgets/unified_video_player.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../../memo/base/text_input_verifier.dart';
import '../../memo/memo_reg_exp.dart';
import '../../providers/post_creator_provider.dart';
import 'post_card_footer.dart';
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

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _initializeSelectedHashtags();
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

  // NEW: Build media widget based on available media types
  Widget _buildPostMedia(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    // Priority: Video > Image > IPFS > Fallback
    if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      return _buildVideoWidget(theme, colorScheme, textTheme);
    } else if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) {
      return _buildImageWidget(theme, colorScheme, textTheme);
    } else if (widget.post.ipfsCid != null && widget.post.ipfsCid!.isNotEmpty) {
      return _buildIpfsWidget(theme, colorScheme, textTheme);
    } else {
      return _buildFallbackWidget(theme, colorScheme);
    }
  }

  // NEW: Build video widget for Odysee videos
  Widget _buildVideoWidget(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11.5),
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

  // NEW: Build image widget for extracted image URLs
  Widget _buildImageWidget(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return GestureDetector(
      onDoubleTap: _isSendingTx ? null : _sendTipToCreator,
      child: ZoomOverlay(
        modalBarrierColor: theme.colorScheme.scrim.withOpacity(0.3),
        minScale: 0.5,
        maxScale: 3.0,
        twoTouchOnly: true,
        animationDuration: const Duration(milliseconds: 200),
        animationCurve: Curves.easeOut,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11.5),
              child: Image.network(
                widget.post.imageUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 36),
                        const SizedBox(height: 8),
                        Text("Error loading image", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // NEW: Build IPFS widget for IPFS content
  Widget _buildIpfsWidget(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    final ipfsUrl = 'https://free-bch.fullstack.cash/ipfs/view/${widget.post.ipfsCid}';

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11.5),
          child: Image.network(
            ipfsUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Column(
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
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // NEW: Fallback widget when no media is available
  Widget _buildFallbackWidget(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: _altImageHeight,
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Icon(Icons.article_outlined, color: colorScheme.onSurfaceVariant.withOpacity(0.7), size: _altImageHeight * 0.6),
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

  // NEW: Helper to determine media height based on content
  double _getMediaHeight() {
    if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty ||
        widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty ||
        widget.post.ipfsCid != null && widget.post.ipfsCid!.isNotEmpty) {
      return 200.0; // Height for media content
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
          showSnackBar(response.name, context);
          _logError("Accountant error during tip: ${response.name}", response);
        }
      });
    } catch (e, s) {
      _logError("Error sending tip", e, s);
      if (mounted) {
        setState(() => _isSendingTx = false);
        showSnackBar("Failed to send tip. Please check your connection.", context);
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

  void _onSend() {
    if (!mounted) return;
    final String textToSend = _textEditController.text.trim();
    final verifier = MemoVerifierDecorator(textToSend)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyOffensiveWords);

    final result = verifier.getResult();
    if (result != MemoVerificationResponse.valid) {
      _showVerificationResponse(result, context);
      return;
    }

    if (_hasSelectedTopic) {
      _publishReplyTopic(textToSend);
    } else {
      _publishReplyHashtags(textToSend);
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

  Future<void> _publishReplyTopic(String text) async {
    var result = await ref.read(postRepositoryProvider).publishReplyTopic(widget.post, text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  Future<void> _publishReplyHashtags(String text) async {
    var result = await ref.read(postRepositoryProvider).publishReplyHashtags(widget.post, text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
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
        showQrCodeDialog(context: ctx, theme: Theme.of(context), user: ref.read(userProvider));
      }
    } else {
      message = "An unexpected error occurred during verification.";
      _logError("Unknown verification response type: ${result.runtimeType}", result);
    }

    if (success) {
      _clearAndConfetti();
    } else if (message.isNotEmpty && mounted) {
      showSnackBar(message, ctx);
    }
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
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PostCardHeader(post: widget.post, onLikePostTipCreator: _sendTipToCreator),
                // NEW: Media section that handles all three types
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

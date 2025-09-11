import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/repositories/post_repository.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/memo_confetti.dart'; // Ensure path is correct
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../../memo/base/text_input_verifier.dart';
import '../../memo/memo_reg_exp.dart';
import '../../providers/post_creator_provider.dart';
import 'post_card_footer.dart';
// Import the new split widget files
import 'post_card_header.dart';
import 'postcard_animations.dart';

// Logging helper (can be moved)
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: PostCardWidget - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

// Changed to ConsumerStatefulWidget
class PostCard extends ConsumerStatefulWidget {
  final MemoModelPost post;

  // NavBarCallback removed from constructor
  const PostCard(this.post, {super.key});

  @override
  ConsumerState<PostCard> createState() => _PostCardState(); // Changed
}

// Changed to ConsumerState
class _PostCardState extends ConsumerState<PostCard> {
  // Constants
  static const double _altImageHeight = 50.0;
  static const int _maxTagsCounter = 3; // This is now used by PostCardFooter
  static const int _minTextLength = 20;
  bool _isAnimatingLike = false;
  bool _isSendingTx = false;
  bool _showInput = false;
  bool _showSend = false;
  bool _hasSelectedTopic = false;
  late List<bool> _selectedHashtags;
  // Controllers
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

  Widget _buildPostMedia(ThemeData theme) {
    if (widget.post.imgurUrl != null && widget.post.imgurUrl!.isNotEmpty) {
      return Image.network(
        widget.post.imgurUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // _logError("Failed to load Imgur image: ${widget.post.imgurUrl}", error, stackTrace);
          return Container(
            height: _altImageHeight * 2,
            color: theme.colorScheme.surfaceVariant,
            child: Center(child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant, size: 30)),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: _altImageHeight * 2,
            color: theme.colorScheme.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.0,
              ),
            ),
          );
        },
      );
    } else {
      return Container(
        height: _altImageHeight,
        color: theme.colorScheme.surfaceVariant,
        child: Center(
          child: Icon(Icons.article_outlined, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), size: _altImageHeight * 0.6),
        ),
      );
    }
  }

  Stack _wrapInAnimationStack(ThemeData theme, wrappedInAnimationWidget) {
    return Stack(
      alignment: Alignment.center,
      children: [
        wrappedInAnimationWidget,
        SendingAnimation(
          isSending: _isSendingTx,
          mediaHeight: widget.post.imgurUrl == null ? _altImageHeight * 2 : 150.0,
          onEnd: () {
            if (mounted) setState(() => _isSendingTx = false);
          },
          theme: theme,
        ),
        LikeSucceededAnimation(
          isAnimating: _isAnimatingLike,
          mediaHeight: widget.post.imgurUrl == null ? _altImageHeight * 2 : 150.0,
          onEnd: () {
            if (mounted) setState(() => _isAnimatingLike = false);
          },
          theme: theme,
        ),
      ],
    );
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
          showSnackBar(response.name, context); // Or a more user-friendly message
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
      // 1. Toggle the selected state
      _selectedHashtags[index] = !_selectedHashtags[index];

      final String currentText = _textEditController.text;

      // 2. Process all hashtags to build the new text
      String newText = currentText;

      // First, remove all hashtags that are no longer selected
      for (int i = 0; i < widget.post.tagIds.length; i++) {
        final String hashtag = widget.post.tagIds[i];
        if (!_selectedHashtags[i]) {
          // Remove this hashtag if it exists
          final RegExp hashtagRegex = RegExp(r'(^|\s)' + RegExp.escape(hashtag) + r'(\s|$)', caseSensitive: false);
          newText = newText.replaceAll(hashtagRegex, ' ');
        }
      }

      // Clean up extra spaces
      newText = newText.replaceAll(RegExp(r'\s+'), ' ').trim();

      // Then, add all selected hashtags that aren't already present
      for (int i = 0; i < widget.post.tagIds.length; i++) {
        final String hashtag = widget.post.tagIds[i];
        if (_selectedHashtags[i]) {
          // Check if the hashtag is already in the text
          final RegExp hashtagRegex = RegExp(r'(^|\s)' + RegExp.escape(hashtag) + r'(\s|$)', caseSensitive: false);

          if (!hashtagRegex.hasMatch(newText)) {
            // Add the hashtag to the end
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

  // Update the _evaluateShowSendButton method
  void _evaluateShowSendButton(String currentText) {
    String textWithoutKnownHashtags = currentText;
    for (String tag in widget.post.tagIds) {
      textWithoutKnownHashtags = textWithoutKnownHashtags.replaceAll(tag, "").trim();
    }

    bool hasAnySelectedOrOtherHashtagsInText = _selectedHashtags.any((s) => s);
    if (!hasAnySelectedOrOtherHashtagsInText) {
      hasAnySelectedOrOtherHashtagsInText = MemoRegExp.extractHashtags(currentText).isNotEmpty;
    }

    final bool meetsLengthRequirement =
        textWithoutKnownHashtags.length >= _minTextLength && currentText.length <= MemoVerifier.maxPostLength; // Add character limit check

    if (_hasSelectedTopic) {
      _showSend = meetsLengthRequirement;
    } else {
      _showSend = hasAnySelectedOrOtherHashtagsInText && meetsLengthRequirement;
    }
  }

  // void _evaluateShowSendButton(String currentText) {
  //   String textWithoutKnownHashtags = currentText;
  //   for (String tag in widget.post.tagIds) {
  //     textWithoutKnownHashtags = textWithoutKnownHashtags.replaceAll(tag, "").trim();
  //   }
  //   bool hasAnySelectedOrOtherHashtagsInText = _selectedHashtags.any((s) => s);
  //   if (!hasAnySelectedOrOtherHashtagsInText) {
  //     hasAnySelectedOrOtherHashtagsInText = MemoScraperUtil.extractHashtags(currentText).isNotEmpty;
  //   }
  //
  //   if (_hasSelectedTopic) {
  //     _showSend = textWithoutKnownHashtags.length >= _minTextLength;
  //   } else {
  //     _showSend = hasAnySelectedOrOtherHashtagsInText && textWithoutKnownHashtags.length >= _minTextLength;
  //   }
  // }

  void _onSend() {
    if (!mounted) return;
    final String textToSend = _textEditController.text.trim();
    // Use the new verifier class
    final verifier = MemoVerifierDecorator(textToSend)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyOffensiveWords);

    final result = verifier.getResult();

    // Pass the verification result to the response handler
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
      MemoConfetti().launch(context); // Ensure MemoConfetti is correctly implemented
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
    // ref is available here because this is ConsumerState
    final ThemeData theme = Theme.of(context);

    // Watch the provider to get the creator data.
    // Riverpod handles the loading, error, and data states automatically.
    final creatorAsyncValue = ref.watch(postCreatorProvider(widget.post.creatorId));

    return creatorAsyncValue.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (creator) {
        // We have the creator data! Update the post model.
        widget.post.creator = creator;

        return _wrapInAnimationStack(
          theme,
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PostCardHeader(
                  post: widget.post,
                  onLikePostTipCreator: _sendTipToCreator,
                  // hasRegisteredAsUser: hasRegisteredAsUser,
                  // creator: creator == null ? wid,
                  // NavBarCallback removed
                ),
                widget.post.imgurUrl != null && widget.post.imgurUrl!.isNotEmpty
                    ? GestureDetector(
                        onDoubleTap: _isSendingTx ? null : _sendTipToCreator,
                        child: ZoomOverlay(
                          modalBarrierColor: theme.colorScheme.scrim.withOpacity(0.3),
                          minScale: 0.5,
                          maxScale: 3.0,
                          twoTouchOnly: true,
                          animationDuration: const Duration(milliseconds: 200),
                          animationCurve: Curves.easeOut,
                          child: _buildPostMedia(theme),
                        ),
                      )
                    : SizedBox(),
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
                  maxTagsCounter: _maxTagsCounter, // Pass the constant
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        // This part runs while the data is loading.
        return SizedBox();
        // return Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        // This part runs if an error occurs.
        return Center(child: Text('An error occurred: $error'));
      },
    );
  }
}

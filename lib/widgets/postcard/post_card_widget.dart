import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/scraper/memo_creator_service.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/memo_confetti.dart'; // Ensure path is correct
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import 'post_card_footer.dart';
// Import the new split widget files
import 'post_card_header.dart';
import 'postcard_animations.dart';

// Import Riverpod providers if needed for _loadUser or other logic.
// For now, _loadUser uses MemoModelUser.getUser() which might be static.
// If MemoModelUser.getUser() itself becomes a Riverpod provider, that would change.

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
  // _animationDuration is used by postcard_animations.dart

  // State variables
  MemoModelUser? _user; // This could potentially come from a Riverpod userProvider
  bool _isAnimatingLike = false;
  bool _isSendingTx = false;
  bool _showInput = false;
  bool _showSend = false;
  bool _hasSelectedTopic = false;
  late List<bool> _selectedHashtags;
  // String? _activeVideoId; // YouTube player logic removed for brevity

  // Controllers
  late TextEditingController _textEditController;

  // NavBarCallback removed
  // _PostCardState(); // Default constructor or pass ref if needed by _loadUser

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _initializeSelectedHashtags();
    _loadUser(); // Consider if this should use ref.read(userProvider) if _user becomes Riverpod state
    _refreshCreator();
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  Future<void> _refreshCreator() async {
    if (_creator() == null && widget.post.creatorId.isNotEmpty) {
      widget.post.creator = MemoModelCreator(id: widget.post.creatorId);
    }
    // if (widget.post.creator != null) {
    if (_creator()!.name.isEmpty) {
      widget.post.creator = await _creator()!.refreshCreatorFirebase();

      if (_creator()!.profileImageAvatar().isEmpty) {
        refreshAvatarThenSetState();
      }

      if (_creator()!.name.isEmpty) {
        _creator()!.name = _creator()!.profileIdShort;

        widget.post.creator = await MemoCreatorService().fetchCreatorDetails(_creator()!);
      }
    }
    // }
    // if (widget.post.topic == null && widget.post.topicId.isNotEmpty) {
    //   widget.post.loadTopic();
    // }
    if (mounted) setState(() {});
  }

  MemoModelCreator? _creator() => widget.post.creator;

  void _initializeSelectedHashtags() {
    final int count = widget.post.tagIds.length > _maxTagsCounter ? _maxTagsCounter : widget.post.tagIds.length;
    _selectedHashtags = List<bool>.filled(count, false);
  }

  Future<void> _loadUser() async {
    // If you have a userProvider in Riverpod for the logged-in user:
    // _user = ref.read(userProvider); // Example: Assumes userProvider gives MemoModelUser?
    // If not, and MemoModelUser.getUser() is static and okay:
    _user = await MemoModelUser.getUser();
    if (mounted) {
      // setState(() {}); // Only if UI directly depends on _user synchronously
    }
  }

  Widget _buildPostMedia(ThemeData theme) {
    if (widget.post.imgurUrl != null && widget.post.imgurUrl!.isNotEmpty) {
      return Image.network(
        widget.post.imgurUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          _logError("Failed to load Imgur image: ${widget.post.imgurUrl}", error, stackTrace);
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
          mediaHeight: widget.post.imgurUrl == null ? _altImageHeight : 150.0,
          onEnd: () {
            if (mounted) setState(() => _isSendingTx = false);
          },
          theme: theme,
        ),
        LikeSucceededAnimation(
          isAnimating: _isAnimatingLike,
          mediaHeight: widget.post.imgurUrl == null ? _altImageHeight : 150.0,
          onEnd: () {
            if (mounted) setState(() => _isAnimatingLike = false);
          },
          theme: theme,
        ),
      ],
    );
  }

  Future<void> _sendTipToCreator() async {
    if (_user == null) {
      showSnackBar("User data not loaded yet. Please try again.", context);
      _loadUser(); // Attempt to reload
      return;
    }
    if (!mounted) return;
    setState(() => _isSendingTx = true);

    try {
      MemoAccountantResponse response = await MemoAccountant(_user!).publishLike(widget.post);
      if (!mounted) return;

      setState(() {
        _isSendingTx = false;
        if (response == MemoAccountantResponse.yes) {
          _isAnimatingLike = true;
          // MemoConfetti().launch(context); // Optional
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
      final currentTextHashtags = MemoScraperUtil.extractHashtags(value);
      for (int i = 0; i < _selectedHashtags.length && i < widget.post.tagIds.length; i++) {
        _selectedHashtags[i] = currentTextHashtags.contains(widget.post.tagIds[i]);
      }
      _evaluateShowSendButton(value);
    });
  }

  void _onSelectHashtag(int index) {
    if (!mounted || index < 0 || index >= _selectedHashtags.length) return;
    setState(() {
      _selectedHashtags[index] = !_selectedHashtags[index];
      String newText = _textEditController.text;
      for (String tag in widget.post.tagIds) {
        newText = newText.replaceAll(tag, "").replaceAll("  ", " ").trim();
      }
      for (int i = 0; i < _selectedHashtags.length && i < widget.post.tagIds.length; i++) {
        if (_selectedHashtags[i]) {
          newText = "$newText ${widget.post.tagIds[i]}".trim();
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
      hasAnySelectedOrOtherHashtagsInText = MemoScraperUtil.extractHashtags(currentText).isNotEmpty;
    }

    if (_hasSelectedTopic) {
      _showSend = textWithoutKnownHashtags.length >= _minTextLength;
    } else {
      _showSend = hasAnySelectedOrOtherHashtagsInText && textWithoutKnownHashtags.length >= _minTextLength;
    }
  }

  void _onSend() {
    if (!mounted) return;
    final String textToSend = _textEditController.text.trim();
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
    var result = await widget.post.publishReplyTopic(text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  Future<void> _publishReplyHashtags(String text) async {
    var result = await widget.post.publishReplyHashtags(text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  void _showVerificationResponse(dynamic result, BuildContext ctx) {
    String message = "";
    bool success = false;

    if (result is MemoVerificationResponse) {
      switch (result) {
        case MemoVerificationResponse.minWordCountNotReached:
          message = "Write more words";
          break;
        case MemoVerificationResponse.email:
          message = "Email not allowed";
          break;
        case MemoVerificationResponse.moreThanOneTopic:
          message = "Only one topic allowed";
          break;
        case MemoVerificationResponse.moreThanThreeTags:
          message = "Too many tags";
          break;
        case MemoVerificationResponse.urlThatsNotTgNorImageNorVideo:
          message = "Invalid URL.";
          break;
        case MemoVerificationResponse.offensiveWords:
          message = "Offensive words detected.";
          break;
        case MemoVerificationResponse.tooLong:
          message = "Text is too long.";
          break;
        case MemoVerificationResponse.tooShort:
          message = "Too short. Tags count towards length.";
          break;
        case MemoVerificationResponse.zeroTags:
          message = "Add at least one visible tag.";
          break;
        default:
          message = "Verification issue: ${result.name}";
      }
    } else if (result is MemoAccountantResponse) {
      switch (result) {
        case MemoAccountantResponse.lowBalance:
          message = "Insufficient balance.";
          break;
        case MemoAccountantResponse.yes:
          success = true;
          break;
        case MemoAccountantResponse.noUtxo:
          message = "Transaction error (no UTXO).";
          break;
        case MemoAccountantResponse.dust:
          message = "Transaction error (dust).";
          break;
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

    // if (widget.post.creator == null) {
    //   _refreshCreator(); // Attempt to refresh if creator is null
    //   return const SizedBox(
    //     height: 100, // Placeholder height for loading state
    //     child: Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
    //   );
    // }
    if (_creator()!.profileImageAvatar().isEmpty) {
      refreshAvatarThenSetState();
    }

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
              onOptionsMenuPressed: _sendTipToCreator,
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
  }

  void refreshAvatarThenSetState() async {
    await _creator()!.refreshAvatar();
    if (context.mounted) setState(() {});
  }
}

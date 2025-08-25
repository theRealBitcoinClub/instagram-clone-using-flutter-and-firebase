import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memobase/memo_accountant.dart';
import 'package:instagram_clone1/memobase/memo_verifier.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_utils.dart';
import 'package:instagram_clone1/utils/imgur_utils.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:instagram_clone1/widgets/like_animtion.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../memomodel/memo_model_post.dart';
import 'memo_confetti.dart'; // Assuming this exists

// Basic logging placeholder
void _logInfo(String message) => print('INFO: PostCard - $message');
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: PostCard - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class PostCard extends StatefulWidget {
  final MemoModelPost post;

  const PostCard(this.post, {Key? key}) : super(key: key); // Use Key? key

  @override
  State<PostCard> createState() => _PostCardState(); // No need to pass post here
}

class _PostCardState extends State<PostCard> {
  // Constants
  static const double _altImageHeight = 50.0;
  static const int _maxTagsCounter = 3;
  static const int _minTextLength = 20;
  static const Duration _animationDuration = Duration(milliseconds: 500);

  // State variables
  MemoModelUser? _user;
  bool _isAnimatingLike = false;
  bool _isSendingTx = false;
  bool _showInput = false;
  bool _showSend = false;
  bool _hasSelectedTopic = false;
  late List<bool> _selectedHashtags; // Initialize in initState

  // Controllers
  late TextEditingController _textEditController;
  YoutubePlayerController? _ytController; // Nullable, initialize if needed

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _initializeSelectedHashtags();
    _loadUser();

    if (widget.post.youtubeId != null && widget.post.youtubeId!.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.post.youtubeId!,
        flags: const YoutubePlayerFlags(
          // Consider making some flags configurable or based on post properties
          hideThumbnail: true, // Or false if you want initial thumbnail
          hideControls: true, // Or false
          mute: false, // Or true
          autoPlay: false,
        ),
      );
    }
  }

  void _initializeSelectedHashtags() {
    // Initialize based on the actual number of hashtags for the post, up to maxTagsCounter
    final int count = widget.post.hashtags.length > _maxTagsCounter ? _maxTagsCounter : widget.post.hashtags.length;
    _selectedHashtags = List<bool>.filled(count, false);
  }

  Future<void> _loadUser() async {
    // No setState needed here if user is only used in async methods
    _user = await MemoModelUser.getUser();
    // If you needed to update UI based on user loaded, then:
    // if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textEditController.dispose();
    _ytController?.dispose(); // Dispose if not null
    super.dispose();
  }

  // --- UI Builder Methods ---

  Widget _buildPostMedia() {
    if (widget.post.youtubeId != null && _ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        // onReady: () { _logInfo('Player is ready.'); },
      );
    } else if (widget.post.imgurUrl != null) {
      return Image.network(
        // Use Image.network directly for better const usage potential
        widget.post.imgurUrl!,
        fit: BoxFit.cover,
        errorBuilder: ImgurUtils.errorLoadImage, // Pass function reference
        loadingBuilder: ImgurUtils.loadingImage, // Pass function reference
      );
    } else {
      // Placeholder for text-only posts or posts without media
      return Container(color: Colors.greenAccent, height: _altImageHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure creator is not null before building parts that depend on it
    if (widget.post.creator == null) {
      _logError("Post creator is null, cannot build PostCard for post ID: ${widget.post.txHash}");
      return const SizedBox.shrink(child: Text("Error: Post data incomplete")); // Or some error placeholder
    }

    return Card(
      // Wrap in Card for common styling and elevation
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2.0,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important for Column in a list
        children: [
          _PostCardHeader(post: widget.post, onOptionsMenuPressed: _showPostOptionsMenu),
          GestureDetector(
            onDoubleTap: _sendTipToCreator,
            child: ZoomOverlay(
              modalBarrierColor: Colors.black12,
              minScale: 0.5,
              maxScale: 3.0,
              twoTouchOnly: true,
              animationDuration: const Duration(milliseconds: 300),
              animationCurve: Curves.fastOutSlowIn,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPostMedia(),
                  _SendingAnimation(
                    isSending: _isSendingTx,
                    mediaHeight: widget.post.imgurUrl == null ? _altImageHeight : 150.0, // Example size
                    onEnd: () {
                      if (mounted) setState(() => _isSendingTx = false);
                    },
                  ),
                  _LikeSucceededAnimation(
                    isAnimating: _isAnimatingLike,
                    mediaHeight: widget.post.imgurUrl == null ? _altImageHeight : 150.0,
                    onEnd: () {
                      if (mounted) setState(() => _isAnimatingLike = false);
                    },
                  ),
                ],
              ),
            ),
          ),
          _PostCardFooter(
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
          ),
        ],
      ),
    );
  }

  // --- Interaction Logic Methods ---

  Future<void> _sendTipToCreator() async {
    if (_user == null) {
      showSnackBar("User data not loaded yet.", context);
      _loadUser(); // Attempt to reload user
      return;
    }
    if (!mounted) return;
    setState(() => _isSendingTx = true);

    try {
      MemoAccountantResponse response = await MemoAccountant(_user!).publishLike(widget.post);
      if (!mounted) return;

      // Single setState for UI changes post-API call
      setState(() {
        _isSendingTx = false; // Always set sending to false
        switch (response) {
          case MemoAccountantResponse.yes:
            _isAnimatingLike = true; // Trigger success animation
            // MemoConfetti().launch(context); // Consider if confetti should be here or part of animation
            break;
          case MemoAccountantResponse.lowBalance:
            showSnackBar("Low balance", context);
            break;
          case MemoAccountantResponse.noUtxo:
          case MemoAccountantResponse.dust:
            _logError("Accountant error: ${response.name}", response);
            showSnackBar("Transaction error. Please try again later.", context);
            break;
          // default: // Handle any other cases if MemoAccountantResponse enum grows
          //   showSnackBar("An unexpected error occurred.", context);
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

  void _showPostOptionsMenu() {
    // This method was building UI directly, which is fine for showDialog.
    // No major performance changes here, but ensure the dialog content is efficient.
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shrinkWrap: true,
          children:
              ["Delete Post", "Ban User", "Report"] // Could be constants
                  .map(
                    (e) => InkWell(
                      onTap: () {
                        // TODO: Implement actual actions
                        _logInfo("Option selected: $e");
                        showSnackBar("Option '$e' tapped (Not implemented)", dialogCtx);
                        Navigator.pop(dialogCtx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Center(child: Text(e)),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  void _onSelectTopic() {
    if (!mounted) return;
    setState(() {
      _hasSelectedTopic = !_hasSelectedTopic;
      _showInput = _hasSelectedTopic || _selectedHashtags.any((selected) => selected);
      // Re-evaluate showSend based on current text and selections
      _evaluateShowSendButton(_textEditController.text);
    });
  }

  void _onInputText(String value) {
    if (!mounted) return;
    setState(() {
      // Update selectedHashtags based on text input
      final currentTextHashtags = MemoScraperUtil.extractHashtags(value);
      for (int i = 0; i < _selectedHashtags.length && i < widget.post.hashtags.length; i++) {
        _selectedHashtags[i] = currentTextHashtags.contains(widget.post.hashtags[i]);
      }
      _evaluateShowSendButton(value);
    });
  }

  void _onSelectHashtag(int index) {
    if (!mounted || index < 0 || index >= _selectedHashtags.length) return;

    setState(() {
      _selectedHashtags[index] = !_selectedHashtags[index];

      // Rebuild text input based on selected hashtags
      String newText = _textEditController.text;
      // Remove all post hashtags first to avoid duplicates or incorrect removal
      for (String tag in widget.post.hashtags) {
        newText = newText.replaceAll(tag, "").replaceAll("  ", " ").trim();
      }

      // Add back only the currently selected ones
      for (int i = 0; i < _selectedHashtags.length && i < widget.post.hashtags.length; i++) {
        if (_selectedHashtags[i]) {
          newText = "$newText ${widget.post.hashtags[i]}".trim();
        }
      }
      _textEditController.text = newText;
      // Move cursor to end
      _textEditController.selection = TextSelection.fromPosition(TextPosition(offset: _textEditController.text.length));

      _showInput = _hasSelectedTopic || _selectedHashtags.any((selected) => selected);
      _evaluateShowSendButton(_textEditController.text);
    });
  }

  void _evaluateShowSendButton(String currentText) {
    // Remove all known post hashtags from currentText to get textWithoutHashtags
    String textWithoutKnownHashtags = currentText;
    for (String tag in widget.post.hashtags) {
      textWithoutKnownHashtags = textWithoutKnownHashtags.replaceAll(tag, "").trim();
    }
    // Check if any of the *actually selected* hashtags are present in the text,
    // OR if any *other* hashtags are present (not from the suggested list)
    bool hasAnySelectedOrOtherHashtagsInText = _selectedHashtags.any((s) => s); // if any predefined tag is selected
    if (!hasAnySelectedOrOtherHashtagsInText) {
      // check if user typed a new hashtag not from suggestions
      hasAnySelectedOrOtherHashtagsInText = MemoScraperUtil.extractHashtags(currentText).isNotEmpty;
    }

    if (_hasSelectedTopic) {
      // Replying to a topic
      _showSend = textWithoutKnownHashtags.length >= _minTextLength;
    } else {
      // Posting with hashtags (not a topic reply)
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
    setState(() {
      _clearInputs();
    });
  }

  Future<void> _publishReplyTopic(String text) async {
    // Consider adding a sending indicator specific to this action if it's long
    var result = await widget.post.publishReplyTopic(text); // Assume widget.post is correct
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  Future<void> _publishReplyHashtags(String text) async {
    var result = await widget.post.publishReplyHashtags(text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  void _showVerificationResponse(dynamic result, BuildContext ctx) {
    // Made ctx non-nullable
    // Ensure result is one of the expected types.
    // This switch is extensive. Ensure all cases are handled correctly.
    String message = "";
    bool success = false;

    if (result is MemoVerificationResponse) {
      switch (result) {
        case MemoVerificationResponse.minWordCountNotReached:
          message = "Write more words";
          break;
        // ... (all your other MemoVerificationResponse cases) ...
        case MemoVerificationResponse.tooShort:
          message = "Too short. Tags count towards length.";
          break;
        case MemoVerificationResponse.zeroTags:
          message = "Add at least one visible tag.";
          break;
        default:
          message = "Verification issue: ${result.name}"; // Generic for unhandled enum values
      }
    } else if (result is MemoAccountantResponse) {
      switch (result) {
        case MemoAccountantResponse.lowBalance:
          message = "You broke dude";
          break;
        case MemoAccountantResponse.yes:
          success = true;
          // Confetti and clear handled separately
          break;
        // ... (other MemoAccountantResponse cases like noUtxo, dust if they can reach here) ...
        default:
          message = "Account issue: ${result.name}";
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

  void _clearAndConfetti() {
    if (!mounted) return;
    setState(() {
      MemoConfetti().launch(context); // Assuming MemoConfetti is correctly set up
      _clearInputs(); // Reset selected hashtags
    });
    // showSnackBar("Success!", context); // Optional success message
  }

  void _clearInputs() {
    _textEditController.clear();
    _hasSelectedTopic = false;
    _showSend = false;
    _showInput = false;
    _initializeSelectedHashtags(); // Reset selected hashtags
  }
}

// --- Helper Child Widgets (for better separation and potential const usage) ---

class _PostCardHeader extends StatelessWidget {
  final MemoModelPost post;
  final VoidCallback onOptionsMenuPressed;

  const _PostCardHeader({required this.post, required this.onOptionsMenuPressed});

  // Example of what onClickCreatorName might do, assuming ProfileScreen exists
  void _navigateToProfile(BuildContext context, String creatorId) {
    _logInfo("Navigate to profile: $creatorId (Not implemented here)");
    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (context) => ProfileScreen(uid: creatorId)),
    // );
    showSnackBar("Navigate to profile $creatorId", context);
  }

  @override
  Widget build(BuildContext context) {
    // Creator should not be null here if PostCard build method checks it.
    final creator = post.creator!;

    return Padding(
      // Use Padding instead of Container with padding for const-ability
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16).copyWith(right: 8), // Adjusted right for menu
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, creator.id),
            child: CircleAvatar(
              radius: 22,
              backgroundImage: creator.profileImage().isEmpty
                  ? const AssetImage("assets/images/default_profile.png")
                        as ImageProvider // Example default
                  : NetworkImage(creator.profileImage()),
              // Add onBackgroundImageError for NetworkImage if needed
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              // Use column for name and time details for better structure
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  // Make name tappable too
                  onTap: () => _navigateToProfile(context, creator.id),
                  child: Text(
                    creator.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  // Keep time details in a row
                  children: [
                    if (post.age != null) Text(post.age!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (post.age != null && post.created != null)
                      const Text(" - ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    if (post.created != null)
                      Text(post.created!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: onOptionsMenuPressed),
        ],
      ),
    );
  }
}

class _PostCardFooter extends StatelessWidget {
  final MemoModelPost post;
  final TextEditingController textEditController;
  final bool showInput;
  final bool showSend;
  final bool hasSelectedTopic;
  final List<bool> selectedHashtags;
  final ValueChanged<String> onInputText;
  final ValueChanged<int> onSelectHashtag;
  final VoidCallback onSelectTopic;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const _PostCardFooter({
    required this.post,
    required this.textEditController,
    required this.showInput,
    required this.showSend,
    required this.hasSelectedTopic,
    required this.selectedHashtags,
    required this.onInputText,
    required this.onSelectHashtag,
    required this.onSelectTopic,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (post.creator == null) return const SizedBox.shrink(); // Should be checked by parent

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.text != null && post.text!.isNotEmpty)
            ExpandableText(
              post.text!,
              prefixText: "${post.creator!.name}: ",
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              expandText: 'show more',
              collapseText: 'show less',
              maxLines: 5,
              linkColor: Colors.blue,
              style: const TextStyle(fontSize: 14.5),
              animation: true,
            ),
          if (showInput) ...[
            // Use collection-if for cleaner conditional list
            const SizedBox(height: 8),
            TextField(
              controller: textEditController,
              onChanged: onInputText,
              decoration: const InputDecoration(
                hintText: "Add a comment or reply...",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ],
          if (post.topic != null) ...[const SizedBox(height: 8), _buildTopicCheckBoxWidget()],
          if (post.hashtags.isNotEmpty) ...[const SizedBox(height: 4), _buildHashtagCheckboxesWidget()],
          if (showSend) ...[
            const SizedBox(height: 8),
            Row(children: [_buildCancelButtonWidget(), Spacer(), _buildSendButtonWidget()]),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicCheckBoxWidget() {
    return Row(
      children: [
        InkWell(
          // Use InkWell for better tap feedback
          onTap: onSelectTopic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text("TOPIC: ${post.topic!.header}", style: const TextStyle(color: Colors.blueAccent)),
          ),
        ),
        Checkbox(
          value: hasSelectedTopic,
          onChanged: (value) => onSelectTopic(),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Smaller tap area for checkbox itself
        ),
      ],
    );
  }

  Widget _buildHashtagCheckboxesWidget() {
    final int displayCount = post.hashtags.length > _PostCardState._maxTagsCounter
        ? _PostCardState._maxTagsCounter
        : post.hashtags.length;

    if (displayCount == 0) return const SizedBox.shrink();

    return Wrap(
      // Use Wrap for better layout if many hashtags
      spacing: 6.0,
      runSpacing: 0.0,
      children: List<Widget>.generate(displayCount, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min, // Important for Row in Wrap
          children: [
            InkWell(
              onTap: () => onSelectHashtag(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: selectedHashtags.length > index && selectedHashtags[index]
                      ? Colors.blue.shade100
                      : (index % 2 == 0 ? Colors.grey.shade300 : Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(post.hashtags[index]),
              ),
            ),
            Checkbox(
              value: selectedHashtags.length > index && selectedHashtags[index],
              onChanged: (value) => onSelectHashtag(index),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCancelButtonWidget() {
    String buttonText = "Cancel";

    return Align(
      // Align button to the right or center
      alignment: Alignment.centerLeft,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onCancel,
        child: Text(buttonText),
      ),
    );
  }

  Widget _buildSendButtonWidget() {
    String buttonText = "Post";
    if (hasSelectedTopic && selectedHashtags.any((s) => s)) {
      buttonText = "Reply to Topic with tags";
    } else if (hasSelectedTopic) {
      buttonText = "Reply to Topic";
    } else if (selectedHashtags.any((s) => s)) {
      buttonText = "Post with tags";
    }
    // else: it might be a general comment if you allow that without topic/tags

    return Align(
      // Align button to the right or center
      alignment: Alignment.centerRight,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white, // Text color
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onSend,
        child: Text(buttonText),
      ),
    );
  }
}

// --- Animation Helper Widgets (extracted for clarity and reusability) ---

class _SendingAnimation extends StatelessWidget {
  final bool isSending;
  final double mediaHeight;
  final VoidCallback onEnd;

  const _SendingAnimation({required this.isSending, required this.mediaHeight, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _PostCardState._animationDuration,
      opacity: isSending ? 1 : 0,
      child: LikeAnimation(
        // Assuming LikeAnimation handles its own state for isAnimating
        isAnimating: isSending, // Or manage isAnimating separately if LikeAnimation needs it
        duration: _PostCardState._animationDuration,
        onEnd: onEnd,
        child: Icon(
          Icons.thumb_up_outlined,
          color: const Color.fromRGBO(255, 255, 255, 0.9), // Slightly transparent
          size: mediaHeight * 0.8, // Relative size
        ),
      ),
    );
  }
}

class _LikeSucceededAnimation extends StatelessWidget {
  final bool isAnimating;
  final double mediaHeight;
  final VoidCallback onEnd;

  const _LikeSucceededAnimation({required this.isAnimating, required this.mediaHeight, required this.onEnd});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: _PostCardState._animationDuration,
      opacity: isAnimating ? 1 : 0,
      child: LikeAnimation(
        isAnimating: isAnimating,
        duration: _PostCardState._animationDuration,
        onEnd: onEnd,
        child: Icon(
          Icons.currency_bitcoin, // Or Icons.favorite for a more generic like
          color: Colors.greenAccent, // Gold-ish, slightly transparent
          size: mediaHeight * 0.8,
        ),
      ),
    );
  }
}

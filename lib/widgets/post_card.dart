import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/base/memo_verifier.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/memo/scraper/memo_scraper_utils.dart';
import 'package:mahakka/screens/home.dart';
import 'package:mahakka/utils/snackbar.dart'; // Ensure this uses themed SnackBars
import 'package:mahakka/widgets/like_animtion.dart'; // Ensure this is theme-aware or neutral
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import 'memo_confetti.dart'; // Ensure this is theme-aware or neutral

// Basic logging placeholder (remains the same)
void _logInfo(String message) => print('INFO: PostCard - $message');
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: PostCard - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class PostCard extends StatefulWidget {
  final MemoModelPost post;

  final NavBarCallback navBarCallback;

  const PostCard(this.post, this.navBarCallback, {Key? key}) : super(key: key);

  @override
  State<PostCard> createState() => _PostCardState(navBarCallback: navBarCallback);
}

class _PostCardState extends State<PostCard> {
  // Constants (remain the same)
  static const double _altImageHeight = 50.0;
  static const int _maxTagsCounter = 3;
  static const int _minTextLength = 20;
  static const Duration _animationDuration = Duration(milliseconds: 500);

  // State variables (remain the same)
  MemoModelUser? _user;
  bool _isAnimatingLike = false;
  bool _isSendingTx = false;
  bool _showInput = false;
  bool _showSend = false;
  bool _hasSelectedTopic = false;
  late List<bool> _selectedHashtags;

  // Controllers (remain the same)
  late TextEditingController _textEditController;
  YoutubePlayerController? _ytController;

  final NavBarCallback navBarCallback;

  _PostCardState({required NavBarCallback this.navBarCallback});

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _initializeSelectedHashtags();
    _loadUser();
    widget.post.creator!.refreshAvatar();

    if (widget.post.youtubeId != null && widget.post.youtubeId!.isNotEmpty) {
      _ytController = YoutubePlayerController(
        initialVideoId: widget.post.youtubeId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          // Consider making controls visible by default or using themed colors
          // hideControls: false,
          // controlsTimeOut: Duration(seconds: 5),
        ),
      );
    }
  }

  void _initializeSelectedHashtags() {
    final int count = widget.post.hashtags.length > _maxTagsCounter ? _maxTagsCounter : widget.post.hashtags.length;
    _selectedHashtags = List<bool>.filled(count, false);
  }

  Future<void> _loadUser() async {
    _user = await MemoModelUser.getUser();
    if (mounted) {
      // If user data influences UI directly that's not part of an async operation,
      // you might need a setState here. For now, assuming it's used in async ops like _sendTip.
      // setState(() {});
    }
  }

  @override
  void dispose() {
    _textEditController.dispose();
    _ytController?.dispose();
    super.dispose();
  }

  // --- UI Builder Methods ---

  Widget _buildPostMedia(ThemeData theme) {
    if (widget.post.youtubeId != null && _ytController != null) {
      return YoutubePlayer(
        controller: _ytController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: theme.colorScheme.primary, // Use theme color
        progressColors: ProgressBarColors(
          // Use theme colors
          playedColor: theme.colorScheme.primary,
          handleColor: theme.colorScheme.secondary,
          bufferedColor: theme.colorScheme.primary.withOpacity(0.5),
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
        ),
        // Consider theming other aspects of the player if available
      );
    } else if (widget.post.imgurUrl != null) {
      return Image.network(
        widget.post.imgurUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // ImgurUtils.errorLoadImage should ideally return a themed widget
          // For now, a simple themed error placeholder:
          _logError("Failed to load Imgur image: ${widget.post.imgurUrl}", error, stackTrace);
          return Container(
            height: _altImageHeight * 2, // Make it a bit larger
            color: theme.colorScheme.surfaceVariant,
            child: Center(
              child: Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant, size: 30),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          // ImgurUtils.loadingImage should ideally return a themed widget
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
                // color is handled by theme.progressIndicatorTheme
              ),
            ),
          );
        },
      );
    } else {
      // Placeholder for text-only posts or posts without media
      return Container(
        height: _altImageHeight,
        color: theme.colorScheme.surfaceVariant, // Use themed background
        child: Center(
          child: Icon(
            Icons.article_outlined, // Placeholder icon
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
            size: _altImageHeight * 0.6,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Get the current theme

    if (widget.post.creator == null) {
      _logError("Post creator is null for post ID: ${widget.post.txHash}");
      return Card(
        // Use Card for consistent error display
        color: theme.colorScheme.errorContainer,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Error: Post data incomplete. Cannot display this post.",
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
      );
    }

    return Card(
      // Card properties will now use theme.cardTheme
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      // elevation: theme.cardTheme.elevation ?? 2.0, // Or set explicitly
      // color: theme.cardTheme.color, // Handled by CardTheme
      // shape: theme.cardTheme.shape, // Handled by CardTheme
      clipBehavior: Clip.antiAlias, // Good practice for cards with images
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PostCardHeader(
            post: widget.post,
            onOptionsMenuPressed: _sendTipToCreator,
            navBarCallback: navBarCallback,
            // _showPostOptionsMenu,
            // Pass theme if _PostCardHeader needs it directly,
            // but it should primarily use Theme.of(context) internally
          ),
          GestureDetector(
            onDoubleTap: _isSendingTx ? null : _sendTipToCreator, // Disable if already sending
            child: ZoomOverlay(
              modalBarrierColor: theme.colorScheme.scrim.withOpacity(0.3), // Themed scrim
              minScale: 0.5,
              maxScale: 3.0,
              twoTouchOnly: true,
              animationDuration: const Duration(milliseconds: 200),
              animationCurve: Curves.easeOut,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _buildPostMedia(theme),
                  // Assuming _SendingAnimation and _LikeSucceededAnimation are theme-aware
                  // or their fixed colors are acceptable (e.g., white overlay icons).
                  // If not, they also need to be refactored to use Theme.of(context).
                  _SendingAnimation(
                    isSending: _isSendingTx,
                    mediaHeight: widget.post.imgurUrl == null && widget.post.youtubeId == null
                        ? _altImageHeight
                        : 150.0,
                    onEnd: () {
                      if (mounted) setState(() => _isSendingTx = false);
                    },
                    theme: theme, // Pass theme if it needs it directly for icons
                  ),
                  _LikeSucceededAnimation(
                    isAnimating: _isAnimatingLike,
                    mediaHeight: widget.post.imgurUrl == null && widget.post.youtubeId == null
                        ? _altImageHeight
                        : 150.0,
                    onEnd: () {
                      if (mounted) setState(() => _isAnimatingLike = false);
                    },
                    theme: theme, // Pass theme
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

  // --- Interaction Logic Methods (Mostly unchanged, ensure SnackBars are themed) ---

  Future<void> _sendTipToCreator() async {
    if (_user == null) {
      showSnackBar("User data not loaded yet.", context); // showSnackBar should use themed context
      _loadUser();
      return;
    }
    if (!mounted) return;
    setState(() => _isSendingTx = true);

    try {
      MemoAccountantResponse response = await MemoAccountant(_user!).publishLike(widget.post);
      if (!mounted) return;

      setState(() {
        _isSendingTx = false;
        switch (response) {
          case MemoAccountantResponse.yes:
            _isAnimatingLike = true;
            // MemoConfetti().launch(context); // Assuming confetti is theme-neutral or adapts
            break;
          case MemoAccountantResponse.lowBalance:
            showSnackBar("Low balance", context);
            break;
          case MemoAccountantResponse.noUtxo:
          case MemoAccountantResponse.dust:
            // default: // Catch-all for other non-success cases
            _logError("Accountant error during tip: ${response.name}", response);
            showSnackBar("Transaction error (${response.name}). Please try again later.", context);
            break;
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

  // void _showPostOptionsMenu() {
  //   final ThemeData theme = Theme.of(context); // Get theme for the dialog
  //
  //   showDialog(
  //     context: context,
  //     builder: (dialogCtx) => Dialog(
  //       // Dialog properties will now use theme.dialogTheme
  //       // shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       // elevation: theme.dialogTheme.elevation ?? 0,
  //       // backgroundColor: theme.dialogTheme.backgroundColor,
  //       child: ListView(
  //         padding: const EdgeInsets.symmetric(vertical: 16),
  //         shrinkWrap: true,
  //         children:
  //             ["Tip Creator", "Creator Profile", "Bookmark"] // Could be constants
  //                 .map(
  //                   (e) => InkWell(
  //                     onTap: () {
  //                       showSnackBar("Report was sent to Satoshi Nakamoto, please wait...", dialogCtx);
  //                       Navigator.pop(dialogCtx);
  //                     },
  //                     child: Container(
  //                       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
  //                       child: Center(
  //                         child: Text(
  //                           e,
  //                           style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
  //                         ),
  //                       ),
  //                     ),
  //                   ),
  //                 )
  //                 .toList(),
  //       ),
  //     ),
  //   );
  // }

  // _onSelectTopic, _onInputText, _onSelectHashtag, _evaluateShowSendButton, _onSend, _onCancel
  // These methods primarily manage state and call _publish methods. Their logic remains the same.
  // The UI they control (_PostCardFooter) will be themed.

  // --- Publish and Response Methods (Ensure SnackBars are themed) ---

  Future<void> _publishReplyTopic(String text) async {
    // ... (logic remains)
    var result = await widget.post.publishReplyTopic(text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  Future<void> _publishReplyHashtags(String text) async {
    // ... (logic remains)
    var result = await widget.post.publishReplyHashtags(text);
    if (!mounted) return;
    _showVerificationResponse(result, context);
  }

  void _showVerificationResponse(dynamic result, BuildContext ctx) {
    // ... (logic remains, ensure showSnackBar uses themed context)
    String message = "";
    bool success = false;

    if (result is MemoVerificationResponse) {
      // ... (existing switch cases)
      switch (result) {
        case MemoVerificationResponse.minWordCountNotReached:
          message = "Write more words";
          break;
        // ... (all your other MemoVerificationResponse cases) ...
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
        // default:
        //   message = "Account issue: ${result.name}";
      }
    } else {
      message = "An unexpected error occurred during verification.";
      _logError("Unknown verification response type: ${result.runtimeType}", result);
    }

    if (success) {
      _clearAndConfetti();
    } else if (message.isNotEmpty && mounted) {
      showSnackBar(message, ctx); // Ensure showSnackBar uses themed context
    }
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
}

// --- Helper Child Widgets (Refactored for Theming) ---

class _PostCardHeader extends StatelessWidget {
  final MemoModelPost post;
  final VoidCallback onOptionsMenuPressed;
  final NavBarCallback navBarCallback;

  const _PostCardHeader({required this.post, required this.onOptionsMenuPressed, required this.navBarCallback});

  void _navigateToProfile(BuildContext context, String creatorId) {
    MemoModelUser.profileIdSet(creatorId);
    navBarCallback.switchToProfileTab();
    // _logInfo("Navigate to profile: $creatorId (Not implemented here)");
    // showSnackBar("Navigate to profile $creatorId", context); // Ensure showSnackBar is themed
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final creator = post.creator!; // Null check in PostCard.build

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16).copyWith(right: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _navigateToProfile(context, creator.id),
            child: CircleAvatar(
              radius: 20, // Slightly smaller for a tighter look
              backgroundColor: theme.colorScheme.surfaceVariant, // Fallback color
              backgroundImage: creator.profileImageAvatar().isEmpty
                  ? const AssetImage("assets/images/default_profile.png")
                        as ImageProvider // Keep your default
                  : NetworkImage(creator.profileImageAvatar()),
              onBackgroundImageError: (exception, stackTrace) {
                _logError("Error loading profile image for ${creator.name}", exception, stackTrace);
                // Optionally, you could use an Icon here as a fallback if the image fails.
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _navigateToProfile(context, creator.id),
                  child: Text(
                    creator.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      // color: theme.colorScheme.onSurface, // Text color from theme
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // const SizedBox(height: 2), // Reduce spacing if too much
                if (post.age != null || post.created != null)
                  Row(
                    children: [
                      if (post.age != null)
                        Text(
                          post.age!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      if (post.age != null && post.created != null)
                        Text(
                          " - ",
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      if (post.created != null)
                        Text(
                          post.created!,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.thumb_up_alt_outlined /* color: theme.colorScheme.onSurfaceVariant */,
            ), // Color from IconTheme
            onPressed: onOptionsMenuPressed,
            tooltip: "Tip",
            iconSize: 22,
            visualDensity: VisualDensity.compact,
          ),
          // IconButton(
          //   icon: Icon(Icons.more_vert /* color: theme.colorScheme.onSurfaceVariant */), // Color from IconTheme
          //   onPressed: onOptionsMenuPressed,
          //   tooltip: "More options",
          //   iconSize: 22,
          //   visualDensity: VisualDensity.compact,
          // ),
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
    final ThemeData theme = Theme.of(context);
    // Creator null check should be done by parent (PostCard.build)
    // if (post.creator == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.text != null && post.text!.isNotEmpty) ...[
            ExpandableText(
              post.text!,
              prefixText: post.creator != null ? "${post.creator!.name}: " : "", // Handle potential null creator
              prefixStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                // color: theme.colorScheme.onSurface,
              ),
              expandText: 'show more',
              collapseText: 'show less',
              maxLines: 6, // Adjust as needed
              linkColor: theme.colorScheme.primary, // Themed link color
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4), // Use themed text style
              animation: true,
              linkEllipsis: true,
              linkStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (showInput) ...[
            TextField(
              controller: textEditController,
              onChanged: onInputText,
              style: theme.textTheme.bodyMedium, // Use themed text style
              decoration: InputDecoration(
                // Will use theme.inputDecorationTheme
                hintText: "Add a comment or reply...",
                // border: OutlineInputBorder(), // Handled by theme
                // isDense: true, // Handled by theme if defined
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: 10),
          ],
          if (post.topic != null) ...[_buildTopicCheckBoxWidget(theme), const SizedBox(height: 6)],
          if (post.hashtags.isNotEmpty) ...[_buildHashtagCheckboxesWidget(theme), const SizedBox(height: 8)],
          if (showSend) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the end
              children: [
                _buildCancelButtonWidget(theme),
                const SizedBox(width: 8), // Spacing between buttons
                _buildSendButtonWidget(theme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopicCheckBoxWidget(ThemeData theme) {
    final bool topicTextIsEffectivelyEmpty = post.topic == null || post.topic!.header.trim().isEmpty;

    return InkWell(
      onTap: onSelectTopic,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Align(
          // Wrap the Row with Align
          // Conditionally align: Center if no text, start if text is present
          alignment: topicTextIsEffectivelyEmpty ? Alignment.center : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min, // Keep this so the Row doesn't expand unnecessarily
            children: [
              Checkbox(
                value: hasSelectedTopic,
                onChanged: (value) => onSelectTopic(),
                activeColor: theme.colorScheme.primary,
                checkColor: theme.colorScheme.onPrimary,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              // Only add SizedBox and Text if there's actual text to display
              if (!topicTextIsEffectivelyEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    post.topic!.header, // Safe to use ! because of the check above
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: hasSelectedTopic ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      fontWeight: hasSelectedTopic ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagCheckboxesWidget(ThemeData theme) {
    final int displayCount = post.hashtags.length > _PostCardState._maxTagsCounter
        ? _PostCardState._maxTagsCounter
        : post.hashtags.length;

    if (displayCount == 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: List<Widget>.generate(displayCount, (index) {
        final bool isSelected = selectedHashtags.length > index && selectedHashtags[index];
        return InkWell(
          onTap: () => onSelectHashtag(index),
          borderRadius: BorderRadius.circular(16), // Rounded chip-like tappable area
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withOpacity(0.15) // Subtle primary highlight
                  : theme.colorScheme.surfaceVariant.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Optional: Checkbox inside the chip, or rely on visual style
                // Checkbox(
                //   value: isSelected,
                //   onChanged: (value) => onSelectHashtag(index),
                //   activeColor: theme.colorScheme.primary,
                //   visualDensity: VisualDensity.compact,
                //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                //   side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline),
                // ),
                // if (isSelected) SizedBox(width: 4),
                Text(
                  post.hashtags[index],
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCancelButtonWidget(ThemeData theme) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.error, // Text color for cancel
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5)), // Optional border
        ),
        textStyle: theme.textTheme.labelLarge,
      ),
      onPressed: onCancel,
      child: const Text("Cancel"),
    );
  }

  Widget _buildSendButtonWidget(ThemeData theme) {
    String buttonText = "Post"; // Default
    // Logic to determine button text remains the same
    if (hasSelectedTopic && selectedHashtags.any((s) => s)) {
      buttonText = "Reply to Topic with tags";
    } else if (hasSelectedTopic) {
      buttonText = "Reply to Topic";
    } else if (selectedHashtags.any((s) => s)) {
      buttonText = "Post with tags";
    }

    return ElevatedButton(
      // Use ElevatedButton for primary action
      style: ElevatedButton.styleFrom(
        // backgroundColor: theme.colorScheme.primary, // Handled by theme.elevatedButtonTheme
        // foregroundColor: theme.colorScheme.onPrimary, // Handled by theme.elevatedButtonTheme
        // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Handled by theme
        textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      onPressed: onSend,
      child: Text(buttonText),
    );
  }
}

// --- Animation Helper Widgets (Pass Theme or ensure they use Theme.of(context)) ---

class _SendingAnimation extends StatelessWidget {
  final bool isSending;
  final double mediaHeight;
  final VoidCallback onEnd;
  final ThemeData theme; // Pass theme

  const _SendingAnimation({
    required this.isSending,
    required this.mediaHeight,
    required this.onEnd,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCircledOpacityAnimation(Icons.thumb_up_alt_outlined, theme, mediaHeight, isSending, onEnd);
  }
}

class _LikeSucceededAnimation extends StatelessWidget {
  final bool isAnimating;
  final double mediaHeight;
  final VoidCallback onEnd;
  final ThemeData theme; // Pass theme

  const _LikeSucceededAnimation({
    required this.isAnimating,
    required this.mediaHeight,
    required this.onEnd,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return _buildCircledOpacityAnimation(Icons.currency_bitcoin_rounded, theme, mediaHeight, isAnimating, onEnd);
  }
}

AnimatedOpacity _buildCircledOpacityAnimation(IconData ico, ThemeData theme, mediaHeight, isAnimating, onEnd) {
  Color avatarBackgroundColor = theme.colorScheme.surface; // Example: Primary color for the circle
  Color iconColorOnAvatar = theme.colorScheme.primary; // Icon color that contrasts with primary

  double iconSize = mediaHeight * 0.6; // CircleAvatar adds some padding, so icon might need to be slightly smaller
  double avatarRadius = mediaHeight * 0.5; // Adjust the radius of the CircleAvatar itself

  return AnimatedOpacity(
    duration: _PostCardState._animationDuration,
    opacity: isAnimating ? 1 : 0,
    child: LikeAnimation(
      isAnimating: isAnimating,
      duration: _PostCardState._animationDuration,
      onEnd: onEnd,
      child: CircleAvatar(
        radius: avatarRadius,
        backgroundColor: avatarBackgroundColor,
        child: Icon(ico, color: iconColorOnAvatar, size: iconSize),
      ),
    ),
  );
}

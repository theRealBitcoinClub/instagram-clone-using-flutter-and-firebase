import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/widgets/memo_confetti.dart'; // Ensure this is theme-neutral or adapts
import 'package:mahakka/widgets/textfield_input.dart'; // CRITICAL: This MUST be themed internally
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Assuming these exist and are correctly imported
import '../views_taggable/view_models/search_view_model.dart'; // Ensure SearchViewModel logic is sound
import '../views_taggable/widgets/comment_text_field.dart'; // CRITICAL: This MUST be themed internally
import '../views_taggable/widgets/search_result_overlay.dart'; // Ensure this is theme-aware or neutral

void _log(String message) => print('[AddPost] $message');

class AddPost extends StatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _imgurCtrl = TextEditingController();
  final TextEditingController _youtubeCtrl = TextEditingController();
  late FlutterTaggerController _tagController;
  late AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();

  // State for YouTube Player
  YoutubePlayerController? _ytPlayerController;
  String? _currentYouTubeVideoId;

  // UI State
  bool _isLoadingUser = true;
  bool _isCheckingClipboard = true;
  bool _isPublishing = false;

  String _validImgurUrl = "";
  String _validYouTubeVideoId = "";

  MemoModelUser? _user;
  late Animation<Offset> _taggerOverlayAnimation;
  final double _taggerOverlayHeight = 300;

  // Assuming searchViewModel is provided or accessible
  // final SearchViewModel searchViewModel = SearchViewModel(); // Replace with actual instance

  @override
  void initState() {
    super.initState();
    _log("initState started");

    _tagController = FlutterTaggerController(
      // Example text, consider making it empty or a placeholder
      text: "I like the topic @Bitcoin#Bitcoin# It's time to earn #bch#bch# and #cashtoken#cashtoken#!",
    );

    _imgurCtrl.addListener(_onImgurInputChanged);
    _youtubeCtrl.addListener(_onYouTubeInputChanged);

    _initStateTagger();
    _loadInitialData();
    _log("initState completed");
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUser = true;
      _isCheckingClipboard = true;
    });

    try {
      final userFuture = MemoModelUser.getUser();
      final clipboardFuture = _checkClipboard();

      _user = await userFuture;
      await clipboardFuture;
    } catch (e, s) {
      _log("Error during initial data load: $e\n$s");
      _showErrorSnackBar('Error loading initial data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _isCheckingClipboard = false;
        });
      }
    }
  }

  Future<void> _checkClipboard() async {
    _log("_checkClipboard started");
    String? newImgurUrl;
    String? newVideoId;
    String? clipboardTextForField;

    try {
      if (await FlutterClipboard.hasData()) {
        final urlFromClipboard = await FlutterClipboard.paste();
        _log("Clipboard data: $urlFromClipboard");
        final ytId = YoutubePlayer.convertUrlToId(urlFromClipboard);

        if (ytId != null && ytId.isNotEmpty) {
          newVideoId = ytId;
          clipboardTextForField = urlFromClipboard;
        } else {
          final imgur = _extractValidImgurUrl(urlFromClipboard);
          if (imgur.isNotEmpty) {
            newImgurUrl = imgur;
            clipboardTextForField = urlFromClipboard;
          }
        }
      }
    } catch (e, s) {
      _log("Error checking clipboard: $e\n$s");
      // Optionally show a less intrusive error for clipboard issues
      // _showErrorSnackBar('Could not read clipboard: ${e.toString()}');
    }

    if (mounted) {
      setState(() {
        if (newVideoId != null) {
          _validYouTubeVideoId = newVideoId;
          _validImgurUrl = "";
          _youtubeCtrl.text = clipboardTextForField ?? _youtubeCtrl.text;
          _imgurCtrl.clear();
          _rebuildYtPlayerController();
        } else if (newImgurUrl != null) {
          _validImgurUrl = newImgurUrl;
          _validYouTubeVideoId = "";
          _imgurCtrl.text = clipboardTextForField ?? _imgurCtrl.text;
          _youtubeCtrl.clear();
          _disposeYtPlayerController();
        }
      });
    }
    _log("_checkClipboard finished");
  }

  String _extractValidImgurUrl(String url) {
    final RegExp exp = RegExp(r'^(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)$');
    final match = exp.firstMatch(url.trim());
    return match?.group(0) ?? ""; // Return the full matched URL or empty
  }

  void _onImgurInputChanged() {
    if (!mounted) return;
    final text = _imgurCtrl.text.trim();
    final newImgurUrl = _extractValidImgurUrl(text);

    if (newImgurUrl != _validImgurUrl) {
      setState(() {
        _validImgurUrl = newImgurUrl;
        if (newImgurUrl.isNotEmpty && _validYouTubeVideoId.isNotEmpty) {
          _validYouTubeVideoId = "";
          _youtubeCtrl.clear();
          _disposeYtPlayerController();
        }
      });
    }
  }

  void _onYouTubeInputChanged() {
    if (!mounted) return;
    final text = _youtubeCtrl.text.trim();
    final newVideoId = YoutubePlayer.convertUrlToId(text);

    if ((newVideoId ?? "") != _validYouTubeVideoId) {
      setState(() {
        if (newVideoId != null && newVideoId.isNotEmpty) {
          _validYouTubeVideoId = newVideoId;
          if (_validImgurUrl.isNotEmpty) {
            _validImgurUrl = "";
            _imgurCtrl.clear();
          }
          _rebuildYtPlayerController();
        } else {
          _validYouTubeVideoId = "";
          _disposeYtPlayerController();
        }
      });
    }
  }

  void _rebuildYtPlayerController() {
    if (_validYouTubeVideoId.isEmpty) {
      _disposeYtPlayerController();
      return;
    }
    if (_currentYouTubeVideoId != _validYouTubeVideoId || _ytPlayerController == null) {
      _disposeYtPlayerController();
      _ytPlayerController = YoutubePlayerController(
        initialVideoId: _validYouTubeVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          // Consider theme for controls if YoutubePlayerFlutter supports it
          // hideControls: false,
        ),
      );
      _currentYouTubeVideoId = _validYouTubeVideoId;
    }
  }

  void _disposeYtPlayerController() {
    _ytPlayerController?.pause();
    _ytPlayerController?.dispose();
    _ytPlayerController = null;
    _currentYouTubeVideoId = null;
  }

  void _initStateTagger() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _taggerOverlayAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine));
    _tagController.addListener(_onTagInputChanged);
  }

  void _onTagInputChanged() {
    // TODO: Implement tag validation logic here
    // This could update a validation message or directly interact with _tagController
    // Example:
    // final String? error = _validateTagsAndTopic();
    // if (mounted) {
    //   setState(() { /* update some error message state variable */ });
    // }
  }

  @override
  void dispose() {
    _log("Dispose called");
    _imgurCtrl.removeListener(_onImgurInputChanged);
    _youtubeCtrl.removeListener(_onYouTubeInputChanged);
    _tagController.removeListener(_onTagInputChanged);
    _imgurCtrl.dispose();
    _youtubeCtrl.dispose();
    _tagController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    _disposeYtPlayerController();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: theme.colorScheme.onError)),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: theme.colorScheme.onSecondaryContainer)), // Example color
        backgroundColor: theme.colorScheme.secondaryContainer, // Example color
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _log("Build method called");
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        _focusNode.unfocus();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          // Properties like backgroundColor, foregroundColor, titleTextStyle, elevation
          // will be inherited from theme.appBarTheme.
          // Explicit overrides below are for fine-tuning if needed.
          title: Text("Create New Post", style: theme.appBarTheme.titleTextStyle),
          // backgroundColor: colorScheme.primary, // Or from theme
          // iconTheme: IconThemeData(color: colorScheme.onPrimary), // Or from theme
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_isLoadingUser || _isCheckingClipboard)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()), // Will use theme color
                )
              else
                _buildMediaInputSection(theme, colorScheme, textTheme),

              if (!_isLoadingUser && !_isCheckingClipboard && (_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty))
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 12, // More padding at bottom
                    left: 12,
                    right: 12,
                    top: 8, // Add some horizontal padding too
                  ),
                  child: _buildTaggableInput(theme, colorScheme, textTheme, mediaQuery.viewInsets),
                )
              else if (!_isLoadingUser && !_isCheckingClipboard)
                const Spacer(), // Pushes content up if no media and no tag input
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaInputSection(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    bool showImgurPlaceholder = _validYouTubeVideoId.isEmpty;
    bool showVideoPlaceholder = _validImgurUrl.isEmpty;

    if (_validImgurUrl.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildMediaDisplay(
            theme: theme,
            colorScheme: colorScheme,
            textTheme: textTheme,
            label: "SELECTED IMAGE",
            mediaUrl: _validImgurUrl,
            onTap: _showImgurDialog,
            isNetworkImage: true,
          ),
        ),
      );
    }

    if (_validYouTubeVideoId.isNotEmpty && _ytPlayerController != null) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildMediaDisplay(
            theme: theme,
            colorScheme: colorScheme,
            textTheme: textTheme,
            label: "SELECTED VIDEO",
            youtubeController: _ytPlayerController,
            onTap: _showVideoDialog,
            isNetworkImage: false,
          ),
        ),
      );
    }

    // Both are empty, show placeholders
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImgurPlaceholder)
            Expanded(
              child: _buildMediaPlaceholder(
                theme: theme,
                colorScheme: colorScheme,
                textTheme: textTheme,
                label: "ADD IMAGE",
                iconData: Icons.add_photo_alternate_outlined,
                onTap: _showImgurDialog,
              ),
            ),
          if (showImgurPlaceholder && showVideoPlaceholder) const SizedBox(width: 16),
          if (showVideoPlaceholder)
            Expanded(
              child: _buildMediaPlaceholder(
                theme: theme,
                colorScheme: colorScheme,
                textTheme: textTheme,
                label: "ADD VIDEO",
                iconData: Icons.video_call_outlined,
                onTap: _showVideoDialog,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPlaceholder({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String label,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 50, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaDisplay({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required String label,
    String? mediaUrl,
    YoutubePlayerController? youtubeController,
    required VoidCallback onTap,
    required bool isNetworkImage,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11.5),
              child: isNetworkImage
                  ? Image.network(
                      mediaUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        _log("Error loading Imgur image: $error");
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) setState(() => _validImgurUrl = "");
                        });
                        return Center(
                          child: Column(
                            // More informative error
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
                            // valueColor from theme.progressIndicatorTheme
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    )
                  : (youtubeController != null
                        ? YoutubePlayer(
                            key: ValueKey("yt_addpost_"),
                            controller: youtubeController,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: colorScheme.primary, // Themed
                            progressColors: ProgressBarColors(
                              // Themed
                              playedColor: colorScheme.primary,
                              handleColor: colorScheme.secondary,
                              bufferedColor: colorScheme.primary.withOpacity(0.4),
                              backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                            ),
                          )
                        : Center(
                            child: Column(
                              // More informative error
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_off_outlined, color: colorScheme.error, size: 36),
                                const SizedBox(height: 8),
                                Text("Video player error", style: textTheme.bodyMedium?.copyWith(color: colorScheme.error)),
                              ],
                            ),
                          )),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          icon: Icon(Icons.edit_outlined, size: 18), // Icon color from TextButtonTheme or colorScheme.primary
          label: Text(isNetworkImage ? "Change Image" : "Change Video"),
          onPressed: onTap,
          // Style from theme.textButtonTheme or direct styling using theme:
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.secondary, // Or colorScheme.primary
            textStyle: textTheme.labelLarge,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _showImgurDialog() async {
    _showUrlInputDialog("Paste Imgur Image URL", _imgurCtrl, "e.g. https://i.imgur.com/image.jpeg");
  }

  Future<void> _showVideoDialog() async {
    _showUrlInputDialog("Paste YouTube Video URL", _youtubeCtrl, "e.g. https://youtu.be/video_id");
  }

  void _showUrlInputDialog(String title, TextEditingController controller, String hint) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    _checkClipboard(); // Ensure clipboard is checked before showing dialog

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          // shape, titleTextStyle, contentTextStyle, backgroundColor from theme.dialogTheme
          title: Text(title /*, style: theme.dialogTheme.titleTextStyle ?? textTheme.titleLarge */),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CRITICAL: TextInputField must be themed internally
              TextInputField(
                textEditingController: controller,
                hintText: hint,
                textInputType: TextInputType.url,
                // If TextInputField doesn't use theme.inputDecorationTheme, it will look out of place
              ),
              const SizedBox(height: 12),
              Text("Tip: Paste a full URL from Imgur or YouTube.", style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          actions: <Widget>[
            TextButton(
              // Style from theme.textButtonTheme
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel' /*, style: TextStyle(color: colorScheme.onSurfaceVariant)*/), // Uses TextButton's foregroundColor
            ),
            TextButton(
              // Style from theme.textButtonTheme (or override for emphasis)
              onPressed: () {
                Navigator.of(dialogCtx).pop();
              },
              child: Text('Done' /*, style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)*/),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaggableInput(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme, EdgeInsets viewInsets) {
    return Material(
      elevation: 4.0,
      color: theme.cardColor, // Or theme.cardColor
      shadowColor: theme.shadowColor,
      borderRadius: BorderRadius.circular(8), // Optional: rounded corners for the input area
      child: Padding(
        padding: const EdgeInsets.all(12), // Consistent padding
        child: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: _tagController,
          // focusNode: _focusNode,
          animationController: _animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchTopic(query);
            } else if (triggerChar == "#") {
              searchViewModel.searchHashtag(query);
            }
          },
          triggerCharacterAndStyles: {
            "@": textTheme.bodyLarge!.copyWith(
              color: colorScheme.secondary, // E.g., your light green
              fontWeight: FontWeight.bold,
            ),
            "#": textTheme.bodyLarge!.copyWith(
              color: colorScheme.tertiary, // E.g., another accent from your theme
              fontWeight: FontWeight.bold,
            ),
          },
          tagTextFormatter: (id, tag, triggerChar) {
            return "$triggerChar$id#$tag#";
          },
          overlayHeight: _taggerOverlayHeight,
          // Ensure SearchResultOverlay is theme-aware or theme-neutral
          overlay: SearchResultOverlay(
            animation: _taggerOverlayAnimation,
            tagController: _tagController,
            // Pass theme if needed: theme: theme,
          ),
          builder: (context, containerKey) {
            // CRITICAL: CommentTextField must be themed internally
            // It should use theme.inputDecorationTheme for its appearance
            // and theme.textTheme for its text style.
            return CommentTextField(
              focusNode: _focusNode,
              containerKey: containerKey,
              insets: viewInsets, // Pass MediaQuery insets
              controller: _tagController,
              hintText: "Add a caption... use @ for topics, # for tags",
              onSend: _onPublish, // Disable button while publishing
              // If CommentTextField takes styling parameters, pass themed values:
              // e.g., hintStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              // sendButtonColor: _isPublishing ? colorScheme.onSurface.withOpacity(0.38) : colorScheme.primary,
            );
          },
        ),
      ),
    );
  }

  Future<void> _onPublish() async {
    if (_isPublishing) return;
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();

    if (_user == null) {
      _showErrorSnackBar('User data not available. Cannot publish.');
      return;
    }
    if (_validImgurUrl.isEmpty && _validYouTubeVideoId.isEmpty) {
      _showErrorSnackBar('Please add an image or video to share.');
      return;
    }

    final String? validationError = _validateTagsAndTopic();
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    if (!mounted) return;
    setState(() => _isPublishing = true);

    String textContent = _tagController.text;
    textContent = _appendMediaUrlToText(textContent);
    final String? topic = _extractTopicFromTags(textContent);

    try {
      // Assuming user.profileIdMemoBch is the correct parameter here
      final response = await MemoModelPost.publishImageOrVideo(textContent, topic);

      if (!mounted) return;

      if (response == MemoAccountantResponse.yes) {
        MemoConfetti().launch(context);
        _clearInputsAfterPublish();
        _showSuccessSnackBar('Successfully published!');
      } else {
        _showErrorSnackBar('Publish failed: ${response.toString()}. Please try again.');
      }
    } catch (e, s) {
      _log("Error during publish: $e\n$s");
      if (mounted) {
        _showErrorSnackBar('An error occurred during publish: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _clearInputsAfterPublish() {
    _tagController.clear();
    _imgurCtrl.clear();
    _youtubeCtrl.clear();
    if (mounted) {
      setState(() {
        _validImgurUrl = "";
        _validYouTubeVideoId = "";
        _disposeYtPlayerController();
      });
    }
  }

  String? _extractTopicFromTags(String rawTextForTopicExtraction) {
    for (Tag t in _tagController.tags) {
      if (t.triggerCharacter == "@") {
        return t.text;
      }
    }
    if (rawTextForTopicExtraction.contains("@")) {
      final words = rawTextForTopicExtraction.split(" ");
      for (String word in words) {
        if (word.startsWith("@") && word.length > 1) {
          return word.substring(1).replaceAll(RegExp(r'[^\w-]'), '');
        }
      }
    }
    return null;
  }

  String _appendMediaUrlToText(String text) {
    if (_validYouTubeVideoId.isNotEmpty) {
      return "$text https://youtu.be/$_validYouTubeVideoId";
    } else if (_validImgurUrl.isNotEmpty) {
      return "$text $_validImgurUrl";
    }
    return text;
  }

  String? _validateTagsAndTopic() {
    final tags = _tagController.tags;
    int topicCount = tags.where((t) => t.triggerCharacter == "@").length;
    int hashtagCount = tags.where((t) => t.triggerCharacter == "#").length;

    if (topicCount > 1) {
      return "Only one @topic is allowed.";
    }
    if (hashtagCount > 3) {
      return "Maximum of 3 #hashtags allowed.";
    }
    if (_tagController.text.trim().isEmpty && (_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty)) {
      return "Please add a caption for your media.";
    }
    // Add other validations like text length if needed
    return null;
  }
}

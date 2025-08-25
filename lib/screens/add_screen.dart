import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:instagram_clone1/memobase/memo_accountant.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/widgets/memo_confetti.dart';
import 'package:instagram_clone1/widgets/textfield_input.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Assuming these exist and are correctly imported
import '../views_taggable/view_models/search_view_model.dart';
import '../views_taggable/widgets/comment_text_field.dart';
import '../views_taggable/widgets/search_result_overlay.dart';

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
  final FocusNode _focusNode = FocusNode(); // This is the _focusNode from your original code

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
  late Animation<Offset> _taggerOverlayAnimation; // Changed from nullable
  final double _taggerOverlayHeight = 300;

  @override
  void initState() {
    super.initState();
    _log("initState started");

    _tagController = FlutterTaggerController(
      text: "I like the topic @Bitcoin#Bitcoin# It's time to earn #bch#bch# and #cashtoken#cashtoken#!",
    );

    _imgurCtrl.addListener(_onImgurInputChanged);
    _youtubeCtrl.addListener(_onYouTubeInputChanged);

    _initStateTagger(); // Initializes _animationController and _taggerOverlayAnimation
    _loadInitialData();
    _log("initState completed");
  }

  Future<void> _loadInitialData() async {
    // ... (logic from previous refactoring: _loadUser, _checkClipboard) ...
    // For brevity, assuming this is the optimized version from before.
    // Ensure setState updates _isLoadingUser and _isCheckingClipboard.
    if (!mounted) return;
    setState(() {
      _isLoadingUser = true;
      _isCheckingClipboard = true;
    });

    try {
      final userFuture = MemoModelUser.getUser();
      final clipboardFuture = _checkClipboard(); // Renamed from checkClipboardHasValidYouTubeOrImgur

      _user = await userFuture;
      await clipboardFuture;
    } catch (e, s) {
      _log("Error during initial data load: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading initial data: ${e.toString()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
          ),
        );
      }
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
    // ... (logic from previous refactoring, includes setState at the end) ...
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
        // _isCheckingClipboard = false; // This is handled in _loadInitialData
      });
    }
    _log("_checkClipboard finished");
  }

  String _extractValidImgurUrl(String url) {
    // Using a slightly more specific regex for i.imgur.com direct links
    final RegExp exp = RegExp(r'^(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)$');
    final match = exp.firstMatch(url.trim());
    if (match != null) {
      return match.group(0)!; // Return the full matched URL
    }
    return "";
  }

  void _onImgurInputChanged() {
    if (!mounted) return;
    final text = _imgurCtrl.text.trim();
    final newImgurUrl = _extractValidImgurUrl(text);

    // Only update if the validity actually changes to avoid unnecessary rebuilds
    if (newImgurUrl != _validImgurUrl) {
      setState(() {
        _validImgurUrl = newImgurUrl;
        if (newImgurUrl.isNotEmpty) {
          if (_validYouTubeVideoId.isNotEmpty) {
            // If user explicitly types Imgur, clear YouTube
            _validYouTubeVideoId = "";
            _youtubeCtrl.clear();
            _disposeYtPlayerController();
          }
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
            // If user explicitly types YouTube, clear Imgur
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
    // ... (logic from previous refactoring) ...
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
          // Consider making controls visible by default for better UX
          // hideControls: false,
        ),
      );
      _currentYouTubeVideoId = _validYouTubeVideoId;
    }
  }

  void _disposeYtPlayerController() {
    // ... (logic from previous refactoring) ...
    _ytPlayerController?.pause(); // Good practice to pause before dispose
    _ytPlayerController?.dispose();
    _ytPlayerController = null;
    _currentYouTubeVideoId = null;
  }

  void _initStateTagger() {
    // _focusNode is already initialized as a final field in your original code
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Slightly faster animation
    );
    _taggerOverlayAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25), // Start a bit closer
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine)); // Smoother curve

    _tagController.addListener(_onTagInputChanged);
  }

  void _onTagInputChanged() {
    // TODOs from original code:
    // CHECK ONLY ONE TOPIC, ONLY ONE @ sign is allowed
    // Check only three hashtags, only three # are allowed
    // These should ideally provide real-time feedback or prevent input if possible,
    // or validate on publish. For now, we'll keep the validation logic for onPublish.
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
    _focusNode.dispose(); // As per your original code
    _disposeYtPlayerController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _log("Build method called");
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final viewInsets = mediaQuery.viewInsets;
    final bool isKeyboardVisible = viewInsets.bottom > 0;

    return GestureDetector(
      onTap: () {
        // This is the original logic for unfocusing, we won't change it.
        _focusNode.unfocus();
        // Also ensure default keyboard dismissal
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor, // Use theme color
        appBar: AppBar(
          title: Text(
            "Create New Post",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: colorScheme.onPrimary),
          ),
          backgroundColor: colorScheme.primary,
          elevation: 1.0, // Softer elevation
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (_isLoadingUser || _isCheckingClipboard)
                const Expanded(
                  // Make loading take full space if it's the only thing
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                _buildMediaInputSection(theme), // Pass theme
              // Taggable input section will be at the bottom or above keyboard
              // No Expanded here to allow it to size itself and be pushed by keyboard
              if (!_isLoadingUser &&
                  !_isCheckingClipboard &&
                  (_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty))
                Padding(
                  // Add padding only when keyboard is not visible to avoid double padding with CommentTextField's internal handling
                  padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 8),
                  child: _buildTaggableInput(theme, viewInsets),
                )
              else if (!_isLoadingUser && !_isCheckingClipboard)
                const Spacer(), // Use Spacer to push content up if no media and no tag input shown
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaInputSection(ThemeData theme) {
    bool showImgurPlaceholder = _validYouTubeVideoId.isEmpty;
    bool showVideoPlaceholder = _validImgurUrl.isEmpty;

    // If one is valid, only show that one expanded.
    // If both are empty, show both side-by-side.

    if (_validImgurUrl.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildMediaDisplay(
            theme: theme,
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
    required String label,
    required IconData iconData,
    required VoidCallback onTap,
  }) {
    return InkWell(
      // Changed from GestureDetector for ripple effect
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3, // Common aspect ratio for placeholders
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 50, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaDisplay({
    required ThemeData theme,
    required String label, // "SELECTED IMAGE" or "SELECTED VIDEO"
    String? mediaUrl,
    YoutubePlayerController? youtubeController,
    required VoidCallback onTap, // To change/remove the media
    required bool isNetworkImage,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min, // Important for Column in Expanded
      children: [
        AspectRatio(
          aspectRatio: 16 / 9, // Standard video/image aspect ratio
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface, // Background for the media
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3), width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11.5),
              child: isNetworkImage
                  ? Image.network(
                      mediaUrl!,
                      fit: BoxFit.contain, // Contain to see full image/video
                      errorBuilder: (context, error, stackTrace) {
                        _log("Error loading Imgur image: $error");
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _validImgurUrl = "");
                          }
                        });
                        return Center(
                          child: Text("Error loading image", style: TextStyle(color: theme.colorScheme.error)),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                        );
                      },
                    )
                  : (youtubeController != null
                        ? YoutubePlayer(
                            controller: youtubeController,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: theme.colorScheme.primary,
                          )
                        : Center(
                            child: Text("Video Player Error", style: TextStyle(color: theme.colorScheme.error)),
                          )),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.secondary),
          label: Text(
            isNetworkImage ? "Change Image" : "Change Video",
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.secondary),
          ),
          onPressed: onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ],
    );
  }

  Future<void> _showImgurDialog() async {
    _showUrlInputDialog("Paste Imgur Image URL", _imgurCtrl, "e.g. https://i.imgur.com/your_image.jpeg", context);
  }

  Future<void> _showVideoDialog() async {
    _showUrlInputDialog("Paste YouTube Video URL", _youtubeCtrl, "e.g. https://youtu.be/your_video_id", context);
  }

  void _showUrlInputDialog(String title, TextEditingController controller, String hint, BuildContext currentContext) {
    final theme = Theme.of(currentContext); // Capture theme from the correct context
    _checkClipboard(); // Ensure clipboard is checked before showing dialog

    showDialog(
      context: currentContext,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Use your custom TextInputField or a standard one
              TextInputField(
                // Assuming this is your custom one. If not, use TextField.
                textEditingController: controller,
                hintText: hint,
                textInputType: TextInputType.url,
                // Add styling if your TextInputField doesn't pick up theme
              ),
              const SizedBox(height: 8),
              Text(
                "Tip: You can often paste a full URL from Imgur or YouTube.",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
            TextButton(
              child: Text(
                'Done',
                style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                // Listener on controller will handle updates
                Navigator.of(dialogCtx).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaggableInput(ThemeData theme, EdgeInsets insets) {
    // This is the original FlutterTagger setup, we are only modifying the styles it uses
    // and the appearance of its container. The _focusNode remains the same.
    return Material(
      // Wrap in Material for elevation and theming consistency
      elevation: 4.0, // Give the input area a slight lift when it appears
      color: theme.canvasColor, // Or theme.cardColor for a slightly different background
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 12,
          // Bottom padding handled by CommentTextField or MediaQuery for keyboard
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : (MediaQuery.of(context).padding.bottom + 12),
        ),
        child: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: _tagController,
          // focusNode: _focusNode, // Using the original _focusNode
          animationController: _animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchTopic(query);
            } else if (triggerChar == "#") {
              searchViewModel.searchHashtag(query);
            }
          },
          triggerCharacterAndStyles: {
            "@": TextStyle(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ), // Use theme color
            "#": TextStyle(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ), // Use theme color
          },
          tagTextFormatter: (id, tag, triggerCharacter) {
            return "$triggerCharacter$id#$tag#"; // Your existing format
          },
          overlayHeight: _taggerOverlayHeight,
          overlay: SearchResultOverlay(
            // Ensure this widget is also styled nicely
            animation: _taggerOverlayAnimation,
            tagController: _tagController,
          ),
          builder: (context, containerKey) {
            // Assuming CommentTextField is your custom widget.
            // You would need to style CommentTextField internally.
            // If CommentTextField is complex, pass theme and colorScheme to it.
            return CommentTextField(
              focusNode: _focusNode, // Using the original _focusNode
              containerKey: containerKey,
              insets: insets,
              controller: _tagController,
              hintText: "Add a caption... use @ for topics, # for tags", // More descriptive hint
              onSend: _onPublish,
              // Potentially pass theme properties to CommentTextField if it supports custom styling
              // e.g., sendButtonColor: _isPublishing ? Colors.grey : theme.colorScheme.primary,
            );
          },
        ),
      ),
    );
  }

  Future<void> _onPublish() async {
    if (_isPublishing) return;
    // ... (logic from previous refactoring, including _focusNode.unfocus()) ...
    // Make sure to use themed SnackBars for feedback.
    _focusNode.unfocus(); // Original focus node logic
    FocusScope.of(context).unfocus();

    if (_user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'User data not available. Cannot publish.',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (_validImgurUrl.isEmpty && _validYouTubeVideoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add an image or video to share.',
            style: TextStyle(color: Theme.of(context).colorScheme.onError),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    // TODO: Implement your tag and topic validation logic here.
    // For example:
    // String? validationError = _validateTagsAndTopic();
    // if (validationError != null) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(validationError), backgroundColor: Theme.of(context).colorScheme.error));
    //   return;
    // }

    if (!mounted) return;
    setState(() => _isPublishing = true);

    String textContent = _tagController.text;
    textContent = _appendMediaUrlToText(textContent);
    final String? topic = _extractTopicFromTags(textContent);

    try {
      final response = await MemoModelPost.publishImageOrVideo(textContent, topic);

      if (!mounted) return;

      if (response == MemoAccountantResponse.yes) {
        MemoConfetti().launch(context);
        _clearInputsAfterPublish();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Successfully published!'), backgroundColor: Colors.green.shade700),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Publish failed: ${response.name}. Please try again.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e, s) {
      _log("Error during publish: $e\n$s");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'An error occurred: ${e.toString()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _clearInputsAfterPublish() {
    // ... (logic from previous refactoring) ...
    _tagController.clear();
    // Optionally clear media:
    // _imgurCtrl.clear();
    // _youtubeCtrl.clear();
    // setState(() {
    //   _validImgurUrl = "";
    //   _validYouTubeVideoId = "";
    //   _disposeYtPlayerController();
    // });
  }

  String? _extractTopicFromTags(String rawTextForTopicExtraction) {
    // ... (logic from previous refactoring) ...
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
    // ... (logic from previous refactoring) ...
    if (_validYouTubeVideoId.isNotEmpty) {
      return "$text https://youtu.be/$_validYouTubeVideoId";
    } else if (_validImgurUrl.isNotEmpty) {
      return "$text $_validImgurUrl";
    }
    return text;
  }

  // Example validation method for tags and topic (TODO implementation)
  String? _validateTagsAndTopic() {
    final tags = _tagController.tags;
    int topicCount = tags.where((t) => t.triggerCharacter == "@").length;
    int hashtagCount = tags.where((t) => t.triggerCharacter == "#").length;

    if (topicCount > 1) {
      return "Only one @topic is allowed.";
    }
    // if (topicCount == 0 && _tagController.text.contains("@")) {
    //   return "Please select a valid @topic or remove the '@' symbol.";
    // }
    if (hashtagCount > 3) {
      return "You can use a maximum of 3 #hashtags.";
    }
    // Add text length validation if needed
    // if (_tagController.text.trim().isEmpty && (_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty)) {
    //   return "Please add a caption for your media.";
    // }
    return null; // No error
  }
}

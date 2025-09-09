import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/screens/pin_claim_screen.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart'; // Ensure this is theme-neutral or adapts
import 'package:mahakka/widgets/textfield_input.dart'; // CRITICAL: This MUST be themed internally
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Assuming these exist and are correctly imported
import '../memo/base/memo_verifier.dart';
import '../memo/base/text_input_verifier.dart';
import '../provider/electrum_provider.dart';
import '../repositories/post_repository.dart';
import '../views_taggable/view_models/search_view_model.dart'; // Ensure SearchViewModel logic is sound
import '../views_taggable/widgets/comment_text_field.dart'; // CRITICAL: This MUST be themed internally
import '../views_taggable/widgets/search_result_overlay.dart'; // Ensure this is theme-aware or neutral

void _log(String message) => print('[AddPost] $message');

class AddPost extends ConsumerStatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPost> createState() => _AddPostState();
}

class _AddPostState extends ConsumerState<AddPost> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _imgurCtrl = TextEditingController();
  final TextEditingController _youtubeCtrl = TextEditingController();
  late FlutterTaggerController _inputTagTopicController;
  late AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();
  // final FocusNode _keyboardFocusNode = FocusNode();

  // State for YouTube Player
  YoutubePlayerController? _ytPlayerController;
  String? _currentYouTubeVideoId;

  // UI State
  // bool _isLoadingUser = true;
  // bool _isCheckingClipboard = true;
  bool _isPublishing = false;

  String _validImgurUrl = "";
  String _validYouTubeVideoId = "";

  late Animation<Offset> _taggerOverlayAnimation;
  final double _taggerOverlayHeight = 300;

  // Assuming searchViewModel is provided or accessible
  // final SearchViewModel searchViewModel = SearchViewModel(); // Replace with actual instance

  @override
  void initState() {
    super.initState();
    _log("initState started");

    _inputTagTopicController = FlutterTaggerController(
      // Example text, consider making it empty or a placeholder
      text: "I like the topic @Bitcoin#Bitcoin# It's time to earn #bch#bch# and #cashtoken#cashtoken#!",
    );

    _imgurCtrl.addListener(_onImgurInputChanged);
    _youtubeCtrl.addListener(_onYouTubeInputChanged);

    _initStateTagger();
    _checkClipboard();

    _log("initState completed");
  }

  Future<void> _checkClipboard() async {
    _log("_checkClipboard started");
    String? newImgurUrl;
    String? newVideoId;
    String? clipboardTextForField;

    try {
      if (await FlutterClipboard.hasData()) {
        final urlFromClipboard = await FlutterClipboard.paste();
        // _log("Clipboard data: $urlFromClipboard");
        final ytId = YoutubePlayer.convertUrlToId(urlFromClipboard);

        if (ytId != null && ytId.isNotEmpty) {
          newVideoId = ytId;
          clipboardTextForField = urlFromClipboard;
        } else {
          final imgur = _extractValidImgurOrGiphyUrl(urlFromClipboard);
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

  String _extractValidImgurOrGiphyUrl(String url) {
    final RegExp exp = RegExp(r'^(https?:\/\/)?(i\.imgur\.com\/)([a-zA-Z0-9]+)\.(jpe?g|png|gif|mp4|webp)$');
    final match = exp.firstMatch(url.trim());
    if (match?.group(0) != null) {
      return match!.group(0)!;
    }

    final RegExp expGiphy = RegExp(r'^(?:https?:\/\/)?(?:[^.]+\.)?giphy\.com(\/.*)?$');
    final matchGiphy = expGiphy.firstMatch(url.trim());

    return matchGiphy?.group(0) ?? ""; // Return the full matched URL or empty
  }

  void _onImgurInputChanged() {
    if (!mounted) return;
    final text = _imgurCtrl.text.trim();
    final newImgurUrl = _extractValidImgurOrGiphyUrl(text);

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
    _inputTagTopicController.addListener(_onTagInputChanged);
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
    _inputTagTopicController.removeListener(_onTagInputChanged);
    _imgurCtrl.dispose();
    _youtubeCtrl.dispose();
    _inputTagTopicController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    // _keyboardFocusNode.dispose();
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
        _unfocusNodes(context);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          // Properties like backgroundColor, foregroundColor, titleTextStyle, elevation
          // will be inherited from theme.appBarTheme.
          // Explicit overrides below are for fine-tuning if needed.
          title: Row(
            children: [
              BurnerBalanceWidget(),
              Spacer(),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse('https://mahakka.com')),
                child: Text("mahakka.com", style: theme.appBarTheme.titleTextStyle),
              ),
            ],
          ),
          // backgroundColor: colorScheme.primary, // Or from theme
          // iconTheme: IconThemeData(color: colorScheme.onPrimary), // Or from theme
        ),
        body: SafeArea(
          child: Column(
            children: [
              // if (_isLoadingUser || _isCheckingClipboard)
              //   const Expanded(
              //     child: Center(child: CircularProgressIndicator()), // Will use theme color
              //   )
              // else
              _buildMediaInputSection(theme, colorScheme, textTheme),

              // if (!_isLoadingUser && !_isCheckingClipboard && (_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty))
              if ((_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty))
                Padding(
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 12, // More padding at bottom
                    left: 12,
                    right: 12,
                    top: 8, // Add some horizontal padding too
                  ),
                  child: _buildTaggableInput(theme, colorScheme, textTheme, mediaQuery.viewInsets),
                ),
              // else if (!_isLoadingUser && !_isCheckingClipboard)
              //   const Spacer(), // Pushes content up if no media and no tag input
            ],
          ),
        ),
      ),
    );
  }

  void _unfocusNodes(BuildContext context) {
    _focusNode.unfocus();
    // _keyboardFocusNode.unfocus();
    FocusScope.of(context).unfocus();
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

  //FILES THAT ARE UPLOADED SUCCESSFULLY ARE DISPLAYED ON https://free-bch.fullstack.cash/ipfs/view/${cid}
  _showIpfsUploadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinClaimScreen(
          wallet: ref.read(electrumServiceProvider).value!,
          serverUrl: 'https://file-stage.fullstack.cash',
          mnemonic: ref.read(userProvider)!.mnemonic,
        ),
      ),
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
      color: theme.cardColor,
      shadowColor: theme.shadowColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        // child: RawKeyboardListener(
        //   // Use a dedicated FocusNode for the keyboard listener.
        //   focusNode: _keyboardFocusNode,
        //   onKey: (RawKeyEvent event) {
        //     // Only handle key downs, not key ups.
        //     if (event is RawKeyDownEvent) {
        //       _handleAutocompleteKeys(event);
        //     }
        //   },
        child: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: _inputTagTopicController,
          animationController: _animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchTopic(query);
            } else if (triggerChar == "#") {
              searchViewModel.searchHashtag(query);
            }
          },
          triggerCharacterAndStyles: {
            "@": textTheme.bodyLarge!.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold),
            "#": textTheme.bodyLarge!.copyWith(color: colorScheme.tertiary, fontWeight: FontWeight.bold),
          },
          tagTextFormatter: (id, tag, triggerChar) {
            return "$triggerChar$id#$tag#";
          },
          overlayHeight: _taggerOverlayHeight,
          overlay: SearchResultOverlay(animation: _taggerOverlayAnimation, tagController: _inputTagTopicController),
          builder: (context, containerKey) {
            return CommentTextField(
              // The main text field still uses its own focus node for input.
              focusNode: _focusNode,
              containerKey: containerKey,
              insets: viewInsets,
              controller: _inputTagTopicController,
              hintText: "Add a caption... use @ for topics, # for tags",
              onSend: _onPublish,
            );
          },
        ),
      ),
      // ),
    );
  }

  // void _handleAutocompleteKeys(RawKeyEvent event) {
  //   // Check if the pressed key is the space key.
  //   if (event.isKeyPressed(LogicalKeyboardKey.space)) {
  //     // Determine which list of results to use based on the current active view.
  //     final List<dynamic> results;
  //     if (searchViewModel.activeView.value == SearchResultView.topics) {
  //       results = searchViewModel.topics.value;
  //     } else if (searchViewModel.activeView.value == SearchResultView.hashtag) {
  //       results = searchViewModel.hashtags.value;
  //     } else {
  //       // No active search, do nothing.
  //       return;
  //     }
  //
  //     // Only autocomplete if there is exactly one suggestion available.
  //     if (results.length == 1) {
  //       _doAutocomplete(results.first);
  //     }
  //   }
  // }

  // Place this method inside your _AddPostState class
  // void _doAutocomplete(dynamic result) {
  //   final TextEditingValue currentValue = _inputTagTopicController.value;
  //   final String text = currentValue.text;
  //   final int cursorPosition = currentValue.selection.baseOffset;
  //
  //   // Find the start of the current word by looking for the last trigger character.
  //   final int queryStartIndex = text.lastIndexOf(RegExp(r'[@#]'), cursorPosition - 1);
  //
  //   if (queryStartIndex == -1) {
  //     return; // No trigger character found, so do nothing.
  //   }
  //
  //   // Extract the text that comes BEFORE the incomplete tag.
  //   final String textBeforeTag = text.substring(0, queryStartIndex);
  //
  //   // Extract the text that comes AFTER the cursor.
  //   final String textAfterCursor = text.substring(cursorPosition);
  //
  //   // Get the trigger character.
  //   final String triggerChar = text[queryStartIndex];
  //
  //   // Generate the new, fully formatted tag text (e.g., "#id#bitcoinabc#").
  //   final String newTagText = _formatTagText(result, triggerChar);
  //
  //   // Combine all three parts: text before, new tag, and text after.
  //   // Add a space after the new tag to make it easier to continue typing.
  //   final String newText = textBeforeTag + newTagText + "" + textAfterCursor;
  //
  //   // Update the controller with the new, corrected string.
  //   _inputTagTopicController.value = TextEditingValue(
  //     text: newText,
  //     // Place the cursor at the end of the newly inserted tag.
  //     selection: TextSelection.collapsed(offset: (textBeforeTag + newTagText + "").length),
  //   );
  // }
  //
  // // Helper method remains the same.
  // String _formatTagText(dynamic result, String triggerChar) {
  //   final id = result.id;
  //   // final tagText = result.name;
  //   return "$triggerChar$id";
  // }

  Future<void> _onPublish() async {
    if (_isPublishing) return;
    _unfocusNodes(context);

    // if (_user == null) {
    //   _showErrorSnackBar('User data not available. Cannot publish.');
    //   return;
    // }
    if (_validImgurUrl.isEmpty && _validYouTubeVideoId.isEmpty) {
      _showErrorSnackBar('Please add an image or video to share.');
      return;
    }

    //TODO REMOVE DUPLICATE VERIFICATION
    final String? validationError = _validateTagsAndTopic();
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    if (!mounted) return;
    setState(() => _isPublishing = true);

    String textContent = _inputTagTopicController.text;

    //TODO remove duplicate verification
    final verifier = MemoVerifierDecorator(textContent)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyOffensiveWords);

    final result = verifier.getResult();

    // Pass the verification result to the response handler
    if (result != MemoVerificationResponse.valid) {
      _showErrorSnackBar('Publish failed: ${result.toString()}. Please try again.');
      return;
    }

    textContent = _appendMediaUrlToText(textContent);
    final String? topic = _extractTopicFromTags(textContent);

    try {
      final postRepository = ref.read(postRepositoryProvider);
      // Assuming user.profileIdMemoBch is the correct parameter here
      final response = await postRepository.publishImageOrVideo(textContent, topic, validate: false);

      if (!mounted) return;

      if (response == MemoAccountantResponse.yes) {
        MemoConfetti().launch(context);
        _clearInputsAfterPublish();
        _showSuccessSnackBar('Successfully published!');
      } else {
        showQrCodeDialog(context: context, theme: Theme.of(context), user: ref.read(userProvider), memoOnly: true);
        _showErrorSnackBar('Publish failed: ${response.toString()}');
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
    _inputTagTopicController.clear();
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
    for (Tag t in _inputTagTopicController.tags) {
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
    final tags = _inputTagTopicController.tags;
    int topicCount = tags.where((t) => t.triggerCharacter == "@").length;
    int hashtagCount = tags.where((t) => t.triggerCharacter == "#").length;

    if (topicCount > 1) {
      return "Only one @topic is allowed.";
    }
    if (hashtagCount > 3) {
      return "Maximum of 3 #hashtags allowed.";
    }
    if (_inputTagTopicController.text.trim().isEmpty && (_validImgurUrl.isNotEmpty || _validYouTubeVideoId.isNotEmpty)) {
      return "Please add a caption for your media.";
    }
    // Add other validations like text length if needed
    return null;
  }
}

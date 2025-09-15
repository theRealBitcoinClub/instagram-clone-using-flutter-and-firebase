import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/memo/base/memo_accountant.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/screens/pin_claim_screen.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:mahakka/widgets/memo_confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Assuming these exist and are correctly imported
import '../config_ipfs.dart';
import '../memo/base/memo_verifier.dart';
import '../memo/base/text_input_verifier.dart';
// Import the Odysee widgets and providers
import '../memo/model/memo_model_post.dart';
import '../repositories/post_repository.dart';
import '../views_taggable/view_models/search_view_model.dart';
import '../views_taggable/widgets/comment_text_field.dart';
import '../views_taggable/widgets/search_result_overlay.dart';
import '../widgets/add/publish_confirmation_activity.dart';
import 'add/add_post_providers.dart';
import 'add/clipboard_monitoring_dialog.dart';
import 'add/clipboard_provider.dart';
import 'add/imgur_media_widget.dart';
import 'add/ipfs_media_widget.dart';
import 'add/odysee_media_widget.dart';
import 'add/youtube_media_widget.dart';

void _log(String message) => print('[AddPost] $message');

class AddPost extends ConsumerStatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPost> createState() => _AddPostState();
}

class _AddPostState extends ConsumerState<AddPost> with TickerProviderStateMixin {
  bool hasInitialized = false;
  // Controllers
  final TextEditingController _imgurCtrl = TextEditingController();
  final TextEditingController _youtubeCtrl = TextEditingController();
  final TextEditingController _ipfsCtrl = TextEditingController();
  final TextEditingController _odyseeCtrl = TextEditingController();
  late FlutterTaggerController _textInputController;
  late AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();

  // UI State
  late Animation<Offset> _taggerOverlayAnimation;
  final double _taggerOverlayHeight = 300;

  @override
  void initState() {
    super.initState();
    _log("initState started");

    _textInputController = FlutterTaggerController(text: "Me gusta @Mahakka#Mahakka# Es hora de ganar #bch#bch# y #cashtoken#cashtoken#!");

    _youtubeCtrl.addListener(_onYouTubeInputChanged);
    _imgurCtrl.addListener(_onImgurInputChanged);
    // _ipfsCtrl.addListener(_onIpfsInputChanged);
    _odyseeCtrl.addListener(_onOdyseeInputChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
    });

    _initStateTagger();

    _log("initState completed");
  }

  void _onImgurInputChanged() {
    if (!mounted) return;
    final text = _imgurCtrl.text.trim();
    String newImgurUrl = MemoRegExp(text).extractValidImgurOrGiphyUrl();

    // var read = ref.read(imgurUrlProvider);
    // if (newImgurUrl != read) {
    if (newImgurUrl.isNotEmpty) {
      ref.read(imgurUrlProvider.notifier).state = newImgurUrl;
      _clearOtherMediaProviders(0);
    } else {
      tryAdvancedImgurCheck();
    }
    // }
  }

  Future<void> tryAdvancedImgurCheck() async {
    final text = _imgurCtrl.text.trim();
    final newImgurUrl = await MemoVerifier(text).verifyAndBuildImgurUrl();

    if (newImgurUrl != MemoVerificationResponse.noImageNorVideo.toString()) {
      ref.read(imgurUrlProvider.notifier).state = newImgurUrl;
      _clearOtherMediaProviders(0);
    }
  }

  void _onYouTubeInputChanged() {
    if (!mounted) return;
    final text = _youtubeCtrl.text.trim();
    final newVideoId = YoutubePlayer.convertUrlToId(text);

    // if ((newVideoId ?? "") != ref.read(youtubeVideoIdProvider)) {
    if (newVideoId != null && newVideoId.isNotEmpty) {
      ref.read(youtubeVideoIdProvider.notifier).state = newVideoId;
      _clearOtherMediaProviders(1);
    }
    // else {
    //   ref.read(youtubeVideoIdProvider.notifier).state = "";
    // }
    // }
  }

  // void _onIpfsInputChanged() {
  //   if (!mounted) return;
  //   final text = _ipfsCtrl.text.trim();
  //   final newIpfsCid = MemoRegExp(text).extractIpfsCid();
  //
  //   // if (newIpfsCid != ref.read(ipfsCidProvider)) {
  //   if (newIpfsCid.isNotEmpty) {
  //     ref.read(ipfsCidProvider.notifier).state = newIpfsCid;
  //     _clearOtherMediaProviders(2);
  //   }
  //   // }
  // }

  void _onOdyseeInputChanged() {
    if (!mounted) return;
    final text = _odyseeCtrl.text.trim();
    final newOdyseeUrl = MemoRegExp(text).extractOdyseeUrl();

    // if (newOdyseeUrl != ref.read(odyseeUrlProvider)) {
    if (newOdyseeUrl.isNotEmpty) {
      ref.read(odyseeUrlProvider.notifier).state = newOdyseeUrl;
      _clearOtherMediaProviders(3);
    }
    // }
  }

  void _clearOtherMediaProviders(int index) {
    if (index != 0) ref.read(imgurUrlProvider.notifier).state = "";
    if (index != 1) ref.read(youtubeVideoIdProvider.notifier).state = "";
    if (index != 2) ref.read(ipfsCidProvider.notifier).state = "";
    if (index != 3) ref.read(odyseeUrlProvider.notifier).state = "";
  }

  void _initStateTagger() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _taggerOverlayAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine));
    _textInputController.addListener(_onTagInputChanged);
  }

  void _onTagInputChanged() {
    // Future(() {});
    // if (hasInitialized) ref.read(tagTextProvider.notifier).state = _inputTagTopicController.text;
  }

  @override
  void dispose() {
    _log("Dispose called");
    _imgurCtrl.removeListener(_onImgurInputChanged);
    _youtubeCtrl.removeListener(_onYouTubeInputChanged);
    // _ipfsCtrl.removeListener(_onIpfsInputChanged);
    _odyseeCtrl.removeListener(_onOdyseeInputChanged);
    _imgurCtrl.dispose();
    _youtubeCtrl.dispose();
    _ipfsCtrl.dispose();
    _odyseeCtrl.dispose();
    _textInputController.removeListener(_onTagInputChanged);
    _textInputController.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    showSnackBar(message, context, type: SnackbarType.error);
  }

  void _showSuccessSnackBar(String message) {
    showSnackBar(message, context, type: SnackbarType.success);
  }

  @override
  Widget build(BuildContext context) {
    _log("Build method called");
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
    hasInitialized = true;

    return GestureDetector(
      onTap: () {
        _unfocusNodes(context);
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 50,
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
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildMediaInputSection(theme, colorScheme, textTheme),
              if (_hasMediaSelected())
                Padding(
                  padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 12, left: 12, right: 12, top: 8),
                  child: _buildTaggableInput(theme, colorScheme, textTheme, mediaQuery.viewInsets),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasMediaSelected() {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    return imgurUrl.isNotEmpty || youtubeId.isNotEmpty || ipfsCid.isNotEmpty || odyseeUrl.isNotEmpty;
  }

  void _unfocusNodes(BuildContext context) {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Widget _buildMediaInputSection(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    final imgurUrl = ref.watch(imgurUrlProvider);
    final youtubeId = ref.watch(youtubeVideoIdProvider);
    final ipfsCid = ref.watch(ipfsCidProvider);
    final odyseeUrl = ref.watch(odyseeUrlProvider);

    if (imgurUrl.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ImgurMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme),
        ),
      );
    }

    if (youtubeId.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: YouTubeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme),
        ),
      );
    }

    if (ipfsCid.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: IpfsMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme),
        ),
      );
    }

    if (odyseeUrl.isNotEmpty) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: OdyseeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme),
        ),
      );
    }

    // All are empty, show placeholders for all four options in two rows
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        children: [
          // First row: IMGUR & YOUTUBE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediaPlaceholder(
                theme: theme,
                colorScheme: colorScheme,
                textTheme: textTheme,
                label: "IMGUR",
                iconData: Icons.add_photo_alternate_outlined,
                onTap: _showImgurDialog,
              ),
              const SizedBox(width: 16),
              _buildMediaPlaceholder(
                theme: theme,
                colorScheme: colorScheme,
                textTheme: textTheme,
                label: "YOUTUBE",
                iconData: Icons.video_call_outlined,
                onTap: _showVideoDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Second row: IPFS & ODYSEE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMediaPlaceholder(
                theme: theme,
                colorScheme: colorScheme,
                textTheme: textTheme,
                label: "IPFS",
                iconData: Icons.cloud_upload_outlined,
                onTap: _showIpfsUploadScreen,
              ),
              const SizedBox(width: 16),
              _buildMediaPlaceholder(
                theme: theme,
                colorScheme: colorScheme,
                textTheme: textTheme,
                label: "ODYSEE",
                iconData: Icons.video_library_outlined,
                onTap: _showOdyseeDialog,
              ),
            ],
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(iconData, size: 60, color: colorScheme.primary),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showIpfsUploadScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const PinClaimScreen())).then((result) {
      if (result != null) {
        final cid = result['cid'];
        if (cid != null && mounted) {
          ref.read(ipfsCidProvider.notifier).state = cid.toString().trim();
          _clearOtherMediaProviders(2);
        }
      }
    });
  }

  Future<void> _showImgurDialog() async {
    _showUrlInputDialog("Paste Imgur Image URL", _imgurCtrl, "e.g. https://i.imgur.com/image.jpeg");
  }

  Future<void> _showVideoDialog() async {
    _showUrlInputDialog("Paste YouTube Video URL", _youtubeCtrl, "e.g. https://youtu.be/video_id");
  }

  Future<void> _showIpfsDialog() async {
    _showUrlInputDialog("Paste IPFS CID", _ipfsCtrl, "e.g. QmXoypizjW3WknFiJnKLwHCnL72vedxjQkDDP1mXWo6uco");
  }

  Future<void> _showOdyseeDialog() async {
    _showUrlInputDialog("Paste Odysee Video URL", _odyseeCtrl, "e.g. https://odysee.com/@BitcoinMap:9/HijackingBitcoin:73");
  }

  void _showUrlInputDialog(String title, TextEditingController controller, String hint) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    ref.watch(clipboardNotifierProvider.notifier).checkClipboard(ref);

    showDialog(
      context: context,
      builder: (dialogCtx) => ClipboardMonitoringDialog(
        title: title,
        controller: controller,
        hint: hint,
        theme: theme,
        textTheme: textTheme,
        onClearInputs: _clearInputs,
      ),
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
        child: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: _textInputController,
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
          overlay: SearchResultOverlay(animation: _taggerOverlayAnimation, tagController: _textInputController),
          builder: (context, containerKey) {
            return CommentTextField(
              onInputText: (value) {
                if (!mounted) return;
                if (value.contains('\n')) {
                  _textInputController.text = value.replaceAll("\n", "");
                  _onPublish();
                }
              },
              focusNode: _focusNode,
              containerKey: containerKey,
              insets: viewInsets,
              controller: _textInputController,
              hintText: "Add a caption... use @ for topics, # for tags",
              onSend: _onPublish,
            );
          },
        ),
      ),
    );
  }

  MemoModelPost _createPostFromCurrentState(String textContent, String? topic) {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    return MemoModelPost(
      id: null, // Will be generated on publish
      text: textContent,
      imgurUrl: imgurUrl.isNotEmpty ? imgurUrl : null,
      youtubeId: youtubeId.isNotEmpty ? youtubeId : null,
      imageUrl: null, // You might need to handle this based on your media selection
      videoUrl: odyseeUrl.isNotEmpty ? odyseeUrl : null,
      ipfsCid: ipfsCid.isNotEmpty ? ipfsCid : null,
      tagIds: MemoRegExp.extractHashtags(textContent),
      topicId: topic ?? "",
      topic: topic != null ? MemoModelTopic(id: topic) : null,
      creator: ref.read(userProvider)!.creator,
      creatorId: ref.read(userProvider)!.id,
    );
  }

  Future<void> _onPublish() async {
    final isPublishing = ref.read(isPublishingProvider);
    if (isPublishing) return;
    // _unfocusNodes(context);

    if (!_hasMediaSelected()) {
      _showErrorSnackBar('Please add an image or video to share.');
      return;
    }

    final String? validationError = _validateTagsAndTopic();
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    ref.read(isPublishingProvider.notifier).state = true;

    String textContent = _textInputController.text;

    MemoVerificationResponse result = _handleVerification(textContent);

    if (result != MemoVerificationResponse.valid) {
      _showErrorSnackBar('${result.message}');
      ref.read(isPublishingProvider.notifier).state = false;
      return;
    }

    textContent = _appendMediaUrlToText(textContent);
    // final String? topic = _extractTopicFromTags(textContent);
    final String topic = MemoRegExp.extractTopics(textContent).isNotEmpty ? MemoRegExp.extractTopics(textContent).first : "";

    try {
      // Create the post object for confirmation screen
      final post = _createPostFromCurrentState(textContent, topic);
      final user = ref.read(userProvider)!;

      // Show confirmation screen and wait for result
      final bool shouldPublish = (await PublishConfirmationActivity.show(context, post: post))!;

      if (!mounted) return;

      if (shouldPublish) {
        // User confirmed, proceed with publishing
        final postRepository = ref.read(postRepositoryProvider);
        final response = await postRepository.publishImageOrVideo(textContent, topic, validate: false);

        if (!mounted) return;

        if (response == MemoAccountantResponse.yes) {
          MemoConfetti().launch(context);
          _clearInputs();
          _showSuccessSnackBar('Successfully published!');
        } else {
          // _focusNode.requestFocus(); // Refocus on error
          showQrCodeDialog(context: context, theme: Theme.of(context), user: user, memoOnly: true);
          _showErrorSnackBar('Publish failed: ${response.message}');
        }
      } else {
        // _focusNode.requestFocus(); // Refocus on error
        showSnackBar(type: SnackbarType.info, 'Publication canceled', context);
      }
      // If shouldPublish is null, the screen was closed by other means (back button)
    } catch (e, s) {
      // _focusNode.requestFocus(); // Refocus on error
      _log("Error during publish: $e\n$s");
      if (mounted) {
        _showErrorSnackBar('Error during publish: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        ref.read(userProvider)!.temporaryTipReceiver = null;
        ref.read(userProvider)!.temporaryTipAmount = null;
        ref.read(isPublishingProvider.notifier).state = false;
      }
    }
  }

  MemoVerificationResponse _handleVerification(String textContent) {
    final verifier = MemoVerifierDecorator(textContent)
        .addValidator(InputValidators.verifyPostLength)
        .addValidator(InputValidators.verifyMinWordCount)
        .addValidator(InputValidators.verifyHashtags)
        .addValidator(InputValidators.verifyNoTopicNorTag)
        .addValidator(InputValidators.verifyTopics)
        .addValidator(InputValidators.verifyUrl)
        .addValidator(InputValidators.verifyOffensiveWords);

    final result = verifier.getResult();
    return result;
  }

  // String? _extractTopicFromTags(String rawTextForTopicExtraction) {
  //   for (Tag t in _textInputController.tags) {
  //     if (t.triggerCharacter == "@") {
  //       return t.text;
  //     }
  //   }
  //   if (rawTextForTopicExtraction.contains("@")) {
  //     final words = rawTextForTopicExtraction.split(" ");
  //     for (String word in words) {
  //       if (word.startsWith("@") && word.length > 1) {
  //         return word.substring(1).replaceAll(RegExp(r'[^\w-]'), '');
  //       }
  //     }
  //   }
  //   return null;
  // }

  String _appendMediaUrlToText(String text) {
    final imgurUrl = ref.read(imgurUrlProvider);
    final youtubeId = ref.read(youtubeVideoIdProvider);
    final ipfsCid = ref.read(ipfsCidProvider);
    final odyseeUrl = ref.read(odyseeUrlProvider);

    if (youtubeId.isNotEmpty) {
      return "$text https://youtu.be/$youtubeId";
    } else if (imgurUrl.isNotEmpty) {
      return "$text $imgurUrl";
    } else if (ipfsCid.isNotEmpty) {
      return "$text ${IpfsConfig.preferredNode}$ipfsCid";
    } else if (odyseeUrl.isNotEmpty) {
      return "$text $odyseeUrl";
    }
    return text;
  }

  String? _validateTagsAndTopic() {
    final tags = _textInputController.tags;
    int topicCount = tags.where((t) => t.triggerCharacter == "@").length;
    int hashtagCount = tags.where((t) => t.triggerCharacter == "#").length;

    if (topicCount > 1) {
      return "Only one @topic is allowed.";
    }
    if (hashtagCount > 3) {
      return "Maximum of 3 #hashtags allowed.";
    }
    if (_textInputController.text.trim().isEmpty && _hasMediaSelected()) {
      return "Please add a caption for your media.";
    }
    return null;
  }

  void _clearInputs() {
    _textInputController.clear();
    _imgurCtrl.clear();
    _youtubeCtrl.clear();
    _ipfsCtrl.clear();
    _odyseeCtrl.clear();
    ref.read(imgurUrlProvider.notifier).state = '';
    ref.read(youtubeVideoIdProvider.notifier).state = '';
    ref.read(ipfsCidProvider.notifier).state = '';
    ref.read(odyseeUrlProvider.notifier).state = '';
    // ref.read(youtubeControllerProvider.notifier).state = null;
  }
}

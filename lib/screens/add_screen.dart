import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme_provider.dart';
import 'add/add_post_providers.dart';
import 'add/clipboard_monitoring_widget.dart';
import 'add/clipboard_provider.dart';
import 'add/imgur_media_widget.dart';
import 'add/ipfs_media_widget.dart';
import 'add/media_selector_widget.dart';
import 'add/odysee_media_widget.dart';
import 'add/taggable_input_widget.dart';
import 'add/youtube_media_widget.dart';
import 'add_post_controller.dart';

void _log(String message) => print('[AddPost] $message');

class AddPost extends ConsumerStatefulWidget {
  const AddPost({Key? key}) : super(key: key);

  @override
  ConsumerState<AddPost> createState() => _AddPostState();
}

class _AddPostState extends ConsumerState<AddPost> with TickerProviderStateMixin {
  bool hasInitialized = false;
  // Controllers
  late FlutterTaggerController _textInputController;
  late AnimationController _animationController;
  final FocusNode _focusNode = FocusNode();

  // UI State
  late Animation<Offset> _taggerOverlayAnimation;

  // AddPostController instance
  late AddPostController _addPostController;

  String _title = "";
  String _hint = "";
  var _onCreateCallback;
  var _onGalleryCallback;

  @override
  void initState() {
    super.initState();
    _log("initState started");

    _textInputController = FlutterTaggerController(text: "Me gusta @Mahakka#Mahakka# Es hora de ganar #bch#bch# y #cashtoken#cashtoken#!");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
    });

    _initStateTagger();

    // Initialize the controller
    _addPostController = AddPostController(
      ref: ref,
      context: context,
      onPublish: _onPublish,
      showErrorSnackBar: _showErrorSnackBar,
      showSuccessSnackBar: _showSuccessSnackBar,
      log: _log,
    );

    _log("initState completed");
  }

  void _initStateTagger() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _taggerOverlayAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _log("Dispose called");
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

  Widget _buildMenuTheme(ThemeState themeState, ThemeData theme) {
    return IconButton(
      icon: Icon(themeState.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      tooltip: "Toggle Theme",
      onPressed: () {
        ref.read(themeNotifierProvider.notifier).toggleTheme();
      },
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
    // WidgetsFlutterBinding.add
    // ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
    hasInitialized = true;
    final asyncThemeState = ref.watch(themeNotifierProvider);
    final ThemeState currentThemeState = asyncThemeState.maybeWhen(data: (data) => data, orElse: () => defaultThemeState);

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
          actions: [_buildMenuTheme(currentThemeState, theme)],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _buildMediaInputSection(theme, colorScheme, textTheme),
              AnimatedGrowFadeIn(
                show: !_hasAddedMediaToPublish(),
                child: ClipboardMonitoringWidget(title: _title, hint: _hint, onCreate: _onCreateCallback, onGallery: _onGalleryCallback),
              ),
              if (_hasAddedMediaToPublish())
                Padding(
                  padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 12, left: 12, right: 12, top: 8),
                  child: TaggableInputWidget(
                    textInputController: _textInputController,
                    animationController: _animationController,
                    focusNode: _focusNode,
                    viewInsets: MediaQuery.of(context).viewInsets,
                    onPublish: _onPublish,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _unfocusNodes(BuildContext context) {
    _focusNode.unfocus();
    FocusScope.of(context).unfocus();
  }

  Widget _buildMediaInputSection(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme, {double space = 16}) {
    final imgurUrl = ref.watch(imgurUrlProvider);
    final youtubeId = ref.watch(youtubeVideoIdProvider);
    final ipfsCid = ref.watch(ipfsCidProvider);
    final odyseeUrl = ref.watch(odyseeUrlProvider);

    // Define reusable padding constants
    final EdgeInsets mediaPadding = EdgeInsets.all(space);
    final EdgeInsets placeholderPadding = EdgeInsets.symmetric(horizontal: space / 2, vertical: space);
    final double spacerWidth = space / 2;
    final double spacerHeight = space;

    // Check for media content and return appropriate widget
    final mediaWidget = _getMediaWidget(imgurUrl, youtubeId, ipfsCid, odyseeUrl, theme, colorScheme, textTheme);
    if (mediaWidget != null) {
      return Expanded(
        child: Padding(padding: mediaPadding, child: mediaWidget),
      );
    }

    // All are empty, show placeholders
    return Padding(
      padding: placeholderPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaSelectorWidget(
            label: "IMGUR",
            iconData: Icons.add_photo_alternate_outlined,
            onTap: () => updateTitleAndHint("Paste Imgur URL", "e.g. https://i.imgur.com/image.jpeg"),
          ),
          SizedBox(width: spacerWidth),
          MediaSelectorWidget(
            label: "YOUTUBE",
            iconData: Icons.video_call_outlined,
            onTap: () => updateTitleAndHint("Paste YouTube URL", "e.g. https://youtu.be/video_id"),
          ),
          SizedBox(width: spacerWidth),
          MediaSelectorWidget(
            label: "IPFS",
            iconData: Icons.cloud_upload_outlined,
            onTap: () => updateTitleAndHint("Paste Ipfs id or create one", "e.g. bafkreieujaprdsulpf5uufjndg4zeknpmhcffy7jophvv7ebcax46w2q74"),
          ),
          SizedBox(width: spacerWidth),
          MediaSelectorWidget(
            label: "ODYSEE",
            iconData: Icons.video_library_outlined,
            onTap: () => updateTitleAndHint("Paste Odysee URL", "e.g. https://odysee.com/@BitcoinMap:9/HijackingBitcoin:73"),
          ),
        ],
      ),
    );
  }

  // Helper method to get the appropriate media widget
  Widget? _getMediaWidget(
    String imgurUrl,
    String youtubeId,
    String ipfsCid,
    String odyseeUrl,
    ThemeData theme,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (imgurUrl.isNotEmpty) {
      return ImgurMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme);
    }
    if (youtubeId.isNotEmpty) {
      return YouTubeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme);
    }
    if (ipfsCid.isNotEmpty) {
      return IpfsMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme);
    }
    if (odyseeUrl.isNotEmpty) {
      return OdyseeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme);
    }
    return null;
  }

  void updateTitleAndHint(String title, String hint) {
    setState(() {
      _title = title;
      _hint = hint;
      _onCreateCallback = title.toLowerCase().contains('ipfs') ? _showIpfsUploadScreen : null;
      _onGalleryCallback = title.toLowerCase().contains('ipfs') ? _showIpfsGallery : null;
    });
  }

  // Add these methods to _AddPostState
  void _showIpfsGallery() {
    _addPostController.showIpfsGallery();
  }

  void _showIpfsUploadScreen() {
    _addPostController.showIpfsUploadScreen();
  }

  Future<void> _onPublish() async {
    if (!mounted) return;
    await _addPostController.publishPost(_textInputController.text);
  }

  // Update the _hasAddedMediaToPublish method to use the controller
  bool _hasAddedMediaToPublish() {
    return _addPostController.hasAddedMediaToPublish();
  }
}

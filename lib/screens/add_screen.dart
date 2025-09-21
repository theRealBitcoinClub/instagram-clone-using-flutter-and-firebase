import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/media_selection_notifier.dart';
import '../theme_provider.dart';
import '../widgets/media_type_selector.dart';
import 'add/add_post_providers.dart';
import 'add/clipboard_monitoring_widget.dart';
import 'add/clipboard_provider.dart';
import 'add/imgur_media_widget.dart';
import 'add/ipfs_media_widget.dart';
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

  String _title = "Select a media type or paste a link";
  String _hint = "e.g. any media url or ipfs content id";
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
    // _log("Build method called");
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
    final selectionState = ref.watch(mediaSelectionProvider);

    // Check for media content and return appropriate widget
    final mediaWidget = _getMediaWidget(imgurUrl, youtubeId, ipfsCid, odyseeUrl, theme, colorScheme, textTheme);
    if (mediaWidget != null) {
      // Clear selection when media is actually loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(mediaSelectionProvider.notifier).clearSelection();
      });
      return Expanded(
        child: Padding(padding: EdgeInsets.all(space), child: mediaWidget),
      );
    }

    // All are empty, show media type selector
    return MediaTypeSelector(
      onMediaTypeSelected: (mediaType) {
        updateTitleAndHint(mediaType.title, mediaType.hint);
      },
      // onIpfsCreate: _showIpfsUploadScreen,
      // onIpfsGallery: _showIpfsGallery,
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
      // Only set callbacks for IPFS (they're handled by the selector directly)
      if (title.toUpperCase().contains('IPFS')) {
        _onCreateCallback = _showIpfsUploadScreen;
        _onGalleryCallback = _showIpfsGallery;
      } else {
        _onCreateCallback = null;
        _onGalleryCallback = null;
      }
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

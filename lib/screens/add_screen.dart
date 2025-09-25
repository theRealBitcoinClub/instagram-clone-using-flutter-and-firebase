import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
import 'package:mahakka/widgets/burner_balance_widget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../provider/media_selection_notifier.dart';
import '../theme_provider.dart';
import '../views_taggable/taggable_providers.dart';
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
  String _title = "Select a media type or paste a link";
  String _hint = "e.g. any media url or ipfs content id";
  var _onCreateCallback;
  var _onGalleryCallback;
  // late AnimationController _animationController; // Local controller

  @override
  void initState() {
    super.initState();
    _log("initState started");
    // _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));

    context.afterBuild(refreshUI: false, () {
      // ref.read(animationControllerNotifierProvider.notifier).initialize(this);
      ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
      final controller = ref.read(addPostControllerProvider.notifier);
      controller.setContext(context);
    });

    // context.afterLayout(() {
    // }, refreshUI: false);
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // });
    _log("initState completed");
  }

  @override
  void dispose() {
    // _animationController.dispose(); // Dispose local controller
    super.dispose();
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
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
    final asyncThemeState = ref.watch(themeNotifierProvider);
    final ThemeState currentThemeState = asyncThemeState.maybeWhen(data: (data) => data, orElse: () => defaultThemeState);

    return GestureDetector(
      onTap: () {
        _unfocusNodes(context);
      },
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 50,
          title: Row(
            children: [
              BurnerBalanceWidget(),
              Spacer(),
              GestureDetector(
                onTap: () {
                  launchUrl(Uri.parse('https://mahakka.com'));
                },
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
                  padding: EdgeInsets.only(bottom: isKeyboardVisible ? 0 : mediaQuery.padding.bottom + 2, left: 4, right: 4, top: 8),
                  child: TaggableInputWidget(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _unfocusNodes(BuildContext context) {
    final focusNode = ref.read(focusNodeProvider);
    focusNode.unfocus();
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

  void _showIpfsGallery() {
    ref.read(addPostControllerProvider.notifier).showIpfsGallery();
  }

  void _showIpfsUploadScreen() {
    ref.read(addPostControllerProvider.notifier).showIpfsUploadScreen();
  }

  bool _hasAddedMediaToPublish() {
    return ref.read(addPostControllerProvider.notifier).hasAddedMediaToPublish();
  }
}

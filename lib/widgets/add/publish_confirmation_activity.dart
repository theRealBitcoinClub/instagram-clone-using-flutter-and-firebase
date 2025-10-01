import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/add/tip_information_card.dart';
import 'package:mahakka/widgets/add/translation_widget.dart';

import '../../memo/model/memo_model_post.dart';
import '../../memo/model/memo_model_user.dart';
import '../../provider/translation_service.dart';
import '../../provider/user_provider.dart';
import '../../screens/add/imgur_media_widget.dart';
import '../../screens/add/ipfs_media_widget.dart';
import '../../screens/add/odysee_media_widget.dart';
import '../../screens/add/youtube_media_widget.dart';
import '../hashtag_display_widget.dart';
import '../profile/settings_widget.dart';
import 'delete_confirmation_dialog.dart';

// Assuming you have a userProvider defined elsewhere
// final userProvider = StateProvider<MemoModelUser>((ref) => MemoModelUser());

class PublishConfirmationActivity extends ConsumerStatefulWidget {
  final MemoModelPost post;
  final bool isPostCreationNotReply;

  const PublishConfirmationActivity({Key? key, required this.post, required this.isPostCreationNotReply}) : super(key: key);

  static Future<bool?> show(BuildContext context, {required MemoModelPost post, required bool isPostCreationNotReply}) {
    return Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (context) => PublishConfirmationActivity(post: post, isPostCreationNotReply: isPostCreationNotReply),
      ),
    );
  }

  @override
  _PublishConfirmationActivityState createState() => _PublishConfirmationActivityState();
}

class _PublishConfirmationActivityState extends ConsumerState<PublishConfirmationActivity> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late bool _isNewPost;
  late String _originalText;

  // ADD THESE NEW ANIMATION CONTROLLERS
  late AnimationController _textFadeController;
  late Animation<double> _textFadeAnimation;
  // ADD TRANSLATION SECTION FADE ANIMATION CONTROLLER
  late AnimationController _translationSectionController;
  late Animation<double> _translationSectionAnimation;

  final detectedLanguageProvider = StateProvider<Language?>((ref) => null);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _originalText = widget.post.text ?? '';
    _translationSectionController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _translationSectionAnimation = CurvedAnimation(
      parent: _translationSectionController,
      curve: Curves.easeInOut,
    ); // Start with translation section visible if hasTranslation is true
    _translationSectionController.forward();

    _textFadeController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _textFadeAnimation = CurvedAnimation(parent: _textFadeController, curve: Curves.easeInOut);

    context.afterLayout(refreshUI: false, () {
      final user = ref.read(userProvider)!;
      user.temporaryTipAmount = user.tipAmountEnum;
      user.temporaryTipReceiver = user.tipReceiver;

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _textFadeController.forward();
        }
      });
    });

    _isNewPost = widget.post.creator == null;

    _controller.forward();
  }

  @override
  void dispose() {
    // DISPOSE TEXT FADE CONTROLLER
    _textFadeController.dispose();
    _translationSectionController.dispose(); // ADD THIS
    _controller.dispose();
    super.dispose();
  }

  void _increaseTipAmount() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipAmount ?? user.tipAmountEnum;
    final values = TipAmount.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex < values.length - 1) {
      setState(() {
        user.temporaryTipAmount = values[currentIndex + 1];
      });
      showSnackBar("Increased Tip: ${user.temporaryTipAmount!.value} sats", type: SnackbarType.success);
    } else {
      showSnackBar("Tip is already at the maximum!", type: SnackbarType.info);
    }
  }

  void _decreaseTipAmount() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipAmount ?? user.tipAmountEnum;
    final values = TipAmount.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex > 0) {
      setState(() {
        user.temporaryTipAmount = values[currentIndex - 1];
      });
      showSnackBar("Decreased Tip: ${user.temporaryTipAmount!.value} sats", type: SnackbarType.success);
    } else {
      showSnackBar("Tip is already at the minimum!", type: SnackbarType.info);
    }
  }

  void _nextTipReceiver() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipReceiver ?? user.tipReceiver;
    final values = TipReceiver.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex < values.length - 1) {
      setState(() {
        user.temporaryTipReceiver = values[currentIndex + 1];
      });
      showSnackBar("Tip Receiver: ${user.temporaryTipReceiver!.displayName}", type: SnackbarType.success);
    } else {
      // hasReachedMaxBurn = true;
      showSnackBar("All the tips will be burned!", type: SnackbarType.info);
    }
  }

  void _previousTipReceiver() {
    final user = ref.read(userProvider)!;
    final current = user.temporaryTipReceiver ?? user.tipReceiver;
    final values = TipReceiver.values;
    final currentIndex = values.indexOf(current);
    if (currentIndex > 0) {
      setState(() {
        user.temporaryTipReceiver = values[currentIndex - 1];
      });
      showSnackBar("Tip Receiver: ${user.temporaryTipReceiver!.displayName}", type: SnackbarType.success);
    } else {
      showSnackBar("All the tips go to creator!", type: SnackbarType.info);
    }
  }

  String _getTipAmountDisplay(TipAmount amount) {
    final formattedValue = amount.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return "$formattedValue satoshis";
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (dialogContext) => DeleteConfirmationDialog(
        theme: Theme.of(context),
        onCancel: () {
          // ref.read(draftPostProvider) = widget.post;
          _resetTranslation();
          // ref.read(userProvider)!.temporaryTipReceiver = null;
          // ref.read(userProvider)!.temporaryTipAmount = null;
          Navigator.of(dialogContext).pop();
          Navigator.of(context).pop(false);
        },
        onContinue: () {
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  void _showTipSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsWidget(initialTab: SettingsTab.tips),
    );
  }

  void _onSendPost() async {
    try {
      Navigator.of(context).pop(true);
    } catch (e) {
      Navigator.of(context).pop(false);
    }
  }

  void _resetTranslation() {
    ref.read(translationServiceProvider).resetTranslationStateAfterPublish();

    setState(() {
      widget.post.text = _originalText;
    });
  }

  Widget _buildMediaPreview(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    final post = widget.post;

    if (post.imgurUrl?.isNotEmpty == true) {
      return ImgurMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, imgurUrl: post.imgurUrl!);
    }

    if (post.youtubeId?.isNotEmpty == true) {
      return YouTubeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, youtubeId: post.youtubeId!);
    }

    if (post.ipfsCid?.isNotEmpty == true) {
      return IpfsMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, ipfsCid: post.ipfsCid!);
    }

    if (post.videoUrl?.isNotEmpty == true) {
      return OdyseeMediaWidget(theme: theme, colorScheme: colorScheme, textTheme: textTheme, videoUrl: post.videoUrl!);
    }

    if (post.imageUrl?.isNotEmpty == true) {
      return Image.network(
        post.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: theme.colorScheme.error),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final temporaryTipAmount = user.temporaryTipAmount ?? user.tipAmountEnum;

    var colorBottomBarIcon = colorScheme.onSurfaceVariant;
    String translatedText = ref.watch(translatedTextProvider) != null ? ref.read(translatedTextProvider)! : _originalText;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: AppBarBurnMahakkaTheme.height,
        leading: IconButton(
          icon: Icon(Icons.cancel_outlined, color: colorScheme.onPrimary),
          onPressed: () => _showDeleteConfirmation(),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.profileIdShort, style: textTheme.labelSmall?.copyWith(color: colorScheme.onPrimary)),
            Text(_getTipAmountDisplay(temporaryTipAmount), style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8))),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: colorScheme.onPrimary),
            onPressed: _onSendPost,
            tooltip: 'Confirm and Send',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ADD THE TRANSLATION TOGGLE CHECKBOX
              if (widget.post.text != null)
                TranslationWidget(
                  post: widget.post,
                  originalText: _originalText,
                  translationSectionController: _translationSectionController,
                  translationSectionAnimation: _translationSectionAnimation,
                  textFadeController: _textFadeController,
                  textFadeAnimation: _textFadeAnimation,
                ),
              if (widget.post.topicId.isNotEmpty) HashtagDisplayWidget(noBorder: true, hashtags: [widget.post.topicId], theme: theme),
              if (widget.post.text != null)
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Text(
                    translatedText.isNotEmpty ? translatedText : widget.post.text!,
                    style: textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.w400),
                  ),
                ),
              if (widget.post.urls.isNotEmpty) HashtagDisplayWidget(noBorder: true, hashtags: widget.post.urls, theme: theme),
              if (widget.post.urls.isEmpty) const SizedBox(height: 8),
              if (widget.post.tagIds.isNotEmpty) HashtagDisplayWidget(hashtags: widget.post.tagIds, theme: theme),
              if (widget.post.tagIds.isNotEmpty) const SizedBox(height: 12),
              _buildMediaPreview(theme, colorScheme, textTheme),
              const SizedBox(height: 0),
              TipInformationCard(post: widget.post, isPostCreationNotReply: widget.isPostCreationNotReply),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _showDeleteConfirmation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'CANCEL',
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.onError, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _onSendPost();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'SEND',
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).colorScheme.surface,
        elevation: Theme.of(context).bottomAppBarTheme.elevation,
        shadowColor: Theme.of(context).colorScheme.shadow,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        height: 60,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCustomIconButton(
                icon: Icons.account_circle_outlined,
                size: 32,
                color: _isNewPost ? colorBottomBarIcon.withAlpha(111) : colorBottomBarIcon,
                onTap: _isNewPost
                    ? () => showSnackBar("Tip receiver is 100% burn on new publications!", type: SnackbarType.error)
                    : _previousTipReceiver,
                tooltip: 'Previous Receiver',
              ),
              _buildCustomIconButton(
                icon: Icons.arrow_circle_down_outlined,
                size: 36,
                color: colorBottomBarIcon,
                onTap: _decreaseTipAmount,
                tooltip: 'Decrease Tip',
              ),
              _buildCustomIconButton(
                icon: Icons.arrow_circle_up_outlined,
                size: 36,
                color: colorBottomBarIcon,
                onTap: _increaseTipAmount,
                tooltip: 'Increase Tip',
              ),
              _buildCustomIconButton(
                icon: Icons.local_fire_department_outlined,
                size: 32,
                color: _isNewPost ? colorBottomBarIcon.withAlpha(111) : colorBottomBarIcon,
                onTap: _isNewPost
                    ? () => showSnackBar("Tip receiver is 100% burn on new publications!", type: SnackbarType.error)
                    : _nextTipReceiver,
                tooltip: 'Next Receiver',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to build custom icon buttons
  Widget _buildCustomIconButton({
    required IconData icon,
    required double size,
    required Color color,
    required VoidCallback? onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size + 32, // Add padding around the icon
        height: size + 32,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(size), // Circular splash
          child: Icon(icon, size: size, color: color),
        ),
      ),
    );
  }
}

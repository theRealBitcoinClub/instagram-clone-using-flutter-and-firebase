import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/add/add_post_providers.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/widgets/add/tip_information_card.dart';

import '../../memo/model/memo_model_post.dart';
import '../../memo/model/memo_model_user.dart';
import '../../screens/add/imgur_media_widget.dart';
import '../../screens/add/ipfs_media_widget.dart';
import '../../screens/add/odysee_media_widget.dart';
import '../../screens/add/youtube_media_widget.dart';
import '../hashtag_display_widget.dart';
import '../profile/settings_widget.dart';
import 'delete_confirmation_dialog.dart';

class PublishConfirmationActivity extends ConsumerStatefulWidget {
  final MemoModelPost post;
  final MemoModelUser user;

  const PublishConfirmationActivity({Key? key, required this.post, required this.user}) : super(key: key);

  static Future<bool?> show(BuildContext context, {required MemoModelPost post, required MemoModelUser user}) {
    return Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (context) => PublishConfirmationActivity(post: post, user: user),
      ),
    );
  }

  @override
  _PublishConfirmationActivityState createState() => _PublishConfirmationActivityState();
}

class _PublishConfirmationActivityState extends ConsumerState<PublishConfirmationActivity> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(temporaryTipAmountProvider.notifier).state = widget.user.tipAmountEnum;
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _increaseTipAmount() {
    final current = ref.read(temporaryTipAmountProvider);
    if (current != null) {
      final values = TipAmount.values;
      final currentIndex = values.indexOf(current);
      if (currentIndex < values.length - 1) {
        ref.read(temporaryTipAmountProvider.notifier).state = values[currentIndex + 1];
      } else {
        showSnackBar("It is already the maximum!", context, type: SnackbarType.info);
      }
    }
  }

  void _decreaseTipAmount() {
    final current = ref.read(temporaryTipAmountProvider);
    if (current != null) {
      final values = TipAmount.values;
      final currentIndex = values.indexOf(current);
      if (currentIndex > 0) {
        ref.read(temporaryTipAmountProvider.notifier).state = values[currentIndex - 1];
      } else {
        showSnackBar("It is already the minimum!", context, type: SnackbarType.info);
      }
    }
  }

  String _getTipAmountDisplay(TipAmount amount) {
    final formattedValue = amount.value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return "$formattedValue satoshis";
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context, // This is the PublishConfirmationActivity's context
      builder: (dialogContext) => DeleteConfirmationDialog(
        theme: Theme.of(context),
        onDelete: () {
          // Use dialogContext to pop the dialog
          Navigator.of(dialogContext).pop(); // Close the dialog
          // Use the outer context to pop the PublishConfirmationActivity
          Navigator.of(context).pop(false); // Return false to add_screen
        },
        onCancel: () {
          // Use dialogContext to pop just the dialog
          Navigator.of(dialogContext).pop(); // Just close the dialog
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

  void _sendPost() {
    //TODO MOVE THE PUBLISHING LOGIC HERE FOM ADD_SCREEN AND POST_CARD_WIDGET
    //currently this activity works like a receipt that does not allow any modifications
    //it shall allow for modifications later on
    try {
      // Return true to indicate successful confirmation
      Navigator.of(context).pop(true);
    } catch (e) {
      // If there's an error during sending, return false
      Navigator.of(context).pop(false);
    }
  }

  Widget _buildMediaPreview(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    final post = widget.post;
    //read first existing post in case it was provided as it is a reply action as media retweet
    post.imgurUrl = post.imgurUrl ?? ref.read(imgurUrlProvider);
    post.youtubeId = post.youtubeId ?? ref.read(youtubeVideoIdProvider);
    post.ipfsCid = post.ipfsCid ?? ref.read(ipfsCidProvider);
    post.videoUrl = post.videoUrl ?? ref.read(odyseeUrlProvider);

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final temporaryTipAmount = ref.watch(temporaryTipAmountProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => _showDeleteConfirmation(),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.user.creator.profileIdShort, style: textTheme.titleSmall?.copyWith(color: colorScheme.onPrimary)),
            if (temporaryTipAmount != null)
              Text(
                _getTipAmountDisplay(temporaryTipAmount),
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onPrimary.withOpacity(0.8)),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: colorScheme.onPrimary),
            onPressed: _sendPost,
            tooltip: 'Confirm and Send',
          ),
        ],
        elevation: 4,
        shadowColor: colorScheme.shadow,
      ),
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text content with topic
              if (widget.post.text != null) Text(widget.post.text!, style: textTheme.bodyLarge),
              const SizedBox(height: 16),
              if (widget.post.tagIds.isNotEmpty) HashtagDisplayWidget(hashtags: widget.post.tagIds, theme: theme),
              const SizedBox(height: 16),
              _buildMediaPreview(theme, colorScheme, textTheme),
              const SizedBox(height: 24),
              TipInformationCard(post: widget.post),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _showDeleteConfirmation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'DELETE',
                        style: textTheme.labelLarge?.copyWith(color: colorScheme.onError, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sendPost,
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
        color: colorScheme.surface,
        elevation: 8,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        height: kBottomNavigationBarHeight + 16,
        padding: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(size: 36, Icons.cancel_outlined, color: colorScheme.onSurfaceVariant),
                onPressed: _showDeleteConfirmation,
                tooltip: 'Cancel Post',
              ),
              IconButton(
                icon: Icon(size: 36, Icons.arrow_downward, color: colorScheme.onSurfaceVariant),
                onPressed: _decreaseTipAmount,
                tooltip: 'Decrease Tip',
              ),
              IconButton(
                icon: Icon(size: 32, Icons.settings, color: colorScheme.onSurfaceVariant),
                onPressed: _showTipSettings,
                tooltip: 'Tip Settings',
              ),
              IconButton(
                icon: Icon(size: 36, Icons.arrow_upward, color: colorScheme.onSurfaceVariant),
                onPressed: _increaseTipAmount,
                tooltip: 'Increase Tip',
              ),
              IconButton(
                icon: Icon(size: 36, Icons.send, color: colorScheme.onSurfaceVariant),
                onPressed: _sendPost,
                tooltip: 'Send',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

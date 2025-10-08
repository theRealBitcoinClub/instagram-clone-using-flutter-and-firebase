// lib/widgets/profile/profile_content_grid.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/config_ipfs.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
import 'package:mahakka/widgets/limit_info_dialog.dart';
import 'package:mahakka/widgets/limit_info_widget.dart';
import 'package:mahakka/widgets/profile/profile_placeholders.dart';
import 'package:mahakka/widgets/unified_image_widget.dart';

void _logGridError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentGrid - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentGrid extends ConsumerWidget {
  final List<MemoModelPost> posts;
  final Function(int index) onPostImageTap;
  final int totalCount;

  const ProfileContentGrid({Key? key, required this.posts, required this.onPostImageTap, required this.totalCount}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final profileLimit = ref.watch(profileLimitProvider);

    // Check if we should show the limit card
    print('ProfileContentGrid: totalCount: $totalCount, profileLimit: $profileLimit');
    final bool shouldShowLimitCard = totalCount >= profileLimit;
    print('ProfileContentGrid: shouldShowLimitCard: $shouldShowLimitCard');
    final itemCount = posts.length + (shouldShowLimitCard ? 1 : 0);
    print('ProfileContentGrid: itemCount: $itemCount');

    if (posts.isEmpty && !shouldShowLimitCard) {
      return EmptySliverContent(message: "No image posts by this creator yet.", icon: Icons.image_not_supported_outlined, theme: theme);
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(0, 1, 0, 0),
      sliver: SliverGrid.builder(
        itemCount: itemCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          // Check if this is the limit card
          if (shouldShowLimitCard && index >= posts.length) {
            return GestureDetector(
              onTap: () {
                LimitInfoDialog.show(context: context, limitType: LimitType.profile);
              },
              child: LimitInfoWidget(limitType: LimitType.profile, compact: true),
            );
          }

          final post = posts[index];
          return _buildGridItem(post, theme, index);
        },
      ),
    );
  }

  Widget _buildGridItem(MemoModelPost post, ThemeData theme, int index) {
    Widget imagePlaceholder = Container(
      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
      child: Icon(Icons.broken_image_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
    );

    final imageUrl = _getBestImageUrl(post);

    if (imageUrl == null) {
      return imagePlaceholder;
    }

    UnifiedImageWidget img = UnifiedImageWidget(
      imageUrl: imageUrl,
      sourceType: ImageSourceType.network,
      backgroundColor: Colors.black,
      fitMode: ImageFitMode.cover,
      aspectRatio: 1.0,
      borderRadius: BorderRadius.zero,
      border: Border(),
      showLoadingProgress: true,
      placeholder: imagePlaceholder,
    );

    return GestureDetector(
      onTap: () => onPostImageTap(index),
      child: AspectRatio(aspectRatio: 1, child: img),
    );
  }

  String? _getBestImageUrl(MemoModelPost post) {
    if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) {
      return post.imgurUrl;
    }
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      return post.imageUrl;
    }
    if (post.ipfsCid != null && post.ipfsCid!.isNotEmpty) {
      return '${IpfsConfig.preferredNode}${post.ipfsCid}';
    }
    return null;
  }
}

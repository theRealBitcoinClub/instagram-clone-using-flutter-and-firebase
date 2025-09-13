import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/profile/profile_placeholders.dart';

import '../cached_unified_image_widget.dart';
import '../unified_image_widget.dart';

void _logGridError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentGrid - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentGrid extends StatelessWidget {
  final List<MemoModelPost> posts;
  // final Function(MemoModelPost post, CachedUnifiedImageWidget imageWidget, GlobalKey imageKey) onPostImageTap;
  final Function(int index) onPostImageTap;

  const ProfileContentGrid({Key? key, required this.posts, required this.onPostImageTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (posts.isEmpty) {
      return EmptySliverContent(message: "No image posts by this creator yet.", icon: Icons.image_not_supported_outlined, theme: theme);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(2.0),
      sliver: SliverGrid.builder(
        itemCount: posts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2.0,
          mainAxisSpacing: 2.0,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          final post = posts[index];
          // final imageKey = GlobalKey(); // Create a unique key for each image

          Widget imagePlaceholder = Container(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: Icon(Icons.broken_image_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
          );

          // Get the best available image URL for this post
          final imageUrl = _getBestImageUrl(post);

          if (imageUrl == null) {
            return imagePlaceholder;
          }

          CachedUnifiedImageWidget img = CachedUnifiedImageWidget(
            // key: imageKey, // Assign the key to the image widget
            imageUrl: imageUrl,
            sourceType: ImageSourceType.network,
            fitMode: ImageFitMode.cover, // Use cover for grid
            aspectRatio: 1.0,
            borderRadius: BorderRadius.zero,
            showLoadingProgress: true,
            placeholder: Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              child: Icon(Icons.broken_image_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
            ),
          );

          return GestureDetector(
            onTap: () => onPostImageTap(index),
            // onTap: () => onPostImageTap(post, img, imageKey),
            child: AspectRatio(aspectRatio: 1, child: img),
          );
        },
      ),
    );
  }

  String? _getBestImageUrl(MemoModelPost post) {
    // Priority 1: imgurUrl (existing property)
    if (post.imgurUrl != null && post.imgurUrl!.isNotEmpty) {
      return post.imgurUrl;
    }

    // Priority 2: imageUrl (new extracted property)
    if (post.imageUrl != null && post.imageUrl!.isNotEmpty) {
      return post.imageUrl;
    }

    // Priority 3: ipfsCid (new property - convert to IPFS gateway URL)
    if (post.ipfsCid != null && post.ipfsCid!.isNotEmpty) {
      return 'https://free-bch.fullstack.cash/ipfs/view/${post.ipfsCid}';
    }

    return null;
  }
}

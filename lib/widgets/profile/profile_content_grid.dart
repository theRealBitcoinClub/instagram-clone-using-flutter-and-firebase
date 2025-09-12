import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/profile/profile_placeholders.dart';

import '../unified_image_widget.dart';

void _logGridError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentGrid - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentGrid extends StatelessWidget {
  final List<MemoModelPost> posts;
  final Function(MemoModelPost post, Widget imageWidget) onPostImageTap;

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
          Widget imagePlaceholder = Container(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: Icon(Icons.broken_image_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
          );

          // Get the best available image URL for this post
          final imageUrl = _getBestImageUrl(post);

          if (imageUrl == null) {
            return imagePlaceholder;
          }

          final img = UnifiedImageWidget(
            imageUrl: imageUrl,
            sourceType: ImageSourceType.network,
            fitMode: ImageFitMode.cover,
            aspectRatio: 1.0,
            borderRadius: BorderRadius.zero,
            showLoadingProgress: true,
            placeholder: Container(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              child: Icon(Icons.broken_image_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
            ),
          );

          // final img = Image.network(
          //   imageUrl,
          //   fit: BoxFit.cover,
          //   errorBuilder: (context, error, stackTrace) {
          //     _logGridError("Error loading grid image: $imageUrl", error, stackTrace);
          //     return imagePlaceholder;
          //   },
          //   loadingBuilder: (context, child, loadingProgress) {
          //     if (loadingProgress == null) return child;
          //     return Container(
          //       color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          //       child: Center(
          //         child: CircularProgressIndicator(
          //           strokeWidth: 1.5,
          //           valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          //           value: loadingProgress.expectedTotalBytes != null
          //               ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
          //               : null,
          //         ),
          //       ),
          //     );
          //   },
          // );

          return GestureDetector(
            onTap: () => onPostImageTap(post, AspectRatio(aspectRatio: 1, child: img)),
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

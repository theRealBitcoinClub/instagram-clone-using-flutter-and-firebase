import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart'; // Adjust path
import 'package:mahakka/widgets/profile/profile_placeholders.dart'; // Import placeholders

// Helper for logging errors consistently
void _logGridError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentGrid - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentGrid extends StatelessWidget {
  final List<MemoModelPost> posts;
  // Callback when a post image is tapped (for showing dialog)
  final Function(MemoModelPost post, Widget imageWidget) onPostImageTap;

  const ProfileContentGrid({Key? key, required this.posts, required this.onPostImageTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (posts.isEmpty) {
      return EmptySliverContent(message: "No image posts by this creator yet.", icon: Icons.image_not_supported_outlined, theme: theme);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(2.0), // Reduced padding
      sliver: SliverGrid.builder(
        itemCount: posts.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Standard 3 columns for image grid
          crossAxisSpacing: 2.0, // Reduced spacing
          mainAxisSpacing: 2.0, // Reduced spacing
          childAspectRatio: 1.0, // Square cells
        ),
        itemBuilder: (context, index) {
          final post = posts[index];
          Widget imagePlaceholder = Container(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            child: Icon(Icons.broken_image_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7)),
          );

          if (post.imgurUrl == null || post.imgurUrl!.isEmpty) {
            return imagePlaceholder;
          }

          final img = Image.network(
            post.imgurUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              _logGridError("Error loading grid image: ${post.imgurUrl}", error, stackTrace);
              return imagePlaceholder;
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          );

          return GestureDetector(
            onTap: () => onPostImageTap(post, AspectRatio(aspectRatio: 1, child: img)),
            child: AspectRatio(aspectRatio: 1, child: img), // Ensures square images
          );
        },
      ),
    );
  }
}

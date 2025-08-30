import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_post.dart'; // Adjust path
import 'package:mahakka/widgets/profile/profile_placeholders.dart'; // For EmptySliverContent
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

// Helper for logging errors consistently if needed
void _logListError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ProfileContentList - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ProfileContentList extends StatelessWidget {
  final List<MemoModelPost> posts;
  final bool isYouTubeList;
  // Use ValueNotifier for YT controllers to allow parent to manage their lifecycle
  final Map<String, ValueNotifier<YoutubePlayerController?>>? ytControllerNotifiers;
  final String creatorName; // For display purposes in list items

  const ProfileContentList._({
    // Private constructor
    Key? key,
    required this.posts,
    required this.isYouTubeList,
    this.ytControllerNotifiers,
    required this.creatorName,
  }) : super(key: key);

  // Factory for YouTube list
  factory ProfileContentList.youTube({
    Key? key,
    required List<MemoModelPost> posts,
    // Pass the map of ValueNotifiers from the parent (_ProfileScreenWidgetState)
    required Map<String, ValueNotifier<YoutubePlayerController?>> ytControllerNotifiers,
    required String creatorName,
  }) {
    return ProfileContentList._(
      key: key,
      posts: posts,
      isYouTubeList: true,
      ytControllerNotifiers: ytControllerNotifiers,
      creatorName: creatorName,
    );
  }

  // Factory for Generic posts list (Tagged, Topics)
  factory ProfileContentList.generic({Key? key, required List<MemoModelPost> posts, required String creatorName}) {
    return ProfileContentList._(
      key: key,
      posts: posts,
      isYouTubeList: false,
      ytControllerNotifiers: null, // Not needed for generic list
      creatorName: creatorName,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (posts.isEmpty) {
      final String message = isYouTubeList ? "No video posts by this creator yet." : "No posts in this category yet.";
      final IconData icon = isYouTubeList ? Icons.videocam_off_outlined : Icons.list_alt_outlined;
      return EmptySliverContent(message: message, icon: icon, theme: theme);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(childCount: posts.length, (context, index) {
        final post = posts[index];
        if (isYouTubeList) {
          return _buildYouTubeListItem(context, theme, post);
        } else {
          return _buildGenericListItem(context, theme, post);
        }
      }),
    );
  }

  Widget _buildYouTubeListItem(BuildContext context, ThemeData theme, MemoModelPost ytPost) {
    if (ytPost.youtubeId == null || ytPost.youtubeId!.isEmpty || ytControllerNotifiers == null) {
      return const SizedBox.shrink(); // Should not happen if data is filtered correctly
    }

    // Get or create the ValueNotifier for the controller
    // The parent (_ProfileScreenWidgetState) is responsible for creating/disposing these notifiers.
    // This widget just consumes them.
    final controllerNotifier = ytControllerNotifiers!.putIfAbsent(ytPost.id!, () => ValueNotifier(null));

    // Initialize or update controller if needed (e.g., if video ID changed for the same post ID, though rare for profiles)
    if (controllerNotifier.value == null || controllerNotifier.value!.initialVideoId != ytPost.youtubeId) {
      controllerNotifier.value?.dispose(); // Dispose old one if it exists and is different
      controllerNotifier.value = YoutubePlayerController(
        initialVideoId: ytPost.youtubeId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false, // Don't autoplay in a list
          mute: true, // Mute by default in a list
          hideControls: false,
          hideThumbnail: false, // Show thumbnail initially
          // disableDragSeek: true, // Consider this for lists
          // loop: false,
        ),
      );
    }
    // This should not be null now
    final YoutubePlayerController controller = controllerNotifier.value!;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        // Removed Padding wrapper, let Column be the direct child
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ensure the YoutubePlayer widget is rebuilt if the controller instance changes.
          // The ValueKey includes the initialVideoId to help with this.
          YoutubePlayer(
            key: ValueKey("yt_profile_${ytPost.id}_${controller.initialVideoId}"),
            controller: controller,
            showVideoProgressIndicator: true,
            progressIndicatorColor: theme.colorScheme.primary,
            progressColors: ProgressBarColors(
              playedColor: theme.colorScheme.primary,
              handleColor: theme.colorScheme.secondary,
              bufferedColor: theme.colorScheme.primary.withOpacity(0.4),
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
            // onEnded: (metadata) { // Optional: reset video on end
            //   controller.seekTo(Duration.zero);
            //   controller.pause();
            // },
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ytPost.text != null && ytPost.text!.isNotEmpty) ...[
                  ExpandableText(
                    ytPost.text!, // Make sure ytPost.text is not null
                    expandText: 'more',
                    collapseText: 'less',
                    maxLines: 3,
                    linkColor: theme.colorScheme.primary,
                    style: theme.textTheme.bodyMedium,
                    linkStyle: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  // Use the passed creatorName, as post.creator might not be populated here
                  "Posted by: $creatorName, ${ytPost.age}",
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericListItem(BuildContext context, ThemeData theme, MemoModelPost post) {
    // Use post.age or post.created as per your original logic for timestamp
    final String postTimestamp = post.age;

    return Card(
      elevation: 1.0, // Subtle elevation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Consistent margin
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header: Creator Name and Timestamp ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    creatorName, // Use the passed creator name
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (postTimestamp.isNotEmpty)
                  Text(
                    postTimestamp,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7), fontSize: 11),
                  ),
              ],
            ),
            const SizedBox(height: 4), // Reduced space
            Divider(color: theme.dividerColor.withOpacity(0.3), height: 1), // Thinner divider
            const SizedBox(height: 10),

            // --- Post Text Content with ExpandableText ---
            ExpandableText(
              post.text ?? " ", // Ensure text is not null
              expandText: 'show more',
              collapseText: 'show less',
              maxLines: 5, // Or your preferred max lines
              linkColor: theme.colorScheme.primary.withOpacity(0.85),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: "Open Sans",
                fontSize: 14,
                height: 1.4, // Line height
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85),
              ),
              linkStyle: theme.textTheme.bodySmall?.copyWith(
                // For "show more/less"
                color: theme.colorScheme.primary.withOpacity(0.85),
                fontWeight: FontWeight.w600,
              ),
              // --- Hashtag Styling and Tap Handling (from original) ---
              hashtagStyle: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary, fontWeight: FontWeight.w500),
              onHashtagTap: (String hashtag) {
                _logListError('Hashtag tapped: $hashtag (Action not implemented in this widget)');
                // Example action:
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped on hashtag: $hashtag')));
              },
              // --- URL Styling and Tap Handling (from original) ---
              urlStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary.withOpacity(0.70),
                decoration: TextDecoration.underline,
                decorationColor: theme.colorScheme.primary.withOpacity(0.5),
              ),
              onUrlTap: (String url) async {
                _logListError('URL tapped: $url');
                Uri? uri = Uri.tryParse(url);
                if (uri != null) {
                  // Attempt to add scheme if missing (e.g., for "www.example.com")
                  if (!uri.hasScheme && (url.startsWith('www.') || RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(url))) {
                    uri = Uri.parse('http://$url');
                  }
                  try {
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      _logListError('Could not launch $uri');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $url')));
                      }
                    }
                  } catch (e) {
                    _logListError('Error launching URL $url: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: $url')));
                    }
                  }
                } else {
                  _logListError('Invalid URL: $url');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid link format: $url')));
                  }
                }
              },
              // --- Prefix for Topic ID (from original) ---
              prefixText: post.topicId.isNotEmpty ? "${post.topicId}\n\n" : null, // Removed extra newline
              prefixStyle: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface, // Using tertiary for topic emphasis
                fontWeight: FontWeight.w400,
                // fontStyle: FontStyle.italic,
              ),
              onPrefixTap: () {
                _logListError("Topic prefix tapped: ${post.topicId} (Action not implemented in this widget)");
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tapped on topic: ${post.topicId}')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

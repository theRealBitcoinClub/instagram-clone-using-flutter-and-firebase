import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';

// Callback type definition
typedef CountChangedCallback = void Function(int count);

class AdminPostsListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminPostsListPage({super.key, required this.onCountChanged});

  @override
  State<AdminPostsListPage> createState() => _AdminPostsListPageState();
}

class _AdminPostsListPageState extends State<AdminPostsListPage> {
  final PostService _postService = PostService();

  Future<void> _deletePost(BuildContext context, String postId, String? postTextSnippet) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete post ID "$postId"${postTextSnippet != null ? ' starting with "$postTextSnippet..."' : ''}? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop(false)),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await _postService.deletePost(postId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Post "$postId" deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        print("Error deleting post: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete post "$postId": $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold and AppBar are removed as they are handled by MainAdminDashboard
    return StreamBuilder<List<MemoModelPost>>(
      stream: _postService.getAllPostsStream(orderByField: 'createdDateTime', descending: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // widget.onCountChanged(0); // Optionally report 0
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          widget.onCountChanged(0);
          print("Error in StreamBuilder (Posts): ${snapshot.error}");
          return Center(child: Text('Error loading posts: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          widget.onCountChanged(0);
          return const Center(child: Text('No posts found.'));
        }

        final List<MemoModelPost> posts = snapshot.data!;
        // Call the callback with the current count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Ensure widget is still mounted
            widget.onCountChanged(posts.length);
          }
        });

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            final postTextSnippet = post.text != null && post.text!.length > 20 ? "${post.text!.substring(0, 20)}..." : post.text;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Post ID: ${post.id}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[700]),
                          tooltip: 'Delete Post',
                          onPressed: () => _deletePost(context, post.id, postTextSnippet),
                        ),
                      ],
                    ),
                    const Divider(),
                    _buildPropertyRow('Text:', post.text, maxLines: 3),
                    _buildPropertyRow('Creator ID:', post.creatorId),
                    _buildPropertyRow('Topic ID:', post.topicId),
                    _buildPropertyRow('Imgur URL:', post.imgurUrl, isUrl: true),
                    _buildPropertyRow('YouTube ID:', post.youtubeId),
                    _buildPropertyRow('Popularity Score:', post.popularityScore?.toString()),
                    _buildPropertyRow('Like Counter:', post.likeCounter?.toString()),
                    _buildPropertyRow('Reply Counter:', post.replyCounter?.toString()),
                    _buildPropertyRow('Created:', post.created),
                    _buildPropertyRow('Created DateTime:', _formatDateTimeSafe(post.createdDateTime)),
                    _buildPropertyRow('Tag IDs:', post.tagIds.join(', ')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String? value, {int? maxLines, bool isUrl = false}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: TextStyle(fontSize: 13, color: isUrl ? Colors.blue : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTimeSafe(DateTime? dateTime) {
    if (dateTime == null) return "N/A";
    try {
      final localDateTime = dateTime.toLocal();
      return "${localDateTime.year}-${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')} "
          "${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}:${localDateTime.second.toString().padLeft(2, '0')}";
    } catch (e) {
      print("Error parsing DateTime: $dateTime, Error: $e");
      return "Invalid Date";
    }
  }
}

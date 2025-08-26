import 'package:flutter/material.dart';
// Adjust these import paths to match your project structure
import 'package:mahakka/memo/firebase/post_service.dart'; // Your PostService path
import 'package:mahakka/memo/model/memo_model_post.dart'; // Your Post Model
// Remove if not running standalone
// import 'package:firebase_core/firebase_core.dart';
// import '../../firebase_options.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // For Timestamp, if displaying directly

class AdminPostsListPage extends StatefulWidget {
  const AdminPostsListPage({super.key});

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
            'Are you sure you want to delete post ID "$postId"${postTextSnippet != null ? ' starting with $postTextSnippet..."' : ''}? This action cannot be undone.',
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
        // The StreamBuilder will automatically rebuild the list
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - All Posts'),
        // You could add sorting options here later if needed
      ),
      body: StreamBuilder<List<MemoModelPost>>(
        // Example: Order by createdDateTime if available, otherwise no specific order from client
        stream: _postService.getAllPostsStream(orderByField: 'createdDateTime', descending: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in StreamBuilder (Posts): ${snapshot.error}");
            return Center(child: Text('Error loading posts: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No posts found.'));
          }

          final List<MemoModelPost> posts = snapshot.data!;

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postTextSnippet = post.text != null && post.text!.length > 20
                  ? "${post.text!.substring(0, 20)}..."
                  : post.text;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    // Using Column for better layout of many fields
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
                      // Displaying only fields assumed to be serialized
                      _buildPropertyRow('Unique Content ID:', post.uniqueContentId),
                      _buildPropertyRow('Text:', post.text, maxLines: 3),
                      _buildPropertyRow('Creator ID:', post.creatorId),
                      _buildPropertyRow('Topic ID:', post.topicId),
                      _buildPropertyRow('Imgur URL:', post.imgurUrl, isUrl: true),
                      _buildPropertyRow('YouTube ID:', post.youtubeId),
                      _buildPropertyRow('Popularity Score:', post.popularityScore?.toString()),
                      _buildPropertyRow('Like Counter:', post.likeCounter?.toString()),
                      _buildPropertyRow('Reply Counter:', post.replyCounter?.toString()),
                      _buildPropertyRow('Created DateTime:', _formatDateTimeSafe(post.createdDateTime)),
                      _buildPropertyRow('Tag IDs:', post.tagIds.join(', ')), // Join list of strings
                      // --- Fields that are NOT serialized (or marked ignore) are omitted: ---
                      // - post.urls (List<String>)
                      // - post.hashtags (List<String>)
                      // - post.creator (MemoModelCreator object)
                      // - post.topic (MemoModelTopic object)
                      // - post.age (String, derived or ignored)
                      // - post.created (String, original version, ignored)
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPropertyRow(String label, String? value, {int? maxLines, bool isUrl = false}) {
    if (value == null || value.isEmpty) {
      // Optionally hide the row if value is null/empty, or show N/A
      return const SizedBox.shrink(); // Hide row
      // return Padding(
      //   padding: const EdgeInsets.symmetric(vertical: 2.0),
      //   child: Row(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      //       const SizedBox(width: 6),
      //       Expanded(child: Text('N/A', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[600]))),
      //     ],
      //   ),
      // );
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
      // Using local time for display
      final localDateTime = dateTime.toLocal();
      return "${localDateTime.year}-${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')} "
          "${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}:${localDateTime.second.toString().padLeft(2, '0')}";
    } catch (e) {
      print("Error parsing DateTime: $dateTime, Error: $e");
      return "Invalid Date";
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart'; // Import for DocumentSnapshot
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
  final int _postsPerPage = 20; // Number of posts to fetch per page

  // State variables for pagination
  List<MemoModelPost> _posts = [];
  bool _isLoading = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNextPage(); // Initial fetch
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check if the user is at the end of the list and more posts are available
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading && _hasMorePosts) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading) return; // Prevent multiple concurrent fetches

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the paginated method from your PostService
      final newPosts = await _postService.getPostsPaginated(limit: _postsPerPage, startAfterDoc: _lastDocument);

      // Check if we reached the end of the collection
      _hasMorePosts = newPosts.length == _postsPerPage;

      if (newPosts.isNotEmpty) {
        // Update the last document for the next page
        _lastDocument = newPosts.last.docSnapshot;

        setState(() {
          _posts.addAll(newPosts);
          widget.onCountChanged(_posts.length); // Update the total count
        });
      } else {
        setState(() {
          _hasMorePosts = false;
        });
      }
    } catch (e) {
      print("Error fetching posts page: $e");
      // Handle error gracefully, perhaps show a snackbar
      setState(() {
        _hasMorePosts = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        // Remove the post from the local list to update the UI
        setState(() {
          _posts.removeWhere((post) => post.id == postId);
          widget.onCountChanged(_posts.length); // Update the total count
        });
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
    if (_posts.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty && !_isLoading && !_hasMorePosts) {
      return const Center(child: Text('No posts found.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _posts.length + (_isLoading ? 1 : 0), // Add 1 for the loading indicator
      itemBuilder: (context, index) {
        if (index < _posts.length) {
          final post = _posts[index];
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
                        onPressed: () => _deletePost(context, post.id!, postTextSnippet),
                      ),
                    ],
                  ),
                  const Divider(),
                  _buildPropertyRow('Text:', post.text, maxLines: 3),
                  _buildPropertyRow('Creator ID:', post.creatorId),
                  _buildPropertyRow('Topic ID:', post.topicId),
                  _buildPropertyRow('Imgur URL:', post.imgurUrl, isUrl: true),
                  _buildPropertyRow('YouTube ID:', post.youtubeId),
                  _buildPropertyRow('Popularity Score:', post.popularityScore.toString()),
                  _buildPropertyRow('Like Counter:', post.likeCounter?.toString()),
                  _buildPropertyRow('Reply Counter:', post.replyCounter?.toString()),
                  _buildPropertyRow('Created:', post.created),
                  _buildPropertyRow('Created DateTime:', _formatDateTimeSafe(post.createdDateTime)),
                  _buildPropertyRow('Tag IDs:', post.tagIds.join(', ')),
                ],
              ),
            ),
          );
        } else {
          // This is the loading indicator at the bottom
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
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

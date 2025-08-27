import 'package:cloud_firestore/cloud_firestore.dart'; // Needed for DocumentSnapshot and Timestamp
import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/post_service.dart'; // Your PostService path
import 'package:mahakka/memo/model/memo_model_post.dart'; // Your Post Model

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
  final ScrollController _scrollController = ScrollController();

  List<MemoModelPost> _posts = [];
  bool _isLoading = true; // For initial load
  bool _isLoadingMore = false;
  bool _hasMorePosts = true;
  DocumentSnapshot? _lastDocument; // To keep track of the last fetched document

  static const int _documentsPerPage = 15; // Number of posts to fetch per page

  @override
  void initState() {
    super.initState();
    _fetchInitialPosts();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    // If scrolled to the bottom, not currently loading, and there are more posts
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 && // Load a bit before exact bottom
        !_isLoadingMore &&
        _hasMorePosts) {
      _fetchMorePosts();
    }
  }

  Future<void> _fetchInitialPosts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _posts = []; // Clear previous posts for a fresh initial fetch
      _lastDocument = null;
      _hasMorePosts = true;
    });

    try {
      QuerySnapshot querySnapshot = await _postService
          .getPostsPaginated(
            limit: _documentsPerPage,
            // No startAfterDocument for the initial fetch
          )
          .first; // Using .first to convert single-event stream to Future

      if (!mounted) return;

      final fetchedPosts = querySnapshot.docs
          .map((doc) => MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>))
          .toList();

      if (fetchedPosts.length < _documentsPerPage) {
        _hasMorePosts = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      setState(() {
        _posts = fetchedPosts;
        _isLoading = false;
      });
      widget.onCountChanged(_posts.length); // Initial count
    } catch (e) {
      if (!mounted) return;
      print("Error fetching initial posts: $e");
      setState(() {
        _isLoading = false;
        _hasMorePosts = false; // Stop trying if there's an error
      });
      widget.onCountChanged(0);
    }
  }

  Future<void> _fetchMorePosts() async {
    if (_isLoadingMore || !_hasMorePosts || _lastDocument == null) return;

    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      QuerySnapshot querySnapshot = await _postService
          .getPostsPaginated(limit: _documentsPerPage, startAfterDoc: _lastDocument)
          .first;

      if (!mounted) return;

      final newPosts = querySnapshot.docs
          .map((doc) => MemoModelPost.fromJson(doc.data()! as Map<String, dynamic>))
          .toList();

      if (newPosts.length < _documentsPerPage) {
        _hasMorePosts = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      } else {
        _hasMorePosts = false; // No more documents came back
      }

      setState(() {
        _posts.addAll(newPosts);
        _isLoadingMore = false;
      });
      widget.onCountChanged(_posts.length); // Update count with newly loaded items
    } catch (e) {
      if (!mounted) return;
      print("Error fetching more posts: $e");
      setState(() {
        _isLoadingMore = false;
        // Optionally, you might want to set _hasMorePosts = false here too
        // or implement a retry mechanism.
      });
      // Do not reset the count here, as previous items are still valid
    }
  }

  Future<void> _deletePost(BuildContext context, String postId, String? postTextSnippet) async {
    // ... (Your existing _deletePost logic) ...
    // After successful deletion, you might want to refresh the list or remove the item locally
    // For simplicity, a full refresh is easier with pagination, but less optimal.
    // A more advanced approach would remove the item from _posts and adjust counts.
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
          // Refresh the list after deletion for simplicity with pagination
          _fetchInitialPosts();
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_posts.isEmpty && !_hasMorePosts) {
      // Check after initial load
      widget.onCountChanged(0);
      return const Center(child: Text('No posts found.'));
    }

    return RefreshIndicator(
      // Optional: Add pull-to-refresh
      onRefresh: _fetchInitialPosts,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _posts.length + (_hasMorePosts && _posts.isNotEmpty ? 1 : 0),
        // +1 for loading indicator if there are more posts AND posts exist
        itemBuilder: (context, index) {
          if (index == _posts.length && _hasMorePosts) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (index >= _posts.length) {
            // Should not happen if itemCount is correct, but as a safeguard
            return const SizedBox.shrink();
          }

          final post = _posts[index];
          final postTextSnippet = post.text != null && post.text!.length > 20
              ? "${post.text!.substring(0, 20)}..."
              : post.text;

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
                  _buildPropertyRow('Tag IDs:', post.tagIds.join(', ')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ... (Keep your _buildPropertyRow and _formatDateTimeSafe methods as they are) ...
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

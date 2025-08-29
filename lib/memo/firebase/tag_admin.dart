import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/tag_service.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';

// Callback type definition
typedef CountChangedCallback = void Function(int count);

class AdminTagsListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminTagsListPage({super.key, required this.onCountChanged});

  @override
  State<AdminTagsListPage> createState() => _AdminTagsListPageState();
}

class _AdminTagsListPageState extends State<AdminTagsListPage> {
  final TagService _tagService = TagService();

  Future<void> _deleteTag(BuildContext context, String tagId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete tag "$tagId"? This action cannot be undone. \n\nNote: This will not remove the tag from existing posts, only delete the tag entry itself (and its postCount).',
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
        await _tagService.deleteTag(tagId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Tag "$tagId" deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        print("Error deleting tag: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete tag "$tagId": $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold and AppBar are removed as they are handled by MainAdminDashboard
    return StreamBuilder<List<MemoModelTag>>(
      stream: _tagService.getAllTagsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // widget.onCountChanged(0); // Optionally report 0
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          widget.onCountChanged(0);
          print("Error in StreamBuilder (Tags): ${snapshot.error}");
          return Center(child: Text('Error loading tags: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          widget.onCountChanged(0);
          return const Center(child: Text('No tags found.'));
        }

        final List<MemoModelTag> tags = snapshot.data!;
        // Call the callback with the current count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Ensure widget is still mounted
            widget.onCountChanged(tags.length);
          }
        });

        // Example: Sort tags by postCount client-side if not done by service
        // tags.sort((a, b) => (b.postCount ?? 0).compareTo(a.postCount ?? 0));

        return ListView.builder(
          itemCount: tags.length,
          itemBuilder: (context, index) {
            final tag = tags[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.sell_outlined, size: 30, color: Theme.of(context).colorScheme.primary),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${tag.id}", // Added index for clarity
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          _buildPropertyRow('Post Count:', tag.postCount?.toString() ?? '0'),
                          _buildPropertyRow('Last Used:', _formatDateSafe(tag.lastPost)), // Assuming you have this field
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[700]),
                      tooltip: 'Delete Tag',
                      onPressed: () => _deleteTag(context, tag.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPropertyRow(String label, String? value, {int? maxLines}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateSafe(String? dateString) {
    if (dateString == null || dateString.isEmpty) return "N/A";
    try {
      final dateTime = DateTime.parse(dateString);
      final localDateTime = dateTime.toLocal();
      return "${localDateTime.year}-${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')} "
          "${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print("Error parsing date: $dateString, Error: $e");
      return dateString;
    }
  }
}

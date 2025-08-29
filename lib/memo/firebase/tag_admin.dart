import 'package:cloud_firestore/cloud_firestore.dart';
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
  final int _tagsPerPage = 20;

  List<MemoModelTag> _tags = [];
  bool _isLoading = false;
  bool _hasMoreTags = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchNextPage();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading && _hasMoreTags) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newTags = await _tagService.getTagsPaginated(limit: _tagsPerPage, startAfterDoc: _lastDocument);

      _hasMoreTags = newTags.length == _tagsPerPage;

      if (newTags.isNotEmpty) {
        // You'll need to make sure your MemoModelTag has a docSnapshot property
        // assigned in its fromSnapshot constructor.
        _lastDocument = newTags.last.docSnapshot;
        setState(() {
          _tags.addAll(newTags);
          widget.onCountChanged(_tags.length);
        });
      } else {
        setState(() {
          _hasMoreTags = false;
        });
      }
    } catch (e) {
      print("Error fetching tags page: $e");
      setState(() {
        _hasMoreTags = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        // Remove the tag from the local list to update the UI
        setState(() {
          _tags.removeWhere((tag) => tag.id == tagId);
          widget.onCountChanged(_tags.length); // Update the total count
        });
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
    if (_tags.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tags.isEmpty && !_isLoading && !_hasMoreTags) {
      return const Center(child: Text('No tags found.'));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _tags.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _tags.length) {
          final tag = _tags[index];
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
                        Text("${index + 1}. ${tag.id}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _buildPropertyRow('Post Count:', tag.postCount?.toString() ?? '0'),
                        _buildPropertyRow('Last Used:', _formatDateSafe(tag.lastPost)),
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
        } else {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
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

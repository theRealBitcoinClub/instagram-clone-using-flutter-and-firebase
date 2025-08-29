// topic_admin.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/topic_service.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

// The callback now takes both fetched and total count.
typedef CountChangedCallback = void Function(int fetchedCount, int totalCount);

class AdminTopicsListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminTopicsListPage({super.key, required this.onCountChanged});

  @override
  State<AdminTopicsListPage> createState() => _AdminTopicsListPageState();
}

class _AdminTopicsListPageState extends State<AdminTopicsListPage> {
  final TopicService _topicService = TopicService();
  final int _topicsPerPage = 20;

  List<MemoModelTopic> _topics = [];
  bool _isLoading = false;
  bool _hasMoreTopics = true;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  int _totalCount = 0;

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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading && _hasMoreTopics) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newTopics = await _topicService.getPaginated(
        limit: _topicsPerPage,
        startAfterDoc: _lastDocument,
        orderByField: 'createdDateTime',
        descending: true,
      );

      _hasMoreTopics = newTopics.length == _topicsPerPage;

      if (newTopics.isNotEmpty) {
        // Assuming your model has a docSnapshot or similar property
        _lastDocument = (newTopics.last as dynamic).docSnapshot;
        setState(() {
          _topics.addAll(newTopics);
          widget.onCountChanged(_topics.length, _totalCount);
        });
      } else {
        setState(() {
          _hasMoreTopics = false;
        });
      }
    } catch (e) {
      print("Error fetching topics page: $e");
      setState(() {
        _hasMoreTopics = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteTopic(BuildContext context, String topicId, String? topicName) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete topic "${topicName ?? 'N/A'}" (ID: $topicId)? This action cannot be undone.'),
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
        await _topicService.delete(topicId);
        setState(() {
          _topics.removeWhere((topic) => topic.id == topicId);
          widget.onCountChanged(_topics.length, _totalCount - 1);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Topic "$topicId" deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        print("Error deleting topic: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete topic "$topicId": $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _topicService.getTotalCountStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _totalCount = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCountChanged(_topics.length, _totalCount);
          });
        }

        if (_topics.isEmpty && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_topics.isEmpty && !_isLoading && !_hasMoreTopics) {
          return const Center(child: Text('No topics found.'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: _topics.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _topics.length) {
              final topic = _topics[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColorLight,
                          child: Icon(Icons.topic_outlined, size: 30, color: Theme.of(context).primaryColorDark),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${index + 1}. ${topic.header}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('ID: ${topic.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            _buildPropertyRow('Url:', topic.url, maxLines: 2),
                            _buildPropertyRow('Posts:', topic.postCount?.toString() ?? 'N/A'),
                            _buildPropertyRow('Follower:', topic.followerCount?.toString() ?? 'N/A'),
                            _buildPropertyRow('Last Post:', _formatDateSafe(topic.lastPost)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[700]),
                        tooltip: 'Delete Topic',
                        onPressed: () => _deleteTopic(context, topic.id, topic.header),
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
      },
    );
  }

  Widget _buildPropertyRow(String label, String? value, {int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? 'N/A',
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: const TextStyle(fontSize: 13),
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
      return "${localDateTime.year}-${localDateTime.month.toString().padLeft(2, '0')}-${localDateTime.day.toString().padLeft(2, '0')} ${localDateTime.hour.toString().padLeft(2, '0')}:${localDateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      print("Error parsing date: $dateString, Error: $e");
      return dateString;
    }
  }
}

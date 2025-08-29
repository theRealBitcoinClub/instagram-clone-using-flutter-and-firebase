import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/topic_service.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

// Callback type definition (can be shared or defined per page)
typedef CountChangedCallback = void Function(int count);

class AdminTopicsListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminTopicsListPage({super.key, required this.onCountChanged});

  @override
  State<AdminTopicsListPage> createState() => _AdminTopicsListPageState();
}

class _AdminTopicsListPageState extends State<AdminTopicsListPage> {
  final TopicService _topicService = TopicService();

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
        await _topicService.deleteTopic(topicId);
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
    return StreamBuilder<List<MemoModelTopic>>(
      stream: _topicService.getAllTopicsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // widget.onCountChanged(0); // Optionally report 0 during load
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          widget.onCountChanged(0);
          print("Error in StreamBuilder (Topics): ${snapshot.error}");
          return Center(child: Text('Error loading topics: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          widget.onCountChanged(0);
          return const Center(child: Text('No topics found.'));
        }

        final List<MemoModelTopic> topics = snapshot.data!;
        // Call the callback with the current count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onCountChanged(topics.length);
          }
        });

        return ListView.builder(
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
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

import 'package:flutter/material.dart';
// Adjust these import paths to match your project structure
import 'package:mahakka/memo/firebase/topic_service.dart'; // Your TopicService path
import 'package:mahakka/memo/model/memo_model_topic.dart'; // Your Topic Model
// Remove if not running standalone
// import 'package:firebase_core/firebase_core.dart';
// import '../../firebase_options.dart';

class AdminTopicsListPage extends StatefulWidget {
  const AdminTopicsListPage({super.key});

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
          content: Text(
            'Are you sure you want to delete topic "${topicName ?? 'N/A'}" (ID: $topicId)? This action cannot be undone.',
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
        await _topicService.deleteTopic(topicId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Topic "$topicId" deleted successfully'), backgroundColor: Colors.green),
          );
        }
        // The StreamBuilder will automatically rebuild the list
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
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel - All Topics')),
      body: StreamBuilder<List<MemoModelTopic>>(
        stream: _topicService.getAllTopicsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in StreamBuilder (Topics): ${snapshot.error}");
            return Center(child: Text('Error loading topics: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No topics found.'));
          }

          final List<MemoModelTopic> topics = snapshot.data!;

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
                      // Optional: Topic Icon or Image
                      // You might want a default icon for topics
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColorLight,
                          child: Icon(
                            Icons.topic_outlined, // Example icon
                            size: 30,
                            color: Theme.of(context).primaryColorDark,
                          ),
                          // If MemoModelTopic has an imageUrl property:
                          // backgroundImage: topic.imageUrl != null && topic.imageUrl!.isNotEmpty
                          //     ? NetworkImage(topic.imageUrl!)
                          //     : null,
                          // onBackgroundImageError: (e, s) { print("Error loading topic image for ${topic.id}: $e"); },
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.header ?? 'N/A', // Assuming MemoModelTopic has a 'name' field
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('ID: ${topic.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            // Display relevant properties from MemoModelTopic
                            _buildPropertyRow('Url:', topic.url, maxLines: 2), // Assuming 'description'
                            _buildPropertyRow('Posts:', topic.postCount?.toString() ?? 'N/A'), // Assuming 'postCount'
                            _buildPropertyRow(
                              'Follower:',
                              topic.followerCount?.toString() ?? 'N/A',
                            ), // Assuming 'postCount'
                            _buildPropertyRow(
                              'Last Post:',
                              _formatDateSafe(topic.lastPost),
                            ), // Assuming 'lastPost' is a date string
                            // Add more properties from MemoModelTopic as needed
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
      ),
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
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      // If parsing fails, return the original string or a placeholder
      print("Error parsing date: $dateString, Error: $e");
      return dateString;
    }
  }
}

// --- Optional: Main function for testing this page standalone ---
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(
//     MaterialApp(
//       title: 'Admin Topics Panel Test',
//       theme: ThemeData(
//         primarySwatch: Colors.blueGrey,
//         useMaterial3: true,
//         cardTheme: CardThemeData( // Corrected usage
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         )
//       ),
//       home: const AdminTopicsListPage(),
//     ),
//   );
// }

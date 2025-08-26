import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Make sure this path is correct for your project
import 'package:mahakka/memo/firebase/creator_service.dart'; // Your CreatorService path
import 'package:mahakka/memo/model/memo_model_creator.dart';

import '../../firebase_options.dart'; // Your Creator Model

class AdminCreatorsListPage extends StatefulWidget {
  const AdminCreatorsListPage({super.key});

  @override
  State<AdminCreatorsListPage> createState() => _AdminCreatorsListPageState();
}

class _AdminCreatorsListPageState extends State<AdminCreatorsListPage> {
  // Use your actual CreatorService
  final CreatorService _creatorService = CreatorService();

  Future<void> _deleteCreator(BuildContext context, String creatorId, String? creatorName) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete creator "${creatorName ?? 'N/A'}" (ID: $creatorId)? This action cannot be undone.',
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
        await _creatorService.deleteCreator(creatorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Creator $creatorId deleted successfully'), backgroundColor: Colors.green),
          );
        }
        // The StreamBuilder will automatically rebuild and show the updated list
      } catch (e) {
        print("Error deleting creator: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete creator $creatorId: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel - All Creators')),
      body: StreamBuilder<List<MemoModelCreator>>(
        stream: _creatorService.getAllCreatorsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error in StreamBuilder: ${snapshot.error}");
            return Center(child: Text('Error loading creators: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No creators found.'));
          }

          final List<MemoModelCreator> creators = snapshot.data!;

          return ListView.builder(
            itemCount: creators.length,
            itemBuilder: (context, index) {
              final creator = creators[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Creator Avatar (Optional)
                      if (creator.profileImageAvatar.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(creator.profileImageAvatar.toString()),
                            onBackgroundImageError: (e, s) {
                              print("Error loading avatar for ${creator.id}: $e");
                              return; // The CircleAvatar will show its child (Icon)
                            },
                            child: Icon(Icons.person, size: 30), // Fallback
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$index. ${creator.name}" ?? 'N/A',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text('ID: ${creator.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            _buildPropertyRow('Profile:', creator.profileText, maxLines: 2),
                            _buildPropertyRow('Followers:', creator.followerCount?.toString() ?? 'N/A'),
                            _buildPropertyRow('Actions:', creator.actions?.toString() ?? 'N/A'),
                            _buildPropertyRow('Created:', _formatDateSafe(creator.created)),
                            _buildPropertyRow('Last Action:', _formatDateSafe(creator.lastActionDate)),
                            // Add more properties from MemoModelCreator as needed
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[700]),
                        tooltip: 'Delete Creator',
                        onPressed: () => _deleteCreator(context, creator.id, creator.name),
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
      // You can use the intl package for more robust and localized date formatting
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }
}

void main() async {
  // You'd need to initialize Firebase here if running standalone
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // If using Firebase CLI setup
  );
  runApp(
    MaterialApp(
      title: 'Admin Panel Test (Stream)',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        useMaterial3: true,
        cardTheme: CardThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      home: const AdminCreatorsListPage(),
    ),
  );
}

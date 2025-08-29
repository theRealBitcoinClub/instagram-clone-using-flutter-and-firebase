import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/user_service.dart'; // Your UserService path
import 'package:mahakka/memo/model/memo_model_user.dart';

typedef CountChangedCallback = void Function(int count);

class AdminUsersListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminUsersListPage({super.key, required this.onCountChanged});

  @override
  State<AdminUsersListPage> createState() => _AdminUsersListPageState();
}

class _AdminUsersListPageState extends State<AdminUsersListPage> {
  final UserService _userService = UserService();

  Future<void> _deleteUser(BuildContext context, String userId) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete user with ID: $userId? This action cannot be undone.'),
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
        await _userService.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User $userId deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        print("Error deleting user: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete user $userId: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MemoModelUser>>(
      stream: _userService.getAllUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          widget.onCountChanged(0);
          print("Error in StreamBuilder (Users): ${snapshot.error}");
          return Center(child: Text('Error loading users: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          widget.onCountChanged(0);
          return const Center(child: Text('No users found.'));
        }

        final List<MemoModelUser> users = snapshot.data!;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onCountChanged(users.length);
          }
        });

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(radius: 30, child: Icon(Icons.person_outline, size: 30)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${index + 1}. User ID", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('ID: ${user.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          _buildPropertyRow('CashToken Address:', user.bchAddressCashtokenAware),
                          _buildPropertyRow('Legacy Address:', user.legacyAddressMemoBch),
                          _buildPropertyRow('Legacy Cash Address:', user.legacyAddressMemoBchAsCashaddress),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[700]),
                      tooltip: 'Delete User',
                      onPressed: () => _deleteUser(context, user.id),
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
}

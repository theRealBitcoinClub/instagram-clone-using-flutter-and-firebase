// lib/admin/admin_user.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/user_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/repositories/creator_repository.dart';

typedef CountChangedCallback = void Function(int count);

class AdminUsersListPage extends ConsumerStatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminUsersListPage({super.key, required this.onCountChanged});

  @override
  ConsumerState<AdminUsersListPage> createState() => _AdminUsersListPageState();
}

class _AdminUsersListPageState extends ConsumerState<AdminUsersListPage> {
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
            return FutureBuilder<MemoModelCreator?>(
              future: ref.read(creatorRepositoryProvider).getCreator(user.id),
              builder: (context, creatorSnapshot) {
                final creator = creatorSnapshot.data;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with avatar and main info
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: creator?.profileImageAvatar().isNotEmpty == true
                                  ? NetworkImage(creator!.profileImageAvatar()) as ImageProvider
                                  : const AssetImage("assets/images/default_profile.png"),
                              onBackgroundImageError: (exception, stackTrace) {
                                print("Error loading creator avatar for ${user.id}: $exception");
                              },
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${index + 1}. User ID: ${user.id}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  _buildPropertyRow('Creator Name:', creator?.name ?? 'N/A', maxLines: 1),
                                  _buildPropertyRow('Profile Text:', creator?.profileText ?? 'N/A', maxLines: 2),
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
                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 12),

                        // Section for all available user fields
                        const Text(
                          'User Data',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        // _buildPropertyRow('Mnemonic:', user.mnemonic ?? 'N/A'),
                        _buildPropertyRow('Is Authenticated:', user.hasInit.toString()),
                        // _buildPropertyRow('Legacy WIF:', user.wifLegacy ?? 'N/A'),
                        _buildPropertyRow('Legacy Address:', user.legacyAddressMemoBch ?? 'N/A'),
                        _buildPropertyRow('CashToken Address:', user.bchAddressCashtokenAware ?? 'N/A'),
                        _buildPropertyRow('Balance (BCH):', user.balanceBchDevPath145 ?? 'N/A'),
                        _buildPropertyRow('Balance (Tokens):', user.balanceCashtokensDevPath145 ?? 'N/A'),
                        _buildPropertyRow('Balance (Memo BCH):', user.balanceBchDevPath0Memo ?? 'N/A'),
                        _buildPropertyRow('Tip Amount:', user.tipAmount?.toString() ?? 'N/A'),

                        const SizedBox(height: 12),
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 12),

                        // Section for all available creator fields
                        const Text(
                          'Creator Data',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        _buildPropertyRow('Followers:', creator?.followerCount?.toString() ?? 'N/A'),
                        // _buildPropertyRow('Posts:', creator?.posts?.toString() ?? 'N/A'),
                        _buildPropertyRow('Actions:', creator?.actions?.toString() ?? 'N/A'),
                        // _buildPropertyRow('Imgur URL:', creator?.profileImgurUrl ?? 'N/A', maxLines: 1),
                        // _buildPropertyRow('YouTube URL:', creator?.profileYoutubeId ?? 'N/A', maxLines: 1),
                        _buildPropertyRow('Timestamp:', creator?.created?.toString() ?? 'N/A'),
                        _buildPropertyRow('Has Registered:', creator?.hasRegisteredAsUser.toString() ?? 'N/A'),
                      ],
                    ),
                  ),
                );
              },
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

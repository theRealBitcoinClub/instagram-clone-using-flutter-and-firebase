// user_admin.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/user_service.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';

// The callback now takes both fetched and total count.
typedef CountChangedCallback = void Function(int fetchedCount, int totalCount);

class AdminUsersListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminUsersListPage({super.key, required this.onCountChanged});

  @override
  State<AdminUsersListPage> createState() => _AdminUsersListPageState();
}

class _AdminUsersListPageState extends State<AdminUsersListPage> {
  final UserService _userService = UserService();
  final int _usersPerPage = 20;

  List<MemoModelUser> _users = [];
  bool _isLoading = false;
  bool _hasMoreUsers = true;
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading && _hasMoreUsers) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newUsers = await _userService.getPaginated(
        limit: _usersPerPage,
        startAfterDoc: _lastDocument,
        orderByField: 'createdDateTime',
        descending: true,
      );

      _hasMoreUsers = newUsers.length == _usersPerPage;

      if (newUsers.isNotEmpty) {
        _lastDocument = (newUsers.last as dynamic).docSnapshot; // Assuming your model has a docSnapshot
        setState(() {
          _users.addAll(newUsers);
          widget.onCountChanged(_users.length, _totalCount);
        });
      } else {
        setState(() {
          _hasMoreUsers = false;
        });
      }
    } catch (e) {
      print("Error fetching users page: $e");
      setState(() {
        _hasMoreUsers = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        await _userService.delete(userId);
        setState(() {
          _users.removeWhere((user) => user.id == userId);
          widget.onCountChanged(_users.length, _totalCount - 1);
        });
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
    return StreamBuilder<int>(
      stream: _userService.getTotalCountStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _totalCount = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCountChanged(_users.length, _totalCount);
          });
        }

        if (_users.isEmpty && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_users.isEmpty && !_isLoading && !_hasMoreUsers) {
          return const Center(child: Text('No users found.'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: _users.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _users.length) {
              final user = _users[index];
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
}

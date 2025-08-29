import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/firebase/creator_service.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

// The callback now takes both fetched and total count.
typedef CountChangedCallback = void Function(int fetchedCount, int totalCount);

class AdminCreatorsListPage extends StatefulWidget {
  final CountChangedCallback onCountChanged;

  const AdminCreatorsListPage({super.key, required this.onCountChanged});

  @override
  State<AdminCreatorsListPage> createState() => _AdminCreatorsListPageState();
}

class _AdminCreatorsListPageState extends State<AdminCreatorsListPage> {
  final CreatorService _creatorService = CreatorService();
  final int _creatorsPerPage = 20;

  List<MemoModelCreator> _creators = [];
  bool _isLoading = false;
  bool _hasMoreCreators = true;
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
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading && _hasMoreCreators) {
      _fetchNextPage();
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newCreators = await _creatorService.getPaginated(
        limit: _creatorsPerPage,
        startAfterDoc: _lastDocument,
        orderByField: 'createdDateTime',
        descending: true,
      );

      _hasMoreCreators = newCreators.length == _creatorsPerPage;

      if (newCreators.isNotEmpty) {
        // Assuming your model has a docSnapshot or similar property
        _lastDocument = (newCreators.last as dynamic).docSnapshot;
        setState(() {
          _creators.addAll(newCreators);
          widget.onCountChanged(_creators.length, _totalCount);
        });
      } else {
        setState(() {
          _hasMoreCreators = false;
        });
      }
    } catch (e) {
      print("Error fetching creators page: $e");
      setState(() {
        _hasMoreCreators = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteCreator(BuildContext context, String creatorId, String? creatorName) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete creator "${creatorName ?? 'N/A'}" (ID: $creatorId)? This action cannot be undone.'),
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
        await _creatorService.delete(creatorId);
        setState(() {
          _creators.removeWhere((creator) => creator.id == creatorId);
          widget.onCountChanged(_creators.length, _totalCount - 1);
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Creator $creatorId deleted successfully'), backgroundColor: Colors.green));
        }
      } catch (e) {
        print("Error deleting creator: $e");
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete creator $creatorId: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _creatorService.getTotalCountStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _totalCount = snapshot.data!;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onCountChanged(_creators.length, _totalCount);
          });
        }

        if (_creators.isEmpty && _isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_creators.isEmpty && !_isLoading && !_hasMoreCreators) {
          return const Center(child: Text('No creators found.'));
        }

        return ListView.builder(
          controller: _scrollController,
          itemCount: _creators.length + (_isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < _creators.length) {
              final creator = _creators[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (creator.profileImageAvatar.toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(creator.profileImageAvatar.toString()),
                            onBackgroundImageError: (e, s) {
                              print("Error loading avatar for ${creator.id}: $e");
                            },
                            child: const Icon(Icons.person, size: 30),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${index + 1}. ${creator.name}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('ID: ${creator.id}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 6),
                            _buildPropertyRow('Profile:', creator.profileText, maxLines: 2),
                            _buildPropertyRow('Followers:', creator.followerCount.toString()),
                            _buildPropertyRow('Actions:', creator.actions.toString()),
                            _buildPropertyRow('Created:', _formatDateSafe(creator.created)),
                            _buildPropertyRow('Last Action:', _formatDateSafe(creator.lastActionDate)),
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
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateString;
    }
  }
}

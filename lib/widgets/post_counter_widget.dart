import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PostCounterWidget extends StatefulWidget {
  final VoidCallback onRefresh;
  final ValueChanged<bool> onVisibilityChanged; // Add this callback

  const PostCounterWidget({
    super.key,
    required this.onRefresh,
    required this.onVisibilityChanged, // Add this parameter
  });

  @override
  State<PostCounterWidget> createState() => _PostCounterWidgetState();
}

class _PostCounterWidgetState extends State<PostCounterWidget> {
  int _postCount = 0;
  int _lastKnownCount = 0;
  StreamSubscription? _subscription;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _setupPostCounter();
    _setupKeyboardListener();
  }

  void _setupPostCounter() {
    _subscription = FirebaseFirestore.instance.collection('metadata').doc('posts').snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final newCount = snapshot.data()?['count'] as int? ?? 0;

        setState(() {
          _postCount = newCount;
          // Show widget if count increased since last check
          final shouldBeVisible = newCount > _lastKnownCount && newCount > 1;
          if (_isVisible != shouldBeVisible) {
            _isVisible = shouldBeVisible;
            widget.onVisibilityChanged(_isVisible); // Notify parent
          }
        });
      }
    });
  }

  void _setupKeyboardListener() {
    RawKeyboard.instance.addListener(_handleKeyEvent);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _triggerRefresh();
      }
    }
  }

  void _triggerRefresh() {
    widget.onRefresh();
    setState(() {
      _lastKnownCount = _postCount;
      _isVisible = false;
      widget.onVisibilityChanged(false); // Notify parent when hiding
    });
  }

  void _dismissCounter() {
    setState(() {
      _lastKnownCount = _postCount;
      _isVisible = false;
      widget.onVisibilityChanged(false); // Notify parent when dismissing
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    RawKeyboard.instance.removeListener(_handleKeyEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12.0)),
      child: Row(
        children: [
          Icon(Icons.update, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'There are $_postCount new posts available, pull to refresh',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            onPressed: _dismissCounter, // Use the new method
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

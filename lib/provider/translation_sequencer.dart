import 'dart:async';

class SimpleMutex {
  Completer<void>? _lockCompleter;

  Future<T> protect<T>(Future<T> Function() operation) async {
    // Wait for existing lock to be released
    while (_lockCompleter != null) {
      await _lockCompleter!.future;
    }

    // Acquire lock
    _lockCompleter = Completer<void>();

    try {
      return await operation();
    } finally {
      // Release lock
      _lockCompleter?.complete();
      _lockCompleter = null;
    }
  }

  bool get isLocked => _lockCompleter != null;
}

class TranslationSequencer {
  final SimpleMutex _mutex = SimpleMutex();
  final Map<String, Completer<String>> _pendingRequests = {};

  Future<String> enqueue(String requestId, Future<String> Function() operation) async {
    // If there's already a pending request with the same ID, return its future
    if (_pendingRequests.containsKey(requestId)) {
      // print("🎯 SEQUENCER: Returning existing future for: $requestId");
      return _pendingRequests[requestId]!.future;
    }

    // Create new completer for this request
    final requestCompleter = Completer<String>();
    _pendingRequests[requestId] = requestCompleter;

    try {
      // Use mutex to ensure only one operation runs at a time
      final result = await _mutex.protect(() async {
        // print("🎯 SEQUENCER: Starting operation for: $requestId");

        final result = await operation();

        // print("🎯 SEQUENCER: Completed operation for: $requestId");

        return result;
      });

      // Complete the request completer with the result
      requestCompleter.complete(result);
      return result;
    } catch (e, stack) {
      requestCompleter.completeError(e, stack);
      rethrow;
    } finally {
      _pendingRequests.remove(requestId);
    }
  }

  void clear() {
    _pendingRequests.clear();
  }

  int get pendingCount => _pendingRequests.length;
  bool get isLocked => _mutex.isLocked;
}

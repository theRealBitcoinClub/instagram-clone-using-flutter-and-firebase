// providers/electrum_provider.dart

import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../memo/base/memo_bitcoin_base.dart';

final electrumServiceProvider = AsyncNotifierProvider<ElectrumServiceNotifier, MemoBitcoinBase>(() {
  return ElectrumServiceNotifier();
});

class ElectrumServiceNotifier extends AsyncNotifier<MemoBitcoinBase> {
  Timer? _healthCheckTimer;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _healthCheckInterval = Duration(seconds: 30);

  @override
  Future<MemoBitcoinBase> build() async {
    final bitcoinBase = await _createServiceWithRetry();

    // Start health monitoring
    _startHealthMonitoring(bitcoinBase);

    // Register the onDispose hook.
    ref.onDispose(() {
      _healthCheckTimer?.cancel();
      bitcoinBase.service?.discounnect();
    });

    return bitcoinBase;
  }

  Future<MemoBitcoinBase> _createServiceWithRetry() async {
    for (int attempt = 1; attempt <= _maxReconnectAttempts; attempt++) {
      try {
        final bitcoinBase = await MemoBitcoinBase.create();
        print("Successfully connected to Electrum server");
        _reconnectAttempts = 0;
        return bitcoinBase;
      } catch (e) {
        print("Connection attempt $attempt failed: $e");
        if (attempt == _maxReconnectAttempts) {
          rethrow;
        }
        await Future.delayed(_reconnectDelay * attempt); // Exponential backoff
      }
    }
    throw Exception("Failed to connect after $_maxReconnectAttempts attempts");
  }

  void _startHealthMonitoring(MemoBitcoinBase service) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      await _performHealthCheck(service);
    });
  }

  Future<void> _performHealthCheck(MemoBitcoinBase service) async {
    if (_isReconnecting) return;

    try {
      // Simple health check - try a small request
      await service.provider!.request(ElectrumRequestServerFeatures(), timeout: _reconnectDelay);
      print("Electrum connection health check passed");
    } catch (e) {
      print("Electrum connection health check failed: $e");
      await _reconnect();
    }
  }

  Future<void> _reconnect() async {
    if (_isReconnecting) return;

    _isReconnecting = true;
    _reconnectAttempts++;

    if (_reconnectAttempts > _maxReconnectAttempts) {
      print("Max reconnect attempts reached. Giving up.");
      _isReconnecting = false;
      return;
    }

    print("Attempting to reconnect (attempt $_reconnectAttempts/$_maxReconnectAttempts)...");

    // Clean up old connection
    try {
      final oldService = state.value;
      oldService?.service?.discounnect();
    } catch (e) {
      print("Error disconnecting old service: $e");
    }

    // Wait before reconnecting
    await Future.delayed(_reconnectDelay * _reconnectAttempts);

    try {
      final newService = await _createServiceWithRetry();

      // Update the state with the new service
      state = AsyncData(newService);

      // Restart health monitoring with the new service
      _startHealthMonitoring(newService);

      print("Reconnection successful!");
    } catch (e) {
      print("Reconnection failed: $e");
      // Update state to reflect the error
      state = AsyncError(e, StackTrace.current);
    } finally {
      _isReconnecting = false;
    }
  }

  // Public method to manually trigger reconnection if needed
  Future<void> reconnect() async {
    await _reconnect();
  }

  // Helper method to check connection status
  bool get isConnected {
    final currentService = state.value;
    return currentService != null && currentService.service != null;
  }
}

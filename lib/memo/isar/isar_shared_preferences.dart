// lib/storage/isar_shared_preferences.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';

import 'isar_shared_preferences_model.dart';

class IsarSharedPreferences {
  static Isar? _isar;
  static final Map<String, dynamic> _memoryCache = {};
  static bool _isInitialized = false;
  static final Completer<void> _initCompleter = Completer<void>();

  /// Initialize Isar database
  static Future<void> initialize({required Isar isar}) async {
    if (_isInitialized) return;

    try {
      _isar = isar;

      // Preload all preferences into memory cache for fast access
      final allPrefs = await _isar!.isarPreferences.where().findAll();
      for (final pref in allPrefs) {
        _memoryCache[pref.key] = _deserializeValue(pref);
      }

      _isInitialized = true;
      _initCompleter.complete();
      if (kDebugMode) {
        print('🗄️ IsarSharedPreferences initialized with ${_memoryCache.length} entries');
      }
    } catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    }
  }

  /// Ensure Isar is initialized
  static Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initCompleter.future;
    }
  }

  /// Get an instance (mimics SharedPreferences.getInstance())
  static Future<IsarSharedPreferences> getInstance() async {
    await _ensureInitialized();
    return IsarSharedPreferences._();
  }

  IsarSharedPreferences._();

  // Original SharedPreferences interface methods

  Set<String> getKeys() => _memoryCache.keys.toSet();

  dynamic get(String key) => _memoryCache[key];

  bool? getBool(String key) => _memoryCache[key] as bool?;

  int? getInt(String key) => _memoryCache[key] as int?;

  double? getDouble(String key) => _memoryCache[key] as double?;

  String? getString(String key) => _memoryCache[key] as String?;

  bool containsKey(String key) => _memoryCache.containsKey(key);

  List<String>? getStringList(String key) {
    final value = _memoryCache[key];
    return value is List<String> ? List<String>.from(value) : null;
  }

  // Write methods with Isar persistence
  Future<bool> setBool(String key, bool value) async {
    await _ensureInitialized();
    return _setValue(key, value, boolValue: value);
  }

  Future<bool> setInt(String key, int value) async {
    await _ensureInitialized();
    return _setValue(key, value, intValue: value);
  }

  Future<bool> setDouble(String key, double value) async {
    await _ensureInitialized();
    return _setValue(key, value, doubleValue: value);
  }

  Future<bool> setString(String key, String value) async {
    await _ensureInitialized();
    return _setValue(key, value);
  }

  Future<bool> setStringList(String key, List<String> value) async {
    await _ensureInitialized();
    return _setValue(key, value.toString(), stringListValue: value);
  }

  Future<bool> remove(String key) async {
    await _ensureInitialized();

    try {
      // Remove from Isar
      await _isar!.writeTxn(() async {
        await _isar!.isarPreferences.deleteByKey(key);
      });

      // Remove from memory cache
      _memoryCache.remove(key);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error removing key $key: $e');
      }
      return false;
    }
  }

  Future<bool> commit() async {
    // Isar auto-commits, so this is just for interface compatibility
    return true;
  }

  Future<void> reload() async {
    await _ensureInitialized();

    // Clear cache and reload from Isar
    _memoryCache.clear();
    final allPrefs = await _isar!.isarPreferences.where().findAll();
    for (final pref in allPrefs) {
      _memoryCache[pref.key] = _deserializeValue(pref);
    }
  }

  // Internal helper methods
  Future<bool> _setValue(
    String key,
    dynamic value, {
    bool? boolValue,
    int? intValue,
    double? doubleValue,
    List<String>? stringListValue,
  }) async {
    try {
      final pref = IsarPreference(
        key: key,
        value: value.toString(),
        intValue: intValue,
        doubleValue: doubleValue,
        boolValue: boolValue,
        stringListValue: stringListValue,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _isar!.writeTxn(() async {
        await _isar!.isarPreferences.putByKey(pref);
      });

      // Update memory cache
      _memoryCache[key] = value;

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error setting key $key: $e');
      }
      return false;
    }
  }

  static dynamic _deserializeValue(IsarPreference pref) {
    if (pref.boolValue != null) return pref.boolValue;
    if (pref.intValue != null) return pref.intValue;
    if (pref.doubleValue != null) return pref.doubleValue;
    if (pref.stringListValue != null) return pref.stringListValue;
    return pref.value;
  }

  // Additional utility methods
  Future<int> get entryCount async {
    await _ensureInitialized();
    return await _isar!.isarPreferences.count();
  }

  Future<void> clear() async {
    await _ensureInitialized();

    await _isar!.writeTxn(() async {
      await _isar!.isarPreferences.clear();
    });

    _memoryCache.clear();
  }

  Future<void> close() async {
    await _isar?.close();
    _isInitialized = false;
    _memoryCache.clear();
  }
}

// Extension for backward compatibility
extension IsarSharedPreferencesExtensions on IsarSharedPreferences {
  // Alias methods to match exact SharedPreferences interface
  Future<bool> setBool(String key, bool value) => setBool(key, value);
  Future<bool> setInt(String key, int value) => setInt(key, value);
  Future<bool> setDouble(String key, double value) => setDouble(key, value);
  Future<bool> setString(String key, String value) => setString(key, value);
  Future<bool> setStringList(String key, List<String> value) => setStringList(key, value);
}

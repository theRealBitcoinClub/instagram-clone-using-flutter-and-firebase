// cached_image_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
// cached_image_manager_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/memo_data_checker.dart';
import 'package:path_provider/path_provider.dart';

final cachedImageManagerProvider = Provider<CachedImageManager>((ref) {
  return CachedImageManager();
});

class CachedImageManager {
  static final CachedImageManager _instance = CachedImageManager._internal();
  factory CachedImageManager() => _instance;
  CachedImageManager._internal();

  final Map<String, Completer<File>> _downloadCompleters = {};
  final Map<String, DateTime> _lastAccessTimes = {};
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB cache limit
  static const Duration _cacheDuration = Duration(days: 30); // Keep images for 30 days

  // Generate a cache key from URL
  String _getCacheKey(String url) {
    return sha256.convert(utf8.encode(url)).toString();
  }

  // Get cache directory
  Future<Directory> _getCacheDir() async {
    final Directory dir = await getTemporaryDirectory();
    final Directory cacheDir = Directory('${dir.path}/image_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  // Get cached file for URL
  Future<File?> getCachedImage(String url) async {
    final String key = _getCacheKey(url);
    final Directory cacheDir = await _getCacheDir();
    final File cachedFile = File('${cacheDir.path}/$key');

    // Check if file exists and is not expired
    if (await cachedFile.exists()) {
      final DateTime lastModified = await cachedFile.lastModified();
      if (DateTime.now().difference(lastModified) < _cacheDuration) {
        _lastAccessTimes[key] = DateTime.now();
        return cachedFile;
      } else {
        // Remove expired file
        await cachedFile.delete();
      }
    }

    return null;
  }

  // Download and cache image
  Future<File?> downloadAndCacheImage(String url) async {
    final String key = _getCacheKey(url);

    // If already downloading, return the existing completer
    if (_downloadCompleters.containsKey(key)) {
      return _downloadCompleters[key]!.future;
    }

    final Completer<File> completer = Completer<File>();
    _downloadCompleters[key] = completer;

    try {
      // Check cache first
      File? cachedFile = await getCachedImage(url);
      if (cachedFile != null) {
        completer.complete(cachedFile);
        _downloadCompleters.remove(key);
        return cachedFile;
      }

      if (await MemoDataChecker().checkUrlReturns404(url)) throw Exception('404 - Failed to download image - 404');

      // Download the image
      final http.Response response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        var message = '${response.statusCode} - Failed to download image - ${response.statusCode}';
        print("FAILED TO DOWNLOAD AND CACHE IMAGE $url: $message");
        _downloadCompleters.remove(key);
        completer.completeError(HttpSilentException(response.statusCode, url, message));
        return null;
      }

      // Save to cache
      final Directory cacheDir = await _getCacheDir();
      cachedFile = File('${cacheDir.path}/$key');
      await cachedFile.writeAsBytes(response.bodyBytes);

      if (await MemoDataChecker().isImageValid(imageFile: cachedFile)) {
        throw Exception('IMGUR IMAGE MOVED');
      }

      _lastAccessTimes[key] = DateTime.now();
      completer.complete(cachedFile);
      _downloadCompleters.remove(key);

      // Clean up cache if needed
      _cleanupCache();

      return cachedFile;
    } catch (e) {
      print("ERROR UNEXPECTED FAILED TO DOWNLOAD AND CACHE IMAGE $url: $e");
      _downloadCompleters.remove(key);
      completer.completeError(e);
      // rethrow;
      return null;
    }
  }

  Future<void> _cleanupCache() async {
    final Directory cacheDir = await _getCacheDir();

    try {
      // Get all files in the cache directory
      final List<FileSystemEntity> entities = await cacheDir.list().toList();
      final List<File> files = entities.whereType<File>().toList();

      // Calculate total size and collect file info
      int totalSize = 0;
      final List<Map<String, dynamic>> fileInfo = [];

      for (final File file in files) {
        try {
          final FileStat stats = await file.stat();
          final String fileName = file.path.split(Platform.pathSeparator).last;
          final DateTime lastAccess = _lastAccessTimes[fileName] ?? await file.lastModified();

          fileInfo.add({'file': file, 'size': stats.size, 'lastAccess': lastAccess, 'fileName': fileName});

          totalSize += stats.size;
        } catch (e) {
          print('Error processing file ${file.path}: $e');
          // Skip files that can't be processed
          continue;
        }
      }

      // If over limit, remove oldest files first (based on last access)
      if (totalSize > _maxCacheSize) {
        // Sort by last access time (oldest first)
        fileInfo.sort((a, b) => (a['lastAccess'] as DateTime).compareTo(b['lastAccess'] as DateTime));

        for (final info in fileInfo) {
          if (totalSize <= _maxCacheSize) break;

          try {
            await (info['file'] as File).delete();
            totalSize -= info['size'] as int;
            _lastAccessTimes.remove(info['fileName'] as String);
          } catch (e) {
            print('Error deleting file: $e');
          }
        }
      }

      // Also remove files older than cache duration
      final DateTime cutoff = DateTime.now().subtract(_cacheDuration);
      for (final info in fileInfo) {
        if ((info['lastAccess'] as DateTime).isBefore(cutoff)) {
          try {
            await (info['file'] as File).delete();
            _lastAccessTimes.remove(info['fileName'] as String);
          } catch (e) {
            print('Error deleting expired file: $e');
          }
        }
      }
    } catch (e) {
      print('Error during cache cleanup: $e');
    }
  }

  // // Clean up cache based on size and age
  // Future<void> _cleanupCache() async {
  //   final Directory cacheDir = await _getCacheDir();
  //   final List<File> files = await cacheDir.list().where((entity) => entity is File).map((entity) => entity as File).toList();
  //
  //   // Calculate total size
  //   int totalSize = 0;
  //   final List<Map<String, dynamic>> fileInfo = [];
  //
  //   for (final File file in files) {
  //     final stats = await file.stat();
  //     final String fileName = file.uri.pathSegments.last;
  //     final DateTime lastAccess = _lastAccessTimes[fileName] ?? await file.lastModified();
  //
  //     fileInfo.add({'file': file, 'size': stats.size.toInt(), 'lastAccess': lastAccess});
  //
  //     totalSize += stats.size.toInt();
  //   }
  //
  //   // If over limit, remove oldest files first
  //   if (totalSize > _maxCacheSize) {
  //     fileInfo.sort((a, b) => a['lastAccess'].compareTo(b['lastAccess']));
  //
  //     for (final info in fileInfo) {
  //       if (totalSize <= _maxCacheSize) break;
  //
  //       await info['file'].delete();
  //       totalSize -= info['size'] as int);
  //       _lastAccessTimes.remove(info['file'].uri.pathSegments.last);
  //     }
  //   }
  //
  //   // Also remove files older than cache duration
  //   final DateTime cutoff = DateTime.now().subtract(_cacheDuration);
  //   for (final info in fileInfo) {
  //     if (info['lastAccess'].isBefore(cutoff)) {
  //       await info['file'].delete();
  //       _lastAccessTimes.remove(info['file'].uri.pathSegments.last);
  //     }
  //   }
  // }

  // Clear entire cache
  Future<void> clearCache() async {
    final Directory cacheDir = await _getCacheDir();
    if (await cacheDir.exists()) {
      await cacheDir.delete(recursive: true);
    }
    _downloadCompleters.clear();
    _lastAccessTimes.clear();
  }

  // Get cache size
  Future<int> getCacheSize() async {
    final Directory cacheDir = await _getCacheDir();
    if (!await cacheDir.exists()) return 0;

    int totalSize = 0;
    await for (final file in cacheDir.list().where((entity) => entity is File).cast<File>()) {
      final stats = await file.stat();
      totalSize += stats.size;
    }
    return totalSize;
  }
}

class HttpSilentException implements Exception {
  final int statusCode;
  final String url;
  final String message;

  HttpSilentException(this.statusCode, this.url, this.message);

  @override
  String toString() => 'HTTP $statusCode: $message ($url)';
}

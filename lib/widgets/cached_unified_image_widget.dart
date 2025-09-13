// cached_unified_image_widget.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cached_image_manager.dart';
import 'unified_image_widget.dart';

class CachedUnifiedImageWidget extends UnifiedImageWidget {
  final bool useCache;

  const CachedUnifiedImageWidget({
    super.key,
    required super.imageUrl,
    super.sourceType = ImageSourceType.network,
    super.fitMode = ImageFitMode.cover,
    super.width,
    super.height,
    super.aspectRatio = 16 / 9,
    super.borderRadius = BorderRadius.zero,
    super.border,
    super.backgroundColor,
    super.placeholder,
    super.errorWidget,
    super.showLoadingProgress = true,
    super.theme,
    super.colorScheme,
    super.textTheme,
    this.useCache = true,
  });

  @override
  ConsumerState<UnifiedImageWidget> createState() => _CachedUnifiedImageWidgetState();
}

class _CachedUnifiedImageWidgetState extends UnifiedImageWidgetState {
  // late CachedImageManager _cacheManager;
  late bool _useCache;
  File? _cachedFile;
  bool _isLoadingFromCache = false;

  @override
  void initState() {
    // _cacheManager = (widget as CachedUnifiedImageWidget).cacheManager;
    _useCache = (widget as CachedUnifiedImageWidget).useCache;

    super.initState();

    // Pre-cache the image if needed
    if (_useCache && widget.sourceType == ImageSourceType.network) {
      _preCacheImage();
    }
  }

  @override
  void didUpdateWidget(UnifiedImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldCachedWidget = oldWidget as CachedUnifiedImageWidget;
    final newCachedWidget = widget as CachedUnifiedImageWidget;

    // Check if cache settings changed
    if (oldCachedWidget.useCache != newCachedWidget.useCache ||
        oldCachedWidget.imageUrl != newCachedWidget.imageUrl ||
        oldCachedWidget.sourceType != newCachedWidget.sourceType) {
      _useCache = newCachedWidget.useCache;

      if (_useCache && widget.sourceType == ImageSourceType.network) {
        _preCacheImage();
      }
    }
  }

  Future<void> _preCacheImage() async {
    if (isSvg || isAvif) {
      // Don't cache SVG or AVIF files for now
      return;
    }

    try {
      _isLoadingFromCache = true;
      _cachedFile = await ref.read(cachedImageManagerProvider).downloadAndCacheImage(resolvedUrl);
    } catch (e) {
      print('Failed to cache image: $e');
      _cachedFile = null;
    } finally {
      _isLoadingFromCache = false;
    }
  }

  @override
  Widget buildRasterImage(String url, ColorScheme colorScheme, TextTheme textTheme) {
    // Use cached file if available, otherwise fall back to network
    if (_useCache && _cachedFile != null && widget.sourceType == ImageSourceType.network) {
      return Image.file(
        _cachedFile!,
        fit: getBoxFit(currentFitMode),
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          // Fall back to network if cached file fails
          return super.buildRasterImage(url, colorScheme, textTheme);
        },
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            child: child,
          );
        },
      );
    }

    // Fall back to parent implementation
    return super.buildRasterImage(url, colorScheme, textTheme);
  }

  // Additional methods for cache management
  Future<void> clearCache() async {
    await ref.read(cachedImageManagerProvider).clearCache();
  }

  Future<int> getCacheSize() async {
    return await ref.read(cachedImageManagerProvider).getCacheSize();
  }

  Future<File?> getCachedFile() async {
    if (_useCache && widget.sourceType == ImageSourceType.network) {
      return await ref.read(cachedImageManagerProvider).getCachedImage(resolvedUrl);
    }
    return null;
  }
}

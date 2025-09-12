import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum ImageSourceType {
  network, // For HTTP URLs
  ipfs, // For IPFS CIDs
  asset, // For local assets
  file, // For local files
}

enum ImageFitMode {
  cover, // Fill the space, crop if needed (like BoxFit.cover)
  contain, // Fit within space, maintain aspect ratio (like BoxFit.contain)
  fill, // Stretch to fill space (like BoxFit.fill)
  fitWidth, // Fit to width, maintain aspect ratio
  fitHeight, // Fit to height, maintain aspect ratio
}

class UnifiedImageWidget extends StatelessWidget {
  final String imageUrl;
  final ImageSourceType sourceType;
  final ImageFitMode fitMode;
  final double? width;
  final double? height;
  final double aspectRatio;
  final BorderRadiusGeometry borderRadius;
  final BoxBorder? border;
  final Color? backgroundColor;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showLoadingProgress;
  final ThemeData? theme;
  final ColorScheme? colorScheme;
  final TextTheme? textTheme;

  const UnifiedImageWidget({
    super.key,
    required this.imageUrl,
    this.sourceType = ImageSourceType.network,
    this.fitMode = ImageFitMode.cover,
    this.width,
    this.height,
    this.aspectRatio = 16 / 9,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.backgroundColor,
    this.placeholder,
    this.errorWidget,
    this.showLoadingProgress = true,
    this.theme,
    this.colorScheme,
    this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData effectiveTheme = theme ?? Theme.of(context);
    final ColorScheme effectiveColorScheme = colorScheme ?? effectiveTheme.colorScheme;
    final TextTheme effectiveTextTheme = textTheme ?? effectiveTheme.textTheme;

    // Determine if the image is SVG
    final bool isSvg = imageUrl.toLowerCase().endsWith('.svg');

    // Get the actual URL based on source type
    final String resolvedUrl = _resolveImageUrl(imageUrl, sourceType);

    // Build the image widget based on type
    Widget imageWidget = isSvg
        ? _buildSvgImage(resolvedUrl, effectiveColorScheme, effectiveTextTheme)
        : _buildRasterImage(resolvedUrl, effectiveColorScheme, effectiveTextTheme);

    // Apply constraints and container styling
    return Container(
      width: width,
      height: height,
      constraints: (width != null || height != null) ? null : BoxConstraints(maxWidth: double.infinity, maxHeight: double.infinity),
      decoration: BoxDecoration(
        color: backgroundColor ?? effectiveColorScheme.surface,
        borderRadius: borderRadius,
        border: border ?? Border.all(color: effectiveColorScheme.outline.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: aspectRatio > 0 ? AspectRatio(aspectRatio: aspectRatio, child: imageWidget) : imageWidget,
      ),
    );
  }

  Widget _buildSvgImage(String url, ColorScheme colorScheme, TextTheme textTheme) {
    try {
      return SvgPicture.network(
        url,
        fit: _getBoxFit(fitMode),
        width: width, //set height first, for square SVGs set the width, only set height for correct aspect ratio
        height: height ?? width ?? 48,
        placeholderBuilder: (context) => placeholder ?? _buildDefaultPlaceholder(colorScheme),
        // colorFilter: ColorFilter.mode(colorScheme.onSurface, BlendMode.srcIn),
      );
    } catch (e) {
      return errorWidget ?? _buildErrorWidget('SVG Load Error: $e', colorScheme, textTheme);
    }
  }

  Widget _buildRasterImage(String url, ColorScheme colorScheme, TextTheme textTheme) {
    return Image.network(
      url,
      fit: _getBoxFit(fitMode),
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorWidget('Image Load Error', colorScheme, textTheme);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        if (!showLoadingProgress) {
          return placeholder ?? _buildDefaultPlaceholder(colorScheme);
        }

        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            backgroundColor: colorScheme.surfaceVariant,
          ),
        );
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

  Widget _buildDefaultPlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceVariant.withOpacity(0.5),
      child: Center(child: Icon(Icons.image_outlined, size: 40, color: colorScheme.onSurfaceVariant.withOpacity(0.7))),
    );
  }

  Widget _buildErrorWidget(String message, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      color: colorScheme.surfaceVariant.withOpacity(0.3),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 36),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  BoxFit _getBoxFit(ImageFitMode fitMode) {
    switch (fitMode) {
      case ImageFitMode.cover:
        return BoxFit.cover;
      case ImageFitMode.contain:
        return BoxFit.contain;
      case ImageFitMode.fill:
        return BoxFit.fill;
      case ImageFitMode.fitWidth:
        return BoxFit.fitWidth;
      case ImageFitMode.fitHeight:
        return BoxFit.fitHeight;
    }
  }

  String _resolveImageUrl(String url, ImageSourceType sourceType) {
    switch (sourceType) {
      case ImageSourceType.ipfs:
        return 'https://free-bch.fullstack.cash/ipfs/view/$url';
      case ImageSourceType.network:
        return url;
      case ImageSourceType.asset:
        return url; // For assets, use SvgPicture.asset or Image.asset directly
      case ImageSourceType.file:
        return url; // For files, use SvgPicture.file or Image.file directly
    }
  }
}

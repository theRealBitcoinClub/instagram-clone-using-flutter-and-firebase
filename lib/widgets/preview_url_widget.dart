// widgets/preview_url_widget.dart
import 'package:any_link_preview/any_link_preview.dart';
import 'package:flutter/material.dart';

class PreviewUrlWidget extends StatelessWidget {
  final String url;

  const PreviewUrlWidget({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      height: 125,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        // borderRadius: BorderRadius.circular(0),
        // borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
      ),
      child: ClipRRect(
        // borderRadius: BorderRadius.circular(0),
        // borderRadius: BorderRadius.circular(11.5),
        child: AnyLinkPreview(
          link: url,
          displayDirection: UIDirection.uiDirectionHorizontal,
          backgroundColor: colorScheme.surface,
          borderRadius: 0,
          removeElevation: true,
          boxShadow: [], // Remove any default shadows
          cache: const Duration(days: 100),
          showMultimedia: true,
          bodyMaxLines: 3,
          bodyTextOverflow: TextOverflow.ellipsis,
          titleStyle: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          bodyStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          errorTitle: "Could not load preview",
          placeholderWidget: _buildLoadingWidget(colorScheme, textTheme),
          errorWidget: _buildErrorWidget(colorScheme, textTheme),
          userAgent: 'Mozilla/5.0 (compatible; YourApp/1.0; +https://yourapp.com)',
          headers: {
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Connection': 'keep-alive',
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      height: 125,
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary)),
            ),
            const SizedBox(height: 16),
            Text("Loading preview...", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      height: 125,
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.onSurface.withAlpha(153), size: 40),
            const SizedBox(height: 12),
            Text("Could not load preview", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Text(
            //     "URL: ${_truncateUrl(url)}",
            //     style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            //     textAlign: TextAlign.center,
            //     maxLines: 2,
            //     overflow: TextOverflow.ellipsis,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  String _truncateUrl(String url) {
    if (url.length <= 40) return url;
    return '${url.substring(0, 20)}...${url.substring(url.length - 15)}';
  }
}

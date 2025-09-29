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
      height: 100,
      decoration: BoxDecoration(color: colorScheme.surface),
      child: ClipRRect(
        child: AnyLinkPreview(
          link: url,
          displayDirection: UIDirection.uiDirectionHorizontal,
          backgroundColor: colorScheme.surface,
          borderRadius: 0,
          removeElevation: true,
          boxShadow: [], // Remove any default shadows
          cache: const Duration(days: 1),
          showMultimedia: true,
          bodyMaxLines: 3,
          bodyTextOverflow: TextOverflow.ellipsis,
          titleStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          bodyStyle: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
          // errorTitle: "Could not load preview",
          placeholderWidget: _buildLoadingWidget(colorScheme, textTheme),
          errorWidget: _buildErrorWidget(colorScheme, textTheme),
          // userAgent: 'Mozilla/5.0 (compatible; YourApp/1.0; +https://yourapp.com)',
          // headers: {
          //   'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          //   'Accept-Language': 'en-US,en;q=0.5',
          //   'Connection': 'keep-alive',
          // },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      height: 110,
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
      height: 110,
      color: colorScheme.surfaceVariant,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: colorScheme.onSurface.withAlpha(153), size: 40),
            const SizedBox(height: 12),
            Text("Could not load preview", style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

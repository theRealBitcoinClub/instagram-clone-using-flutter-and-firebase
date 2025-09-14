import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalBrowserLauncher {
  final List<String> whitelistedDomains;
  final List<String>? whitelistPatterns;

  ExternalBrowserLauncher({required this.whitelistedDomains, this.whitelistPatterns});

  Future<void> launchUrlWithConfirmation(BuildContext context, String url) async {
    final Uri? parsedUri = Uri.tryParse(url);
    if (parsedUri == null || !parsedUri.hasScheme) {
      // Handle invalid URL
      return;
    }

    final bool isWhitelisted = _isUrlWhitelisted(url);
    final ThemeData theme = Theme.of(context);
    final bool isDarkTheme = theme.brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return _UrlConfirmationDialog(
          url: url,
          isWhitelisted: isWhitelisted,
          onConfirm: () => _launchBrowser(url),
          onShare: () => _shareUrl(url),
          theme: theme,
          isDarkTheme: isDarkTheme,
        );
      },
    );
  }

  bool _isUrlWhitelisted(String url) {
    final Uri parsedUri = Uri.parse(url);
    final String domain = parsedUri.host;

    // Check against simple domain whitelist
    if (whitelistedDomains.contains(domain)) {
      return true;
    }

    // Check against regex patterns if provided
    if (whitelistPatterns != null) {
      for (final pattern in whitelistPatterns!) {
        try {
          final regex = RegExp(pattern, caseSensitive: false);
          if (regex.hasMatch(url)) {
            return true;
          }
        } catch (e) {
          // Handle invalid regex patterns gracefully
          debugPrint('Invalid regex pattern: $pattern');
        }
      }
    }

    return false;
  }

  Future<void> _launchBrowser(String url) async {
    final Uri parsedUri = Uri.parse(url);
    if (await canLaunchUrl(parsedUri)) {
      await launchUrl(parsedUri);
    }
  }

  Future<void> _shareUrl(String url) async {
    await Share.share(url, subject: 'Check out this link', sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100));
  }
}

class _UrlConfirmationDialog extends StatelessWidget {
  final String url;
  final bool isWhitelisted;
  final VoidCallback onConfirm;
  final VoidCallback onShare;
  final ThemeData theme;
  final bool isDarkTheme;

  const _UrlConfirmationDialog({
    required this.url,
    required this.isWhitelisted,
    required this.onConfirm,
    required this.onShare,
    required this.theme,
    required this.isDarkTheme,
  });

  Color _getButtonColor(Color lightColor, Color darkColor) {
    return isDarkTheme ? darkColor : lightColor;
  }

  Color _getTextColor(Color lightColor, Color darkColor) {
    return isDarkTheme ? darkColor : lightColor;
  }

  @override
  Widget build(BuildContext context) {
    final Color dialogBackgroundColor = isDarkTheme ? theme.dialogBackgroundColor : theme.colorScheme.surface;

    final Color textColor = theme.textTheme.bodyLarge?.color ?? (isDarkTheme ? Colors.white : Colors.black);

    final Color surfaceVariant = theme.colorScheme.surfaceVariant;
    final Color onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDarkTheme ? theme.colorScheme.outline.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      backgroundColor: dialogBackgroundColor,
      elevation: isDarkTheme ? 8 : 4,
      shadowColor: isDarkTheme ? Colors.black.withOpacity(0.5) : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icons
            Row(
              children: [
                // Whitelist status icon
                Icon(
                  isWhitelisted ? Icons.check_circle : Icons.warning_rounded,
                  color: isWhitelisted ? theme.colorScheme.primary : theme.colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Text(
                    'Open link in browser',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: textColor),
                  ),
                ),
                // Close button
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: onSurfaceVariant),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 16,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // URL text widget
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkTheme ? surfaceVariant.withOpacity(0.3) : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkTheme ? theme.colorScheme.outline.withOpacity(0.2) : theme.colorScheme.outline.withOpacity(0.1),
                ),
              ),
              child: SelectableText(
                url,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor, fontFamily: 'Monospace', fontSize: 13),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(Colors.red.shade600, Colors.red.shade400),
                    foregroundColor: Colors.white,
                    textStyle: theme.textTheme.labelLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                // Share button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onShare();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(Colors.blue.shade600, Colors.blue.shade400),
                    foregroundColor: Colors.white,
                    textStyle: theme.textTheme.labelLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Share'),
                ),
                const SizedBox(width: 12),
                // Confirm button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getButtonColor(Colors.green.shade600, Colors.green.shade400),
                    foregroundColor: Colors.white,
                    textStyle: theme.textTheme.labelLarge,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Yes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

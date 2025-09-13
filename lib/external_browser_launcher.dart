import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalBrowserLauncher {
  final List<String> whitelistedDomains;

  ExternalBrowserLauncher({required this.whitelistedDomains});

  Future<void> launchUrlWithConfirmation(BuildContext context, String url) async {
    final Uri? parsedUri = Uri.tryParse(url);
    if (parsedUri == null || !parsedUri.hasScheme) {
      // Handle invalid URL
      return;
    }

    final String domain = parsedUri.host;
    final bool isWhitelisted = whitelistedDomains.contains(domain);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return _UrlConfirmationDialog(
          url: url,
          isWhitelisted: isWhitelisted,
          onConfirm: () => _launchBrowser(url),
          onShare: () => _shareUrl(url),
        );
      },
    );
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

  const _UrlConfirmationDialog({required this.url, required this.isWhitelisted, required this.onConfirm, required this.onShare});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with icons
            Row(
              children: [
                // Whitelist status icon
                Icon(isWhitelisted ? Icons.check_circle : Icons.warning, color: isWhitelisted ? Colors.green : Colors.orange, size: 24),
                const SizedBox(width: 8),
                // Title
                const Expanded(
                  child: Text('Open link in browser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // URL text widget
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(url, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 24),
            // Buttons row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel button
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                // Share button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onShare();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('Share'),
                ),
                const SizedBox(width: 8),
                // Confirm button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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

import 'package:flutter/material.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalBrowserLauncher {
  final List<String>? whitelistedDomains;
  final List<String>? whitelistPatterns;

  ExternalBrowserLauncher({this.whitelistedDomains, this.whitelistPatterns});

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
          onShare: () {
            SharePlus.instance.share(ShareParams(text: url));
          },
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
    if (whitelistedDomains != null && whitelistedDomains!.contains(domain)) {
      return true;
    }

    return MemoRegExp.isUrlWhitelisted(url);
  }

  Future<void> _launchBrowser(String url) async {
    final Uri parsedUri = Uri.parse(url);
    if (await canLaunchUrl(parsedUri)) {
      await launchUrl(parsedUri);
    }
  }

  // Future<void> _shareUrl(String url) async {
  //   await Share.share(url, subject: 'Check out this link', sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100));
  // }
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
        borderRadius: BorderRadius.circular(9),
        side: BorderSide(
          color: isDarkTheme ? theme.colorScheme.outline.withOpacity(0.3) : theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      backgroundColor: dialogBackgroundColor,
      elevation: isDarkTheme ? 8 : 4,
      shadowColor: isDarkTheme ? Colors.black.withOpacity(0.5) : null,
      child: Padding(
        padding: const EdgeInsets.all(18),
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
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconAction(text: "cancel", size: 12, onTap: () => Navigator.of(context).pop(), type: IAB.cancel, icon: Icons.cancel_outlined),
                  IconAction(
                    text: "share",
                    size: 12,
                    onTap: () {
                      // Navigator.of(context).pop();
                      onShare();
                    },
                    type: IAB.alternative,
                    icon: Icons.share_outlined,
                  ),
                  SizedBox(width: 1),
                  IconAction(
                    text: "yes",
                    size: 12,
                    onTap: () {
                      Navigator.of(context).pop();
                      onConfirm();
                    },
                    type: IAB.success,
                    icon: Icons.check_circle_outline,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

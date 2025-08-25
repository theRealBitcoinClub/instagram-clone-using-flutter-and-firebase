import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
// import 'package:instagram_clone1/utils/colors.dart'; // REMOVE THIS
import 'package:instagram_clone1/utils/snackbar.dart'; // Ensure this uses themed SnackBars
import 'package:pretty_qr_code/pretty_qr_code.dart';

// Logging placeholder (remains the same)
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: QrCodeDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends StatefulWidget {
  final MemoModelUser user;
  final bool initialToggleState;
  final ValueChanged<bool> onToggle;

  const QrCodeDialog({Key? key, required this.user, required this.initialToggleState, required this.onToggle})
    : super(key: key);

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  late bool _isCashtokenFormat;

  @override
  void initState() {
    super.initState();
    _isCashtokenFormat = widget.initialToggleState;
  }

  Future<void> _copyToClipboard(BuildContext context, String text, String successMessage) async {
    // Pass context for themed snackbar
    if (text.isEmpty) {
      if (mounted) showSnackBar("Nothing to copy.", context); // Use passed context
      return;
    }
    await FlutterClipboard.copyWithCallback(
      text: text,
      onSuccess: () {
        if (mounted) showSnackBar(successMessage, context); // Use passed context
      },
      onError: (error) {
        _logError("Copy to clipboard failed", error);
        if (mounted) showSnackBar('Copy failed. See logs for details.', context); // Use passed context
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context); // Get the current theme
    final ColorScheme colorScheme = theme.colorScheme;

    final String addressToShow = _isCashtokenFormat
        ? widget.user.bchAddressCashtokenAwareCtFormat
        : widget.user.legacyAddressMemoBchAsCashaddress;
    final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo-128x128";
    final String toggleButtonText = _isCashtokenFormat ? "SHOW MEMO QR" : "SHOW CASHTOKEN QR";

    // Style for the primary action button (Copy Address)
    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      textStyle: theme.textTheme.labelLarge,
      minimumSize: const Size(double.infinity, 40), // Make it full width
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    // Style for the secondary action button (Toggle QR Type)
    final ButtonStyle secondaryButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.primary, // Use primary color for text
      textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      minimumSize: const Size(double.infinity, 40),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    // Style for the dismiss button (Close)
    final ButtonStyle dismissButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface.withOpacity(0.7), // Muted color for dismiss
      textStyle: theme.textTheme.labelLarge,
      minimumSize: const Size(double.infinity, 40),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    return SimpleDialog(
      // backgroundColor will be from theme.dialogTheme.backgroundColor
      // shape will be from theme.dialogTheme.shape
      // titleTextStyle (if you add a title) will be from theme.dialogTheme.titleTextStyle
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16), // Adjusted padding
      children: [
        if (addressToShow.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(8.0), // Padding around QR code
            decoration: BoxDecoration(
              color: Colors.white, // QR codes are best on a white background for scannability
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: PrettyQrView.data(
              data: addressToShow,
              decoration: PrettyQrDecoration(
                // The image overlay is an asset, its colors are fixed by the asset itself.
                image: PrettyQrDecorationImage(image: AssetImage("assets/images/$qrImageAsset.png")),
                // You can style the QR code elements (dots, background) here if `PrettyQrDecoration` supports it
                // and if you want to theme them, but usually black on white is best.
                // shape: PrettyQrSmoothSymbol(color: theme.colorScheme.onSurface), // Example: if QR dots can be themed
              ),
              // size: 200, // You can specify a size
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0), // More padding for this message
            child: Text(
              "Address not available.",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        const SizedBox(height: 24), // Increased spacing
        ElevatedButton(
          // Changed to ElevatedButton for primary action
          style: primaryButtonStyle,
          onPressed: () {
            _copyToClipboard(context, addressToShow, "Address copied!"); // Pass context
            Navigator.of(context).pop();
          },
          child: const Text("COPY ADDRESS"),
        ),
        const SizedBox(height: 12),
        TextButton(
          style: secondaryButtonStyle,
          onPressed: () {
            setState(() {
              _isCashtokenFormat = !_isCashtokenFormat;
            });
            widget.onToggle(_isCashtokenFormat);
          },
          child: Text(toggleButtonText),
        ),
        const SizedBox(height: 8),
        TextButton(style: dismissButtonStyle, onPressed: () => Navigator.of(context).pop(), child: const Text("CLOSE")),
      ],
    );
  }
}

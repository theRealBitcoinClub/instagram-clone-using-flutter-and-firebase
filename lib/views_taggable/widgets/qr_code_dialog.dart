import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

// Basic logging placeholder
void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends StatefulWidget {
  final MemoModelUser user;
  final bool initialToggleState;
  final ValueChanged<bool> onToggle; // Callback to inform parent of toggle

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

  Future<void> _copyToClipboard(String text, String successMessage) async {
    if (text.isEmpty) {
      if (mounted) showSnackBar("Nothing to copy.", context);
      return;
    }
    await FlutterClipboard.copyWithCallback(
      text: text,
      onSuccess: () {
        if (mounted) showSnackBar(successMessage, context);
      },
      onError: (error) {
        _logError("Copy to clipboard failed", error);
        if (mounted) showSnackBar('Copy failed. See logs for details.', context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String addressToShow = _isCashtokenFormat
        ? widget.user.bchAddressCashtokenAwareCtFormat
        : widget.user.legacyAddressMemoBchAsCashaddress;
    final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo-128x128";
    final String toggleButtonText = _isCashtokenFormat ? "SHOW MEMO QR" : "SHOW CASHTOKEN QR";

    return SimpleDialog(
      contentPadding: const EdgeInsets.all(16.0),
      children: [
        if (addressToShow.isNotEmpty)
          PrettyQrView.data(
            data: addressToShow,
            decoration: PrettyQrDecoration(
              // Ensure these assets exist and are in pubspec.yaml
              image: PrettyQrDecorationImage(image: AssetImage("assets/images/$qrImageAsset.png")),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Address not available.", textAlign: TextAlign.center),
          ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            _copyToClipboard(addressToShow, "Address copied!");
            Navigator.of(context).pop(); // Close dialog after copy
          },
          child: const Text("COPY ADDRESS"),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            setState(() {
              _isCashtokenFormat = !_isCashtokenFormat;
            });
            widget.onToggle(_isCashtokenFormat); // Notify parent of the change
            // No need to pop and re-show, the dialog rebuilds itself.
          },
          child: Text(
            toggleButtonText,
            style: const TextStyle(fontWeight: FontWeight.bold, color: blueColor),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}

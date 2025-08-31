import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

import '../../utils/snackbar.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: QrCodeDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends StatefulWidget {
  final String legacyAddress;
  final String? cashtokenAddress;
  final bool initialToggleState;
  final ValueChanged<bool> onToggle;

  const QrCodeDialog({Key? key, required this.legacyAddress, this.cashtokenAddress, required this.initialToggleState, required this.onToggle})
    : super(key: key);

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  late bool _isCashtokenFormat;

  @override
  void initState() {
    super.initState();
    // The dialog should persist its toggle state if both addresses are available.
    // Otherwise, it defaults to the legacy QR code.
    final bool isToggleEnabled = widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty;
    _isCashtokenFormat = isToggleEnabled && widget.initialToggleState;
  }

  String convertToBchFormat(legacyAddress) {
    const cashAddressHrp = 'bitcoincash';

    try {
      return BitcoinCashAddress.fromBaseAddress(
        P2pkhAddress.fromAddress(address: legacyAddress, network: BitcoinNetwork.mainnet, type: P2pkhAddressType.p2pkh),
      ).address;

      // 1. Create a BitcoinCashAddress object from the legacy string.
      // The factory constructor automatically detects the address type and decodes it.
      final BitcoinCashAddress typedAddress = BitcoinCashAddress(legacyAddress);

      // 2. Use the toAddress() method to get the CashAddr format with the desired HRP.
      // The library handles the conversion from the internal representation to the new format.
      return typedAddress.toAddress(BitcoinCashNetwork.mainnet, cashAddressHrp);
    } catch (e) {
      print('An error occurred during conversion: $e');
      return legacyAddress;
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text, String successMessage) async {
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
  Widget build(BuildContext ctx) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final bool isToggleEnabled = widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty;

    final String addressToShow = _isCashtokenFormat ? widget.cashtokenAddress! : convertToBchFormat(widget.legacyAddress);
    final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo-128x128";
    final String toggleButtonText = _isCashtokenFormat ? "SHOW MEMO QR" : "SHOW CASHTOKEN QR";

    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      textStyle: theme.textTheme.labelLarge,
      minimumSize: const Size(double.infinity, 40),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    final ButtonStyle secondaryButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.primary,
      textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
      minimumSize: const Size(double.infinity, 40),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    final ButtonStyle dismissButtonStyle = TextButton.styleFrom(
      foregroundColor: colorScheme.onSurface.withOpacity(0.7),
      textStyle: theme.textTheme.labelLarge,
      minimumSize: const Size(double.infinity, 40),
      padding: const EdgeInsets.symmetric(vertical: 12),
    );

    return SimpleDialog(
      contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey(addressToShow),
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: PrettyQrView.data(
              data: addressToShow,
              decoration: PrettyQrDecoration(image: PrettyQrDecorationImage(image: AssetImage("assets/images/$qrImageAsset.png"))),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: primaryButtonStyle,
          onPressed: () {
            _copyToClipboard(context, addressToShow, "Address copied!");
            Navigator.of(ctx).pop();
          },
          child: const Text("COPY ADDRESS"),
        ),
        const SizedBox(height: 12),
        if (isToggleEnabled)
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
        TextButton(style: dismissButtonStyle, onPressed: () => Navigator.of(ctx).pop(), child: const Text("CLOSE")),
      ],
    );
  }
}

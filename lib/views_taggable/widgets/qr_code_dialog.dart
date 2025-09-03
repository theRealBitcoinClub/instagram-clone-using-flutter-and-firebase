import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../memo/model/memo_model_creator.dart';
import '../../memo/model/memo_model_user.dart';
import '../../utils/snackbar.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: QrCodeDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends StatefulWidget {
  final String legacyAddress;
  final String? cashtokenAddress;

  const QrCodeDialog({Key? key, required this.legacyAddress, this.cashtokenAddress}) : super(key: key);

  @override
  State<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends State<QrCodeDialog> {
  late bool _isCashtokenFormat;
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadToggleState();
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to cashtoken format if available, otherwise use legacy
    final bool isToggleEnabled = widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty;
    final bool defaultState = isToggleEnabled;

    _isCashtokenFormat = prefs.getBool('qr_code_toggle_state') ?? defaultState;

    // Ensure we don't try to use cashtoken format if it's not available
    if (_isCashtokenFormat && !isToggleEnabled) {
      _isCashtokenFormat = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('qr_code_toggle_state', value);
  }

  String convertToBchFormat(String legacyAddress) {
    const cashAddressHrp = 'bitcoincash';

    try {
      return BitcoinCashAddress.fromBaseAddress(
        P2pkhAddress.fromAddress(address: legacyAddress, network: BitcoinNetwork.mainnet, type: P2pkhAddressType.p2pkh),
      ).address;
    } catch (e) {
      _logError('An error occurred during address conversion: $e');
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
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SimpleDialog(
            contentPadding: const EdgeInsets.all(20),
            children: [Center(child: CircularProgressIndicator(color: colorScheme.primary))],
          );
        }

        final bool isToggleEnabled = widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty;
        final String addressToShow = _isCashtokenFormat ? widget.cashtokenAddress! : convertToBchFormat(widget.legacyAddress);
        final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo-128x128";

        final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          textStyle: theme.textTheme.labelLarge,
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
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          children: [
            // Tab-like selector
            if (isToggleEnabled) _buildTabSelector(theme, colorScheme),

            const SizedBox(height: 16),

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
                Navigator.of(context).pop();
              },
              child: const Text("COPY ADDRESS"),
            ),
            const SizedBox(height: 12),
            TextButton(style: dismissButtonStyle, onPressed: () => Navigator.of(context).pop(), child: const Text("CLOSE")),
          ],
        );
      },
    );
  }

  Widget _buildTabSelector(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          // Legacy Address Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isCashtokenFormat) {
                  _toggleFormat(false);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: !_isCashtokenFormat ? colorScheme.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Center(
                  child: Text(
                    "MEMO",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: !_isCashtokenFormat ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: !_isCashtokenFormat ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // CashToken Address Tab
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isCashtokenFormat) {
                  _toggleFormat(true);
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _isCashtokenFormat ? colorScheme.primary : Colors.transparent,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Center(
                  child: Text(
                    "BCH & TOKEN",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: _isCashtokenFormat ? colorScheme.onPrimary : colorScheme.onSurface,
                      fontWeight: _isCashtokenFormat ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFormat(bool isCashtoken) async {
    setState(() {
      _isCashtokenFormat = isCashtoken;
    });
    await _saveToggleState(isCashtoken);
  }
}

// --- Simplified BCH QR Code Dialog Helper ---
void showQrCodeDialog({required BuildContext context, required ThemeData theme, MemoModelUser? user, MemoModelCreator? creator}) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return QrCodeDialog(
        cashtokenAddress: user != null
            ? user.bchAddressCashtokenAware
            : creator!.hasRegisteredAsUser
            ? creator.bchAddressCashtokenAware
            : null,
        legacyAddress: user != null
            ? user.legacyAddressMemoBch
            : creator!.hasRegisteredAsUser
            ? creator.id
            : creator.id,
      );
    },
  );
}

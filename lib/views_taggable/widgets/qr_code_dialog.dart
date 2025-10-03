import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/provider/profile_balance_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../memo/model/memo_model_creator.dart';
import '../../memo/model/memo_model_user.dart';
import '../../provider/profile_data_model_provider.dart';
import '../../utils/snackbar.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: QrCodeDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends ConsumerStatefulWidget {
  final String legacyAddress;
  final String? cashtokenAddress;
  final String memoProfileId;
  final bool memoOnly;

  const QrCodeDialog({Key? key, required this.legacyAddress, this.cashtokenAddress, required this.memoProfileId, this.memoOnly = false})
    : super(key: key);

  @override
  ConsumerState<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends ConsumerState<QrCodeDialog> {
  late bool _isCashtokenFormat;
  late Future<void> _initFuture;
  bool _isToggleEnabled = true;
  var toggleKey;

  @override
  void initState() {
    super.initState();
    toggleKey = 'qr_code_toggle_state${widget.memoProfileId}';
    _initFuture = _loadToggleState(context);
  }

  Future<void> _loadToggleState(BuildContext ctx) async {
    final prefs = await SharedPreferences.getInstance();
    _isToggleEnabled = widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty;
    if (widget.memoOnly) _isToggleEnabled = false;
    final bool defaultState = false; //DEFAULT STATE IS MEMO AFTER INSTALL

    // Only use saved state if it's valid for current dialog
    final savedState = prefs.getBool(toggleKey);
    _isCashtokenFormat = (savedState != null && _isToggleEnabled) ? savedState : defaultState;

    // Reset to default if saved state is invalid for current address
    if (_isCashtokenFormat && !_isToggleEnabled) {
      _isCashtokenFormat = false;
      await _saveToggleState(false);
    }

    // Start QR dialog refresh with the selected mode
    _startQrDialogRefresh(ctx);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(toggleKey, value);
  }

  void _startQrDialogRefresh(BuildContext ctx) {
    // final profileNotifier = ref.read(profileDataProvider.notifier);
    ref.read(profileBalanceProvider).startQrDialogRefresh(_isCashtokenFormat, ctx);
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
      if (mounted) showSnackBar(type: SnackbarType.info, "Nothing to copy.");
      return;
    }
    await FlutterClipboard.copyWithCallback(
      text: text,
      onSuccess: () {
        if (mounted) showSnackBar(type: SnackbarType.success, successMessage);
      },
      onError: (error) {
        _logError("Copy to clipboard failed", error);
        if (mounted) showSnackBar(type: SnackbarType.error, 'Copy failed. See logs for details.');
      },
    );
  }

  Future<void> _shareAddress(String address) async {
    try {
      await Share.share(address, subject: 'My Bitcoin Cash Address');
    } catch (e) {
      _logError("Share failed", e);
      if (mounted) showSnackBar(type: SnackbarType.error, 'Share failed. See logs for details.');
    }
  }

  void _toggleFormat(bool isCashtoken, BuildContext ctx) async {
    if (!mounted) return;

    setState(() {
      _isCashtokenFormat = isCashtoken;
    });

    // Update QR dialog refresh mode in provider
    // final profileNotifier = ref.read(profileDataProvider.notifier);
    ref.read(profileBalanceProvider).setQrDialogMode(isCashtoken, ctx);

    await _saveToggleState(isCashtoken);
  }

  String _formatBalance(int balance) {
    return balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _getBalanceText(bool isCashtokenTab, MemoModelCreator? creator) {
    if (isCashtokenTab) {
      final bch = creator?.balanceBch ?? 0;
      final token = creator?.balanceToken ?? 0;
      return 'BCH: ${_formatBalance(bch)} sats\n${MemoBitcoinBase.tokenTicker}: ${_formatBalance(token)} units';
    } else {
      final balance = creator?.balanceMemo ?? 0;
      return 'MEMO: ${_formatBalance(balance)} sats';
    }
  }

  @override
  Widget build(BuildContext dialogCtx) {
    final ThemeData theme = Theme.of(dialogCtx);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    // Watch for creator updates using the new provider
    final profileData = ref.watch(profileDataNotifier);
    final creator = profileData.value?.creator;

    return FutureBuilder(
      future: _initFuture,
      builder: (builderCtx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Loading...', style: textTheme.bodyMedium),
                ],
              ),
            ),
          );
        }

        final String addressShorter = _isCashtokenFormat ? widget.cashtokenAddress! : convertToBchFormat(widget.legacyAddress).substring(12);
        final String addressToShow = _isCashtokenFormat ? widget.cashtokenAddress! : convertToBchFormat(widget.legacyAddress);
        final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo";
        final String balanceText = _getBalanceText(_isCashtokenFormat, creator);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with balance and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        balanceText,
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () => closeDialog(dialogCtx),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                if (_isToggleEnabled) const SizedBox(height: 6),

                // Tab-like selector
                if (_isToggleEnabled) _buildTabSelector(theme, colorScheme, dialogCtx),

                const SizedBox(height: 16),

                // QR Code
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: GestureDetector(
                    onTap: () {
                      _copyToClipboard(dialogCtx, addressToShow, "Address copied!");
                    },
                    onLongPress: () {
                      closeDialog(dialogCtx);
                      // Navigator.of(dialogCtx).pop();
                    },
                    child: Container(
                      key: ValueKey(addressToShow),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor, width: 1),
                      ),
                      child: PrettyQrView.data(
                        data: addressToShow,
                        decoration: PrettyQrDecoration(image: PrettyQrDecorationImage(image: AssetImage("assets/images/$qrImageAsset.png"))),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Address text
                SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Tooltip(
                      message: addressToShow,
                      child: Text(
                        addressShorter,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(dialogCtx, addressToShow, "Address copied!"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.copy, size: 18, color: Colors.white),
                        label: Text('COPY', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareAddress(addressToShow),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[900],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: Icon(Icons.share, size: 18, color: Colors.white),
                        label: Text('SHARE', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabSelector(ThemeData theme, ColorScheme colorScheme, dialogCtx) {
    return Container(
      height: 40,
      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          // Legacy Address Tab (Memo)
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (_isCashtokenFormat) {
                  _toggleFormat(false, dialogCtx);
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

          // CashToken Address Tab (BCH & Token)
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isCashtokenFormat) {
                  _toggleFormat(true, dialogCtx);
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
                    MemoBitcoinBase.tokenTicker,
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

  void closeDialog(BuildContext ctx) {
    ref.read(profileBalanceProvider).stopQrDialogRefresh();
    Navigator.of(ctx).pop();
  }
}

// --- Simplified BCH QR Code Dialog Helper ---
void showQrCodeDialog({required BuildContext ctx, MemoModelUser? user, MemoModelCreator? creator, bool memoOnly = false}) {
  if (creator != null) {
    showDialog(
      context: ctx,
      builder: (ctx) {
        return QrCodeDialog(
          cashtokenAddress: creator.hasRegisteredAsUserFixed ? creator.bchAddressCashtokenAware : null,
          legacyAddress: creator.id,
          memoProfileId: creator.id,
          memoOnly: memoOnly,
        );
      },
    );
  } else if (user != null) {
    showDialog(
      context: ctx,
      builder: (ctx) {
        return QrCodeDialog(
          cashtokenAddress: user.bchAddressCashtokenAware,
          legacyAddress: user.legacyAddressMemoBch,
          memoProfileId: user.id,
          memoOnly: memoOnly,
        );
      },
    );
  } else
    throw Exception("This shall not happen");
}

import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../memo/model/memo_model_creator.dart';
import '../../memo/model/memo_model_user.dart';
import '../../provider/profile_providers.dart';
import '../../utils/snackbar.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: QrCodeDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends ConsumerStatefulWidget {
  final String legacyAddress;
  final String? cashtokenAddress;
  final MemoModelCreator? creator;
  final MemoModelUser? user;
  final bool memoOnly;

  const QrCodeDialog({Key? key, required this.legacyAddress, this.cashtokenAddress, this.creator, this.user, this.memoOnly = false})
    : super(key: key);

  @override
  ConsumerState<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends ConsumerState<QrCodeDialog> {
  late bool _isCashtokenFormat;
  late Future<void> _initFuture;
  Timer? _balanceRefreshTimer;
  final Duration _refreshInterval = Duration(seconds: kDebugMode ? 60 : 3);
  bool _isToggleEnabled = true;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadToggleState();
  }

  @override
  void dispose() {
    _balanceRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadToggleState() async {
    final prefs = await SharedPreferences.getInstance();
    _isToggleEnabled = widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty;
    if (widget.memoOnly) _isToggleEnabled = false;
    final bool defaultState = _isToggleEnabled;

    _isCashtokenFormat = prefs.getBool('qr_code_toggle_state') ?? defaultState;

    if (_isCashtokenFormat && !_isToggleEnabled) {
      _isCashtokenFormat = false;
    }
    // Start/restart the refresh timer for the selected tab
    _startBalanceRefresh(_isCashtokenFormat);

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
      if (mounted) showSnackBar(type: SnackbarType.info, "Nothing to copy.", context);
      return;
    }
    await FlutterClipboard.copyWithCallback(
      text: text,
      onSuccess: () {
        if (mounted) showSnackBar(type: SnackbarType.success, successMessage, context);
      },
      onError: (error) {
        _logError("Copy to clipboard failed", error);
        if (mounted) showSnackBar(type: SnackbarType.error, 'Copy failed. See logs for details.', context);
      },
    );
  }

  Future<void> _shareAddress(String address) async {
    try {
      await Share.share(address, subject: 'My Bitcoin Cash Address');
    } catch (e) {
      _logError("Share failed", e);
      if (mounted) showSnackBar(type: SnackbarType.error, 'Share failed. See logs for details.', context);
    }
  }

  void _startBalanceRefresh(bool isCashtokenTab) {
    _balanceRefreshTimer?.cancel();

    final profileNotifier = ref.read(profileCreatorStateProvider.notifier);
    final isAutoRefreshRunning = profileNotifier.isAutoRefreshRunning();

    // Only start refresh timer if general auto-refresh isn't running
    if (!isAutoRefreshRunning) {
      _balanceRefreshTimer = Timer.periodic(_refreshInterval, (_) {
        _refreshBalance(isCashtokenTab);
      });
    }
  }

  void _refreshBalance(bool isCashtokenTab) {
    final profileNotifier = ref.read(profileCreatorStateProvider.notifier);

    if (isCashtokenTab) {
      profileNotifier.refreshMahakkaBalance();
    } else {
      profileNotifier.refreshMemoBalance();
    }
  }

  void _toggleFormat(bool isCashtoken) async {
    setState(() {
      _isCashtokenFormat = isCashtoken;
    });

    // Immediately refresh the balance for the selected tab
    _refreshBalance(isCashtoken);

    // Start/restart the refresh timer for the selected tab
    _startBalanceRefresh(isCashtoken);

    await _saveToggleState(isCashtoken);
  }

  String _formatBalance(int balance) {
    // Format with thousand separators (no decimals)
    return balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  String _getBalanceText(bool isCashtokenTab, MemoModelCreator? creator) {
    if (isCashtokenTab) {
      // Mahakka balance (BCH & Tokens)
      final balance = creator?.balanceBch ?? 0;
      return 'Balance: ${_formatBalance(balance)}';
    } else {
      // Memo balance
      final balance = creator?.balanceMemo ?? 0;
      return 'Balance: ${_formatBalance(balance)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;
    // Watch for creator updates
    final creatorState = ref.watch(profileCreatorStateProvider);

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
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

        final String addressToShow = _isCashtokenFormat ? widget.cashtokenAddress! : convertToBchFormat(widget.legacyAddress);
        final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo";
        final String balanceText = _getBalanceText(_isCashtokenFormat, creatorState.value);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                        style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: colorScheme.onSurface),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                if (_isToggleEnabled) const SizedBox(height: 16),

                // Tab-like selector
                if (_isToggleEnabled) _buildTabSelector(theme, colorScheme),

                const SizedBox(height: 16),

                // QR Code
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: GestureDetector(
                    onTap: () {
                      _copyToClipboard(context, addressToShow, "Address copied!");
                    },
                    onLongPress: () {
                      Navigator.of(context).pop();
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

                // Address text - single line with ellipsis
                SizedBox(
                  width: double.infinity,
                  child: Tooltip(
                    message: addressToShow,
                    child: Text(
                      addressToShow,
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _copyToClipboard(context, addressToShow, "Address copied!"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white, // White text and icon
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
                          backgroundColor: Colors.yellow[900], // Dark yellow background
                          foregroundColor: Colors.white, // White text and icon
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

  Widget _buildTabSelector(ThemeData theme, ColorScheme colorScheme) {
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

          // CashToken Address Tab (BCH & Token)
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
}

// --- Simplified BCH QR Code Dialog Helper ---
void showQrCodeDialog({
  required BuildContext context,
  required ThemeData theme,
  MemoModelUser? user,
  MemoModelCreator? creator,
  bool memoOnly = false,
}) {
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
        user: user,
        creator: creator,
        memoOnly: memoOnly,
      );
    },
  );
}

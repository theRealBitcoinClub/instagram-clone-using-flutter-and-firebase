import 'dart:async';

import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/provider/profile_balance_provider.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';

import '../../main.dart';
import '../../memo/model/memo_model_creator.dart';
import '../../memo/model/memo_model_user.dart';
import '../../utils/snackbar.dart';

void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: QrCodeDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class QrCodeDialog extends ConsumerStatefulWidget {
  final String memoProfileId;
  final bool memoOnly;
  final bool tokenOnly;

  const QrCodeDialog({Key? key, required this.memoProfileId, this.memoOnly = false, this.tokenOnly = false}) : super(key: key);

  @override
  ConsumerState<QrCodeDialog> createState() => _QrCodeDialogState();
}

class _QrCodeDialogState extends ConsumerState<QrCodeDialog> {
  bool _isCashtokenFormat = true;
  bool _isToggleEnabled = true;
  var toggleKey;
  late final ProfileBalanceProvider _balanceProvider; // Store provider reference

  @override
  void initState() {
    super.initState();
    _balanceProvider = ref.read(profileBalanceProvider);
    toggleKey = 'qr_code_toggle_state${widget.memoProfileId}';
    _loadToggleState(context);
  }

  Future<void> _loadToggleState(BuildContext ctx) async {
    final prefs = ref.read(sharedPreferencesProvider);
    _isToggleEnabled = widget.tokenOnly || widget.memoOnly ? false : true;
    // _isToggleEnabled = widget.tokenOnly ? false : (widget.cashtokenAddress != null && widget.cashtokenAddress!.isNotEmpty);
    if (widget.memoOnly) _isToggleEnabled = false;
    final bool defaultState = false; //DEFAULT STATE IS MEMO AFTER INSTALL

    // Only use saved state if it's valid for current dialog
    final savedState = prefs.getBool(toggleKey);
    _isCashtokenFormat = widget.tokenOnly ? true : ((savedState != null && _isToggleEnabled) ? savedState : defaultState);

    // Reset to default if saved state is invalid for current address
    if (!widget.tokenOnly && _isCashtokenFormat && !_isToggleEnabled) {
      _isCashtokenFormat = false;
      await _saveToggleState(false);
    }

    // Start QR dialog refresh with the selected mode
    _startQrDialogRefresh(ctx, widget.memoProfileId);

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveToggleState(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(toggleKey, value);
  }

  void _startQrDialogRefresh(BuildContext ctx, String profileId) {
    // final profileNotifier = ref.read(profileDataProvider.notifier);
    _balanceProvider.startQrDialogRefresh(_isCashtokenFormat, profileId);
  }

  String convertToBchFormat(String? legacyAddress) {
    if (legacyAddress == null || legacyAddress.trim().isEmpty) return "";

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
      if (mounted) ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.info, "Nothing to copy.");
      return;
    }
    await FlutterClipboard.copyWithCallback(
      text: text,
      onSuccess: () {
        if (mounted) ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.success, successMessage);
      },
      onError: (error) {
        _logError("Copy to clipboard failed", error);
        if (mounted) ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, 'Copy failed. See logs for details.');
      },
    );
  }

  Future<void> _shareAddress(String address) async {
    try {
      await Share.share(address, subject: 'My Bitcoin Cash Address');
    } catch (e) {
      _logError("Share failed", e);
      if (mounted) ref.read(snackbarServiceProvider).showTranslatedSnackBar(type: SnackbarType.error, 'Share failed. See logs for details.');
    }
  }

  void _toggleFormat(bool isCashtoken, BuildContext ctx, String profileId) async {
    if (!mounted) return;

    setState(() {
      _isCashtokenFormat = isCashtoken;
    });

    // Update QR dialog refresh mode in provider
    // final profileNotifier = ref.read(profileDataProvider.notifier);
    _balanceProvider.setQrDialogMode(isCashtoken, profileId);

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
    MemoModelCreator? creator = ref.watch(getCreatorProvider(widget.memoProfileId)).value;
    String cashtokenAddress = creator?.bchAddressCashtokenAware ?? "";
    String legacyAddress = creator?.id ?? "";

    String cashtokenAddressShorter = shortenAddress(cashtokenAddress);
    String legacyAddressShorter = shortenAddress(legacyAddress);

    final String addressShorter = _isCashtokenFormat ? cashtokenAddressShorter : legacyAddressShorter;
    final String addressToShow = _isCashtokenFormat ? cashtokenAddress : convertToBchFormat(legacyAddress);
    final String qrImageAsset = _isCashtokenFormat ? "cashtoken" : "memo";
    final String balanceText = _getBalanceText(_isCashtokenFormat, creator);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(21, 18, 21, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildHeaderRow(balanceText, textTheme, colorScheme, dialogCtx),
            if (_isToggleEnabled) const SizedBox(height: 6),
            if (_isToggleEnabled) _buildTabSelector(theme, colorScheme, dialogCtx),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: GestureDetector(
                key: ValueKey(addressToShow),
                onTap: () {
                  _copyToClipboard(dialogCtx, addressToShow, "Address copied!");
                },
                onLongPress: () {
                  closeDialog(dialogCtx);
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
            const SizedBox(height: 12),
            buildAddressText(addressToShow, addressShorter, textTheme, colorScheme),
            const SizedBox(height: 12),
            buildActionButtons(dialogCtx, addressToShow),
          ],
        ),
      ),
    );
  }

  String shortenAddress(String addr) {
    return addr.isNotEmpty && addr.startsWith("bitcoincash:") ? convertToBchFormat(addr).substring(12) : "";
  }

  Container buildActionButtons(BuildContext dialogCtx, String addressToShow) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          IconAction(
            text: "COPY",
            onTap: () => _copyToClipboard(dialogCtx, addressToShow, "Address copied!"),
            type: IAB.success,
            icon: Icons.copy_outlined,
          ),
          SizedBox(width: 1),
          IconAction(text: "SHARE", onTap: () => _shareAddress(addressToShow), type: IAB.alternative, icon: Icons.share_outlined),
        ],
      ),
    );
  }

  SizedBox buildAddressText(String addressToShow, String addressShorter, TextTheme textTheme, ColorScheme colorScheme) {
    return SizedBox(
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
    );
  }

  Row buildHeaderRow(String balanceText, TextTheme textTheme, ColorScheme colorScheme, BuildContext dialogCtx) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            balanceText,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, color: colorScheme.onSurface),
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface, size: 33),
          onPressed: () => closeDialog(dialogCtx),
          tooltip: 'Close',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
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
                  _toggleFormat(false, dialogCtx, widget.memoProfileId);
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
                  _toggleFormat(true, dialogCtx, widget.memoProfileId);
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

  @override
  void dispose() {
    _balanceProvider.stopQrDialogRefresh();
    super.dispose();
  }

  void closeDialog(BuildContext ctx) {
    _balanceProvider.stopQrDialogRefresh();
    Navigator.of(ctx).pop();
  }
}

// --- Simplified BCH QR Code Dialog Helper ---
void showQrCodeDialog({
  required BuildContext ctx,
  MemoModelUser? user,
  MemoModelCreator? creator,
  bool memoOnly = false,
  bool tokenOnly = false,
  bool withDelay = false,
}) {
  if (withDelay) {
    Future.delayed(Duration(milliseconds: 3333), () {
      show(creator, ctx, memoOnly, tokenOnly, user);
    });
  } else {
    show(creator, ctx, memoOnly, tokenOnly, user);
  }
}

void show(MemoModelCreator? creator, BuildContext ctx, bool memoOnly, bool tokenOnly, MemoModelUser? user) {
  if (creator != null) {
    showDialog(
      fullscreenDialog: true,
      context: ctx,
      builder: (ctx) {
        return QrCodeDialog(memoProfileId: creator.id, memoOnly: !creator.hasRegisteredAsUserFixed ? true : memoOnly, tokenOnly: tokenOnly);
      },
    );
  } else if (user != null) {
    showDialog(
      fullscreenDialog: true,
      context: ctx,
      builder: (ctx) {
        return QrCodeDialog(memoProfileId: user.id, memoOnly: memoOnly, tokenOnly: tokenOnly);
      },
    );
  } else {
    throw Exception("You must pass a user or a creator to showQrCodeDialog");
  }
}

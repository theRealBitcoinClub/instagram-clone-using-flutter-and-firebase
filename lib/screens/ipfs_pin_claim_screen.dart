import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:path/path.dart' show basename;

import '../ipfs/ipfs_pin_claim_service.dart';
import '../memo/base/memo_accountant.dart';
import '../provider/electrum_provider.dart';
import '../provider/user_provider.dart';

class IpfsPinClaimScreen extends ConsumerStatefulWidget {
  const IpfsPinClaimScreen({Key? key}) : super(key: key);

  static Future<Map<String, dynamic>?> show(BuildContext context) async {
    return await Navigator.push(context, MaterialPageRoute(builder: (context) => const IpfsPinClaimScreen(), fullscreenDialog: true));
  }

  @override
  ConsumerState<IpfsPinClaimScreen> createState() => _PinClaimScreenState();
}

class _PinClaimScreenState extends ConsumerState<IpfsPinClaimScreen> {
  File? _selectedFile;
  double? _pinClaimPrice;
  String? _cid;
  String? _pobTxid;
  String? _claimTxid;
  String? _error;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isPinning = false;
  bool _isCheckingBalance = false;

  // Timer variables
  Timer? _countdownTimer;
  int _countdownSeconds = 69;
  bool _showOverlay = false;

  final String _serverUrl = 'https://file-stage.fullstack.cash';

  @override
  void initState() {
    super.initState();
    print('IpfsPinClaimScreen: Initialized');
  }

  @override
  void dispose() {
    // Cancel and dispose the timer when the widget is disposed
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _showOverlay = true;
      _countdownSeconds = 99;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdownSeconds > 0) {
          _countdownSeconds--;
        } else {
          // Time's up - hide the counter show some last resort snackbars to entertain the user;
          _stopCountdown();
          if (mounted) {
            showSnackBar("ARE YOU UPLOADING A LARGE FILE OR NOT HAZ VERY FAST CONNECTION?!", context, type: SnackbarType.info);
            showSnackBar("WAGMI! WE ALL GONNA MAKE IT!", context, type: SnackbarType.success, wait: true);
            showSnackBar(
              "SOME MORE PATIENCE REQUIRED! YOU MADE IT THIS FAR, STAND STRONG, TAKE A DEEP BREATH!",
              context,
              type: SnackbarType.error,
              wait: true,
            );
            showSnackBar("PLEASE HOLD THE LINE!", context, type: SnackbarType.info, wait: true);
            showSnackBar(
              "YOU STILL HERE! THATS A VERY GOOD SIGN! SATOSHI NAKAMOTO LOVES YOU!",
              context,
              type: SnackbarType.success,
              wait: true,
            );
            showSnackBar("PLEASE REACH OUT TO MAHAKKA SUPPORT IN TELEGRAM @MAHAKKA_COM", context, type: SnackbarType.error, wait: true);
            showSnackBar("PLEASE TAKE A SCREENSHOT SO YOU CAN PROVIDE IT @MAHAKKA_COM", context, type: SnackbarType.info, wait: true);
            showSnackBar("SUPPORT WILL ASK FOR THAT SCREENSHOT TO MAKE A REFUND @MAHAKKA_COM", context, type: SnackbarType.success, wait: true);
            showSnackBar("PLEASE REACH OUT TO MAHAKKA SUPPORT IN TELEGRAM @MAHAKKA_COM", context, type: SnackbarType.error, wait: true);
            showSnackBar("PLEASE TAKE A SCREENSHOT SO YOU CAN PROVIDE IT @MAHAKKA_COM", context, type: SnackbarType.info, wait: true);
            showSnackBar("SUPPORT WILL ASK FOR THAT SCREENSHOT TO MAKE A REFUND @MAHAKKA_COM", context, type: SnackbarType.success, wait: true);
          }
        }
      });
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    if (mounted) {
      setState(() {
        _showOverlay = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _pinClaimPrice = null;
          _resetState();
        });

        _calculatePrice();
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: ${e.toString()}';
      });
    }
  }

  Future<void> _calculatePrice() async {
    if (_selectedFile == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bitcoinBase = await ref.read(electrumServiceProvider.future);
      final ipfsService = IpfsPinClaimService(bitcoinBase: bitcoinBase, serverUrl: _serverUrl);

      final price = await ipfsService.fetchBCHWritePrice(_selectedFile!);
      setState(() {
        _pinClaimPrice = price;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error calculating price: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_serverUrl/ipfs/upload'));

      request.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path, filename: basename(_selectedFile!.path)));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);

      if (response.statusCode == 200) {
        setState(() {
          _cid = jsonResponse['cid'];
          _isUploading = false;
        });
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']}');
      }
    } catch (e) {
      setState(() {
        _error = 'Error uploading file: ${e.toString()}';
        _isUploading = false;
      });
    }
  }

  Future<void> _checkBalanceAndPin() async {
    if (_selectedFile == null || _cid == null) return;

    setState(() {
      _isCheckingBalance = true;
      _error = null;
    });

    try {
      final accountant = ref.read(memoAccountantProvider);
      final hasSufficientBalance = await accountant.checkBalanceForIpfsOperation(_pinClaimPrice!);

      if (!hasSufficientBalance) {
        setState(() {
          _error = 'Insufficient balance for IPFS operation. Please add more BCH to your wallet.';
          _isCheckingBalance = false;
          showQrCodeDialog(context: context, user: ref.read(userProvider), memoOnly: true);
        });
        return;
      }

      await _pinFile();
    } catch (e) {
      setState(() {
        _error = 'Error checking balance: ${e.toString()}';
        _isCheckingBalance = false;
      });
    }
  }

  Future<void> _pinFile() async {
    if (_selectedFile == null || _cid == null) return;

    setState(() {
      _isPinning = true;
      _error = null;
    });

    // Start the countdown overlay
    _startCountdown();

    try {
      final accountant = ref.read(memoAccountantProvider);
      final result = await accountant.pinIpfsFile(_selectedFile!, _cid!);

      if (result == MemoAccountantResponse.yes) {
        // Stop the countdown and pop the screen immediately
        _stopCountdown();
        if (mounted) Navigator.pop(context);
      } else {
        _stopCountdown();
        setState(() {
          _error = 'Error pinning file!!!!';
          resetLoadingStates();
        });
        throw Exception(result.message);
      }
    } catch (e) {
      _stopCountdown();
      _error = 'Error pinning file: ${e.toString()}';
      resetLoadingStates();
    }
  }

  void resetLoadingStates() {
    setState(() {
      _isUploading = false;
      _isPinning = false;
      _isLoading = false;
    });
  }

  void _resetState() {
    setState(() {
      _cid = null;
      _pobTxid = null;
      _claimTxid = null;
      _error = null;
    });
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _pinClaimPrice = null;
      _resetState();
    });
  }

  // Override the back button behavior when overlay is shown
  Future<bool> _onWillPop() async {
    if (_showOverlay) {
      // Prevent back navigation when overlay is shown
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload and Pin Content'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Use this page to upload an image to the IPFS network. '
                    'Your wallet must have sufficient Memo balance to pay for the upload. ',
                    style: textTheme.bodyMedium?.copyWith(height: 1.5, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 16),

                  // File selection area
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(20),
                    height: 200,
                    child: Center(
                      child: _selectedFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: _pickFile,
                                  style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                                  child: const Text('SELECT IMAGE'),
                                ),
                                const SizedBox(height: 8),
                                Icon(Icons.cloud_upload, size: 48, color: colorScheme.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text(
                                  'Select an image from your phone to be uploaded to the Inter Planetary File System - IPFS',
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_selectedFile!.path.split('/').last, style: textTheme.titleSmall, textAlign: TextAlign.center),
                                const SizedBox(height: 24),
                                if (_pinClaimPrice != null)
                                  Text(
                                    'Upload cost: ${(_pinClaimPrice! * 100000000).toStringAsFixed(0)} sats',
                                    style: textTheme.titleLarge?.copyWith(color: colorScheme.primary, letterSpacing: 1.5),
                                  ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: _removeFile,
                                  style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                                  child: const Text('CHANGE IMAGE'),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Loading indicator for price calculation
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: LinearProgressIndicator(color: colorScheme.primary),
                      ),
                    ),

                  // Error message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          border: Border.all(color: colorScheme.error),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_error!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer, letterSpacing: 0.5)),
                      ),
                    ),

                  const SizedBox(height: 4),

                  // Success messages
                  if (_cid != null) _buildSuccessCard('Upload Success', 'CID: $_cid', theme, colorScheme, textTheme),
                  if (_claimTxid != null) _buildSuccessCard('Pin Claim Success', 'Claim Txid: $_claimTxid', theme, colorScheme, textTheme),

                  const SizedBox(height: 4),

                  // Action buttons
                  Center(
                    child: Column(
                      children: [
                        if (_selectedFile != null && _cid == null && _claimTxid == null)
                          ElevatedButton(
                            onPressed: _isUploading ? null : _uploadFile,
                            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                            child: _isUploading ? const LinearProgressIndicator() : const Text('UPLOAD IMAGE'),
                          ),
                        if (_cid != null && _claimTxid == null)
                          ElevatedButton(
                            onPressed: (_isPinning || _isCheckingBalance) ? null : _checkBalanceAndPin,
                            style: ElevatedButton.styleFrom(
                              fixedSize: const Size.fromHeight(52),
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                            ),
                            child: (_isPinning || _isCheckingBalance) ? const LinearProgressIndicator() : const Text('PIN IMAGE'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Fullscreen overlay
            if (_showOverlay)
              WillPopScope(
                onWillPop: () async => false, // Disable back button
                child: Container(
                  color: Colors.black.withOpacity(0.5), // 50% alpha black
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colorScheme.primary, // Theme color for circle
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _countdownSeconds.toString(),
                          style: textTheme.headlineLarge?.copyWith(
                            color: colorScheme.onPrimary, // onPrimary theme color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(String title, String content, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 4),
          Text(content, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

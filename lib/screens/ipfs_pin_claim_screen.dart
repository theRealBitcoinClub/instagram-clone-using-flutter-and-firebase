import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/external_browser_launcher.dart';
import 'package:mahakka/memo/base/memo_publisher.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
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
  bool hasSufficientBalance = true;

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
    // if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _showOverlay = true;
      _countdownSeconds = 69;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdownSeconds > 0) {
          if (_countdownSeconds == 60) showSnackBar("http://psfoundation.info made this feature possible!", context, type: SnackbarType.info);
          if (_countdownSeconds == 49) showSnackBar("BCH fork block is number #478558", context, type: SnackbarType.info);
          if (_countdownSeconds == 38) showSnackBar("BCH independence day is August 1st 2017", context, type: SnackbarType.info);
          if (_countdownSeconds == 27) showSnackBar("Satoshi Nakamoto is the real Bitcoin Jesus", context, type: SnackbarType.info);
          if (_countdownSeconds == 16) showSnackBar("BCH birthday is 3rd January 2009", context, type: SnackbarType.info);
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
      resetLoadingStates();
      setState(() {
        _selectedFile = null;
        _pinClaimPrice = null;
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
      resetLoadingStates();
      setState(() {
        _selectedFile = null;
        _pinClaimPrice = null;
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
        if (!_isPinning || !_isCheckingBalance) {
          showSnackBar("Upload successfull, now its pinning to the IPFS!", context, type: SnackbarType.success);
          _checkBalanceAndPin();
        }
        ;
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']}');
      }
    } catch (e) {
      resetLoadingStates();
      setState(() {
        _error = 'Error uploading file: ${e.toString()}';
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
      hasSufficientBalance = await accountant.checkBalanceForIpfsOperation(_pinClaimPrice!);

      if (!hasSufficientBalance) {
        setState(() {
          _error = 'Insufficient balance for IPFS operation. Please add more BCH to your wallet.';
          _isCheckingBalance = false;
          showQrCodeDialog(context: context, user: ref.read(userProvider), memoOnly: true);
          showSnackBar(_error!, context, type: SnackbarType.error);
        });
        return;
      }

      await _pinFile();
    } catch (e) {
      resetLoadingStates();
      setState(() {
        _error = 'Error checking balance: ${e.toString()}';
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
        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
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
      _isCheckingBalance = false;
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
      resetLoadingStates();
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
          toolbarHeight: AppBarBurnMahakkaTheme.height,
          title: Text('Upload and Pin images to the IPFS', style: textTheme.bodyMedium!.copyWith(color: colorScheme.onPrimary.withAlpha(222))),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          actions: [AppBarBurnMahakkaTheme.buildThemeIcon(ref.read(themeStateProvider), ref, context)],
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
                    'Your wallet must have sufficient Memo balance to pay for the upload. Select an image to check the cost!',
                    style: textTheme.bodyMedium?.copyWith(height: 1.5, letterSpacing: 1),
                  ),
                  const SizedBox(height: 16),

                  // File selection area
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
                      borderRadius: BorderRadius.circular(8),
                      color: colorScheme.surface,
                    ),
                    padding: const EdgeInsets.all(20),
                    height: 200,
                    child: Center(
                      child: _selectedFile == null
                          ? AnimGrowFade(
                              show: _selectedFile == null,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: _pickFile,
                                    style: ElevatedButton.styleFrom(
                                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: colorScheme.onPrimary,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 12),
                                      child: Text(
                                        'SELECT IMAGE',
                                        style: textTheme.titleLarge?.copyWith(height: 1.5, letterSpacing: 1.2, color: colorScheme.onPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Icon(Icons.cloud_upload_outlined, size: 48, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Select an image from your phone to be uploaded to the Inter Planetary File System - IPFS',
                                    textAlign: TextAlign.center,
                                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            )
                          : AnimGrowFade(
                              show: _selectedFile != null,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _selectedFile!.path.split('/').last,
                                    style: textTheme.bodySmall!.copyWith(letterSpacing: 0.5, color: colorScheme.secondary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  if (_pinClaimPrice != null)
                                    AnimGrowFade(
                                      show: _pinClaimPrice != null,
                                      child: GestureDetector(
                                        onTap: () => ExternalBrowserLauncher().launchUrlWithConfirmation(
                                          context,
                                          "https://psffpp.com/docs/overview/#payment",
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center, // Center the content
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Upload price: ${((_pinClaimPrice! * 100000000) + MemoPublisher.minerFeeDefault.toInt()).toStringAsFixed(0)} sats',
                                                style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, letterSpacing: 1.5),
                                              ),
                                              SizedBox(width: 9),
                                              Icon(Icons.info_outline_rounded, size: 22, color: colorScheme.onSurface),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _removeFile,
                                    style: ButtonStyle(
                                      foregroundColor: MaterialStateProperty.all(colorScheme.error.withAlpha(198)),
                                      side: MaterialStateProperty.all(BorderSide(color: colorScheme.error.withAlpha(198))),
                                    ),
                                    child: const Text('CHANGE IMAGE'),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Loading indicator for price calculation
                  if (_isLoading || _isUploading || _isPinning || _isCheckingBalance)
                    Center(
                      child: AnimGrowFade(
                        show: _isLoading || _isUploading || _isPinning || _isCheckingBalance,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          child: LinearProgressIndicator(color: colorScheme.primary),
                        ),
                      ),
                    ),

                  // Error message
                  if (_error != null)
                    AnimGrowFade(
                      show: _error != null,
                      child: Padding(
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
                    ),

                  const SizedBox(height: 4),

                  // Success messages
                  if (_cid != null) AnimGrowFade(show: _cid != null, child: _buildSuccessCard('', 'CID: $_cid', theme, colorScheme, textTheme)),
                  if (_claimTxid != null)
                    AnimGrowFade(
                      show: _claimTxid != null,
                      child: _buildSuccessCard('Pin Claim Success', 'Claim Txid: $_claimTxid', theme, colorScheme, textTheme),
                    ),

                  const SizedBox(height: 4),

                  // Action buttons
                  Center(
                    child: Column(
                      children: [
                        if (_selectedFile != null && _cid == null && _claimTxid == null && !_isLoading && !_isUploading)
                          AnimGrowFade(
                            show: _selectedFile != null && _cid == null && _claimTxid == null && !_isLoading && !_isUploading,
                            child: Row(
                              children: [
                                IconAction(
                                  type: IAB.success,
                                  text: "UPLOAD IMAGE",
                                  icon: Icons.upload,
                                  size: 20,
                                  onTap: () {
                                    if (!_isUploading) _uploadFile();
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_cid != null && _claimTxid == null && !_isLoading && !hasSufficientBalance)
                          AnimGrowFade(
                            show: _cid != null && _claimTxid == null && !_isLoading && !hasSufficientBalance,
                            child: Row(
                              children: [
                                IconAction(
                                  type: IAB.success,
                                  text: "PIN IMAGE ON IPFS",
                                  icon: Icons.upload,
                                  size: 20,
                                  onTap: () {
                                    if (!_isPinning && !_isCheckingBalance) _checkBalanceAndPin();
                                  },
                                ),
                              ],
                            ),
                            //
                            // IconAction(text: "PIN IMAGE", onTap: onTap, type: type, icon: icon)
                            //
                            //                         ElevatedButton(
                            //                           onPressed: (_isPinning || _isCheckingBalance) ? null : _checkBalanceAndPin,
                            //                           style: ElevatedButton.styleFrom(
                            //                             fixedSize: const Size.fromHeight(52),
                            //                             backgroundColor: colorScheme.primary,
                            //                             foregroundColor: colorScheme.onPrimary,
                            //                           ),
                            //                           child: (_isPinning || _isCheckingBalance) ? const LinearProgressIndicator() : const Text('PIN IMAGE'),
                            //                         ),
                          ),
                      ],
                    ),
                  ),
                  if (_selectedFile != null)
                    AnimGrowFade(
                      show: _selectedFile != null,
                      child: Column(children: [SizedBox(height: 16), Image.file(_selectedFile!, width: 500)]),
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
                            fontSize: 50,
                            color: colorScheme.onPrimary, // onPrimary theme color
                            fontWeight: FontWeight.w400,
                            letterSpacing: 1,
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
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        border: Border.all(color: colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title.isNotEmpty
              ? Text(
                  title,
                  style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                )
              : SizedBox.shrink(),
          const SizedBox(height: 4),
          Text(content, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

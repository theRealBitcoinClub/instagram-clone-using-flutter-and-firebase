import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/app_bar_burn_mahakka_theme.dart';
import 'package:mahakka/app_utils.dart';
import 'package:mahakka/external_browser_launcher.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/utils/snackbar.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';
import 'package:path/path.dart' show basename;

import '../ipfs/ipfs_pin_claim_service.dart';
import '../memo/base/memo_accountant.dart';
import '../memo/model/memo_model_creator.dart';
import '../provider/electrum_provider.dart';
import '../provider/translation_service.dart';
import '../provider/user_provider.dart';
import '../repositories/creator_repository.dart';

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
  int _countdownSeconds = 78;
  bool _showOverlay = false;

  final String _serverUrl = 'https://file-stage.fullstack.cash';

  // DRY text constants
  static const String _insufficientBalanceText = 'You need to add more funds to your wallet.';
  static const String _uploadSuccessText = 'Upload successful, now its pinning to the IPFS!';
  static const String _selectImageText = 'SELECT IMAGE';
  static const String _changeImageText = 'CHANGE IMAGE';
  static const String _uploadPriceText = 'Price';
  static const String _screenTitle = 'Upload and Pin images to the IPFS';
  static const String _screenDescription =
      'Use this page to upload an image to the IPFS network. '
      'Your wallet must have sufficient Memo balance to pay for the upload. Select an image to check the cost!';
  static const String _fileSelectionDescription = 'Select an image from your phone to be uploaded to the Inter Planetary File System - IPFS';
  static const String _pinClaimSuccessText = 'Pin Claim Success';

  @override
  void initState() {
    super.initState();
    context.afterBuildAsync(refreshUI: false, () async {
      (await ipfsPinClaimServiceFactory()).executeFakeApiRequestForWakeUp();
    });
    print('IpfsPinClaimScreen: Initialized');
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _showOverlay = true;
      _countdownSeconds = 78;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_countdownSeconds > 0) {
          if (_countdownSeconds == 60) {
            ref
                .read(snackbarServiceProvider)
                .showPartiallyTranslatedSnackBar(
                  translateable: 'made this feature possible!',
                  fixedBefore: 'http://psfoundation.info ',
                  type: SnackbarType.info,
                );
          }
          if (_countdownSeconds == 49) {
            ref.read(snackbarServiceProvider).showTranslatedSnackBar("BCH fork block is number #478558", type: SnackbarType.info);
          }
          if (_countdownSeconds == 38) {
            ref.read(snackbarServiceProvider).showTranslatedSnackBar("BCH independence day is August 1st 2017", type: SnackbarType.info);
          }
          if (_countdownSeconds == 27) {
            ref.read(snackbarServiceProvider).showTranslatedSnackBar("Satoshi Nakamoto is the real Bitcoin Jesus", type: SnackbarType.info);
          }
          if (_countdownSeconds == 16) {
            ref.read(snackbarServiceProvider).showTranslatedSnackBar("BCH birthday is 3rd January 2009", type: SnackbarType.info);
          }
          _countdownSeconds--;
        } else {
          _stopCountdown();
          if (mounted) {
            _showTimeoutSnackbars();
          }
        }
      });
    });
  }

  // DRY method for timeout snackbars
  void _showTimeoutSnackbars() {
    final snackbars = [
      {"text": "ARE YOU UPLOADING A LARGE FILE OR NOT HAZ VERY FAST CONNECTION?!", "type": SnackbarType.info, "wait": false},
      {"text": "WAGMI! WE ALL GONNA MAKE IT!", "type": SnackbarType.success, "wait": true},
      {
        "text": "SOME MORE PATIENCE REQUIRED! YOU MADE IT THIS FAR, STAND STRONG, TAKE A DEEP BREATH!",
        "type": SnackbarType.error,
        "wait": true,
      },
      {"text": "PLEASE HOLD THE LINE!", "type": SnackbarType.info, "wait": true},
      {"text": "YOU STILL HERE! THATS A VERY GOOD SIGN! SATOSHI NAKAMOTO LOVES YOU!", "type": SnackbarType.success, "wait": true},
      {"text": "PLEASE REACH OUT TO MAHAKKA SUPPORT IN TELEGRAM @MAHAKKA_COM", "type": SnackbarType.error, "wait": true},
      {"text": "PLEASE TAKE A SCREENSHOT SO YOU CAN PROVIDE IT @MAHAKKA_COM", "type": SnackbarType.info, "wait": true},
      {"text": "SUPPORT WILL ASK FOR THAT SCREENSHOT TO MAKE A REFUND @MAHAKKA_COM", "type": SnackbarType.success, "wait": true},
      {"text": "PLEASE REACH OUT TO MAHAKKA SUPPORT IN TELEGRAM @MAHAKKA_COM", "type": SnackbarType.error, "wait": true},
      {"text": "PLEASE TAKE A SCREENSHOT SO YOU CAN PROVIDE IT @MAHAKKA_COM", "type": SnackbarType.info, "wait": true},
      {"text": "SUPPORT WILL ASK FOR THAT SCREENSHOT TO MAKE A REFUND @MAHAKKA_COM", "type": SnackbarType.success, "wait": true},
    ];

    for (final snackbar in snackbars) {
      ref
          .read(snackbarServiceProvider)
          .showTranslatedSnackBar(snackbar["text"] as String, type: snackbar["type"] as SnackbarType, wait: snackbar["wait"] as bool);
    }
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
        _error = _createPartialErrorMessage('Error picking file', e);
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
      final ipfsService = await ipfsPinClaimServiceFactory();
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
        _error = _createPartialErrorMessage('Error calculating price', e);
        _isLoading = false;
      });
    }
  }

  Future<IpfsPinClaimService> ipfsPinClaimServiceFactory() async =>
      IpfsPinClaimService(bitcoinBase: await ref.read(electrumServiceProvider.future), serverUrl: _serverUrl);

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
          ref.read(snackbarServiceProvider).showTranslatedSnackBar(_uploadSuccessText, type: SnackbarType.success);
          _checkBalanceAndPin();
        }
      } else {
        throw Exception('Upload failed: ${jsonResponse['error']}');
      }
    } catch (e) {
      resetLoadingStates();
      setState(() {
        _error = _createPartialErrorMessage('Error uploading file', e);
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
          _error = _insufficientBalanceText;
          _isCheckingBalance = false;
        });
        ref.read(snackbarServiceProvider).showTranslatedSnackBar(_insufficientBalanceText, type: SnackbarType.error);
        showQrCodeDialog(ctx: context, user: ref.read(userProvider), memoOnly: true, withDelay: true);
        return;
      }

      await _pinFile();
    } catch (e) {
      resetLoadingStates();
      setState(() {
        _error = _createPartialErrorMessage('Error checking balance', e);
      });
    }
  }

  Future<void> _pinFile() async {
    if (_selectedFile == null || _cid == null) return;

    setState(() {
      _isPinning = true;
      _error = null;
    });

    _startCountdown();

    try {
      final accountant = ref.read(memoAccountantProvider);
      final result = await accountant.pinIpfsFile(_selectedFile!, _cid!);

      if (result == MemoAccountantResponse.yes) {
        _stopCountdown();
        if (mounted) ScaffoldMessenger.of(context).clearSnackBars();
        if (mounted) Navigator.pop(context);
      } else {
        _stopCountdown();
        setState(() {
          _error = _createPartialErrorMessage('Error pinning file', Exception(result.message));
          resetLoadingStates();
        });
      }
    } catch (e) {
      _stopCountdown();
      setState(() {
        _error = _createPartialErrorMessage('Error pinning file', e);
        resetLoadingStates();
      });
    }
  }

  // DRY method for partial error message translation
  String _createPartialErrorMessage(String userFriendlyPrefix, dynamic exception) {
    return '$userFriendlyPrefix: ${exception.toString()}';
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

  Future<bool> _onWillPop() async {
    return !_showOverlay;
  }

  int lastBalance = -2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    MemoModelCreator? creator = ref.watch(getCreatorProvider(ref.read(userProvider)!.id)).value;
    var currentBalance = creator != null ? creator.balanceMemo : -1;
    if (currentBalance > lastBalance && currentBalance > 0)
      setState(() {
        _error = null;
      });
    lastBalance = currentBalance;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: AppBarBurnMahakkaTheme.height,
          title: Consumer(
            builder: (context, ref, child) {
              final translatedTitle = ref.watch(autoTranslationTextProvider(_screenTitle));
              return Text(
                translatedTitle.value ?? _screenTitle,
                style: textTheme.bodyMedium!.copyWith(color: colorScheme.onPrimary.withAlpha(222)),
              );
            },
          ),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          actions: [AppBarBurnMahakkaTheme.buildThemeIcon(ref, context, theme)],
        ),
        body: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final translatedDescription = ref.watch(autoTranslationTextProvider(_screenDescription));
                        return Text(
                          translatedDescription.value ?? _screenDescription,
                          style: textTheme.bodyMedium?.copyWith(height: 1.5, letterSpacing: 1),
                        );
                      },
                    ),
                    const SizedBox(height: 9),
                    buildFileSelectionContainer(colorScheme, textTheme, context),
                    const SizedBox(height: 6),
                    if (_isLoading || _isUploading || _isPinning || _isCheckingBalance) buildLoadingProgressBar(colorScheme),
                    if (_error != null) buildErrorCard(colorScheme, textTheme),
                    const SizedBox(height: 3),
                    if (_cid != null)
                      AnimGrowFade(show: _cid != null, child: _buildSuccessCard('', 'CID: $_cid', theme, colorScheme, textTheme)),
                    if (_claimTxid != null)
                      AnimGrowFade(
                        show: _claimTxid != null,
                        child: _buildSuccessCard(_pinClaimSuccessText, 'Claim Txid: $_claimTxid', theme, colorScheme, textTheme),
                      ),
                    const SizedBox(height: 3),
                    Center(
                      child: Column(
                        children: [
                          if (_selectedFile != null && _cid == null && _claimTxid == null && !_isLoading && !_isUploading) buildButtonUpload(),
                          if (_cid != null && _claimTxid == null && !_isLoading && !hasSufficientBalance) buildButtonPin(),
                        ],
                      ),
                    ),
                    if (_selectedFile != null)
                      AnimGrowFade(
                        show: _selectedFile != null,
                        child: Column(
                          children: [
                            SizedBox(height: 12),
                            Image.file(_selectedFile!, width: 500, fit: BoxFit.contain),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (_showOverlay) buildOverlayLoading(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Container buildFileSelectionContainer(ColorScheme colorScheme, TextTheme textTheme, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withOpacity(0.3), width: 1),
        borderRadius: BorderRadius.circular(9),
        color: colorScheme.surface,
      ),
      padding: const EdgeInsets.all(15),
      height: 180,
      child: Center(
        child: _selectedFile == null
            ? buildFileSelectionInit(colorScheme, textTheme)
            : buildFileSelectionPriceCalculationCard(textTheme, colorScheme, context),
      ),
    );
  }

  AnimGrowFade buildFileSelectionInit(ColorScheme colorScheme, TextTheme textTheme) {
    return AnimGrowFade(
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
            child: Consumer(
              builder: (context, ref, child) {
                final translatedButton = ref.watch(autoTranslationTextProvider(_selectImageText));
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                  child: Text(
                    // textAlign: TextAlign.justify,
                    translatedButton.value ?? _selectImageText,
                    style: textTheme.titleLarge?.copyWith(height: 1.2, letterSpacing: 1.2, color: colorScheme.onPrimary),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Icon(Icons.cloud_upload_outlined, size: 42, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 3),
          Consumer(
            builder: (context, ref, child) {
              final translatedDescription = ref.watch(autoTranslationTextProvider(_fileSelectionDescription));
              return Text(
                translatedDescription.value ?? _fileSelectionDescription,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.5),
              );
            },
          ),
        ],
      ),
    );
  }

  AnimGrowFade buildFileSelectionPriceCalculationCard(TextTheme textTheme, ColorScheme colorScheme, BuildContext context) {
    return AnimGrowFade(
      show: _selectedFile != null,
      child: Container(
        width: double.infinity,
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
                  onTap: () => ExternalBrowserLauncher().launchUrlWithConfirmation(context, "https://psffpp.com/docs/overview/#payment"),
                  child: Container(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final translatedPrice = ref.watch(autoTranslationTextProvider(_uploadPriceText)).value ?? _uploadPriceText;
                            return Text(
                              '${translatedPrice.trim()} ~${((_pinClaimPrice! * 100000000)).toStringAsFixed(0)} sats',
                              style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface, letterSpacing: 1.5),
                            );
                          },
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
                foregroundColor: MaterialStateProperty.all(colorScheme.onSurface.withAlpha(198)),
                side: MaterialStateProperty.all(BorderSide(color: colorScheme.onSurface.withAlpha(198))),
              ),
              child: Consumer(
                builder: (context, ref, child) {
                  final translatedChange = ref.watch(autoTranslationTextProvider(_changeImageText));
                  return Text(translatedChange.value ?? _changeImageText);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Center buildLoadingProgressBar(ColorScheme colorScheme) {
    return Center(
      child: AnimGrowFade(
        show: _isLoading || _isUploading || _isPinning || _isCheckingBalance,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: LinearProgressIndicator(color: colorScheme.primary),
        ),
      ),
    );
  }

  AnimGrowFade buildErrorCard(ColorScheme colorScheme, TextTheme textTheme) {
    return AnimGrowFade(
      show: _error != null,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
          child: Consumer(
            builder: (context, ref, child) {
              if (_error == null) return SizedBox.shrink();

              // Split error message for partial translation
              final parts = _error!.split(': ');
              if (parts.length > 1) {
                // Translate only the user-friendly part, keep exception as-is
                final translatedPrefix = ref.watch(autoTranslationTextProvider(parts[0]));
                return Text(
                  '${translatedPrefix.value ?? parts[0]}: ${parts.sublist(1).join(': ')}',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer, letterSpacing: 0.5),
                );
              } else {
                // Full translation for non-exception errors
                final translatedError = ref.watch(autoTranslationTextProvider(_error!));
                return Text(
                  translatedError.value ?? _error!,
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer, letterSpacing: 0.5),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  AnimGrowFade buildButtonPin() {
    return AnimGrowFade(
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
    );
  }

  AnimGrowFade buildButtonUpload() {
    return AnimGrowFade(
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
    );
  }

  WillPopScope buildOverlayLoading(ColorScheme colorScheme, TextTheme textTheme) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
            child: Center(
              child: Text(
                _countdownSeconds.toString(),
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 50,
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(String title, String content, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      decoration: BoxDecoration(color: Colors.blue[900], borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title.isNotEmpty
              ? Consumer(
                  builder: (context, ref, child) {
                    final translatedTitle = ref.watch(autoTranslationTextProvider(title));
                    return Text(
                      translatedTitle.value ?? title,
                      style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                    );
                  },
                )
              : SizedBox.shrink(),
          const SizedBox(height: 4),
          Text(content, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimaryContainer)),
        ],
      ),
    );
  }
}

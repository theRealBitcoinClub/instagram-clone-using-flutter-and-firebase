import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:path/path.dart';

import '../ipfs/ipfs_pin_claim_service.dart';
import '../provider/electrum_provider.dart';
import '../provider/user_provider.dart';

class IpfsPinClaimScreen extends ConsumerStatefulWidget {
  const IpfsPinClaimScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IpfsPinClaimScreen> createState() => _PinClaimScreenState();
}

class _PinClaimScreenState extends ConsumerState<IpfsPinClaimScreen> {
  File? _selectedFile;
  double? _pinClaimPrice;
  String? _cid;
  String? _pobTxid;
  bool isPopping = false;
  String? _claimTxid;
  String? _error;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isPinning = false;

  IpfsPinClaimService? _pinClaim;
  final String _serverUrl = 'https://file-stage.fullstack.cash';

  @override
  void initState() {
    super.initState();
    // Initialize PinClaimAsync with data from providers
    MemoBitcoinBase? bitcoinBase = ref.read(electrumServiceProvider).value;
    if (bitcoinBase != null) {
      _pinClaim = IpfsPinClaimService(bitcoinBase: bitcoinBase, serverUrl: _serverUrl);
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

        // Calculate price after file selection
        _calculatePrice();
      }
    } catch (e) {
      setState(() {
        _error = 'Error picking file: ${e.toString()}';
      });
    }
  }

  Future<void> _calculatePrice() async {
    if (_selectedFile == null || _pinClaim == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final price = await _pinClaim!.fetchBCHWritePrice(_selectedFile!);
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

  Future<void> _pinFile() async {
    if (_selectedFile == null || _cid == null || _pinClaim == null) return;

    setState(() {
      _isPinning = true;
      _error = null;
    });

    try {
      final result = await _pinClaim!.pinClaimBCH(_selectedFile!, _cid!, ref.watch(userProvider)!.mnemonic);
      setState(() {
        _pobTxid = result['pobTxid'];
        _claimTxid = result['claimTxid'];
        _isPinning = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error pinning file: ${e.toString()}';
        _isPinning = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Auto-close the screen and return the CID after successful pinning
    if (_claimTxid != null && _cid != null && !isPopping) {
      isPopping = true;
      pop(context);
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Check if we have all required data from providers
    // final wallet = ref.watch(electrumServiceProvider).value;
    //
    // if (wallet == null) {
    //   return Scaffold(
    //     appBar: AppBar(title: const Text('Upload and Pin Content')),
    //     body: Center(
    //       child: Text('Wallet not available', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
    //     ),
    //   );
    // }

    if (_claimTxid != null && _cid != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pop({'cid': _cid});
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Upload and Pin Content'), backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use this page to upload an image and pin it to the IPFS network. '
              'Your wallet must have BCH to pay for the pinning of content. ',
              style: textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            // const SizedBox(height: 16),
            // Text('Selected Server: $_serverUrl', style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
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
                          Icon(Icons.cloud_upload, size: 48, color: colorScheme.onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(
                            'Drag and drop your file here\nor',
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _pickFile,
                            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                            child: const Text('Browse Files'),
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
                              style: textTheme.titleLarge?.copyWith(color: colorScheme.primary),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _removeFile,
                            style: OutlinedButton.styleFrom(foregroundColor: colorScheme.error),
                            child: const Text('Remove File'),
                          ),
                        ],
                      ),
              ),
            ),

            // const SizedBox(height: 8),

            // Loading indicator for price calculation
            if (_isLoading)
              Center(
                child: Padding(
                  padding: EdgeInsetsGeometry.only(top: 12),
                  child: LinearProgressIndicator(color: colorScheme.primary),
                ),
              ),

            // Error message
            if (_error != null)
              Padding(
                padding: EdgeInsetsGeometry.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    border: Border.all(color: colorScheme.error),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_error!, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onErrorContainer)),
                ),
              ),

            const SizedBox(height: 12),

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
                      child: _isUploading ? CircularProgressIndicator(color: colorScheme.onPrimary) : const Text('Upload File'),
                    ),
                  if (_cid != null && _claimTxid == null)
                    ElevatedButton(
                      onPressed: _isPinning ? null : _pinFile,
                      style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                      child: _isPinning ? CircularProgressIndicator(color: colorScheme.onPrimary) : const Text('Pin File'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void pop(BuildContext context) async {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (context.mounted) {
        Navigator.of(context).pop({'cid': _cid});
      }
    });
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

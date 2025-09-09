import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

import '../ipfs/pin_claim_async.dart';
import '../memo/base/memo_bitcoin_base.dart';

class PinClaimScreen extends StatefulWidget {
  final MemoBitcoinBase wallet;
  final String serverUrl;
  final String mnemonic;

  const PinClaimScreen({Key? key, required this.wallet, required this.serverUrl, required this.mnemonic}) : super(key: key);

  @override
  _PinClaimScreenState createState() => _PinClaimScreenState();
}

class _PinClaimScreenState extends State<PinClaimScreen> {
  File? _selectedFile;
  double? _pinClaimPrice;
  String? _cid;
  String? _pobTxid;
  String? _claimTxid;
  String? _error;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isPinning = false;

  PinClaimAsync? _pinClaim;

  initState() {
    super.initState();
    _pinClaim = PinClaimAsync(wallet: widget.wallet, server: 'https://file-stage.fullstack.cash');
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
    if (_selectedFile == null) return;

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
      final request = http.MultipartRequest('POST', Uri.parse('${widget.serverUrl}/ipfs/upload'));

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
    if (_selectedFile == null || _cid == null) return;

    setState(() {
      _isPinning = true;
      _error = null;
    });

    try {
      final result = await _pinClaim!.pinClaimBCH(_selectedFile!, _cid!, widget.mnemonic);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Upload and Pin Content'), backgroundColor: Colors.blue, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Use this page to upload a file and pin it to the IPFS network. '
              'Your wallet must have BCH to pay for the pinning of content. '
              'Files must be less than 100MB in size.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text('Selected Server: https://file-stage.fullstack.cash', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 24),

            // File selection area
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(20),
              height: 200,
              child: Center(
                child: _selectedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cloud_upload, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          const Text('Drag and drop your file here\nor', textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          ElevatedButton(onPressed: _pickFile, child: const Text('Browse Files')),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (_pinClaimPrice != null)
                            Text(
                              'Pin claim price: ${_pinClaimPrice!.toStringAsFixed(8)} BCH',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _removeFile,
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Remove File'),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Loading indicator for price calculation
            if (_isLoading) const Center(child: CircularProgressIndicator()),

            // Error message
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 16),

            // Success messages
            if (_cid != null) _buildSuccessCard('Upload Success', 'CID: $_cid'),
            if (_claimTxid != null) _buildSuccessCard('Pin Claim Success', 'Claim Txid: $_claimTxid'),

            const SizedBox(height: 24),

            // Action buttons
            Center(
              child: Column(
                children: [
                  if (_selectedFile != null && _cid == null && _claimTxid == null)
                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadFile,
                      child: _isUploading ? const CircularProgressIndicator() : const Text('Upload File'),
                    ),
                  if (_cid != null && _claimTxid == null)
                    ElevatedButton(
                      onPressed: _isPinning ? null : _pinFile,
                      child: _isPinning ? const CircularProgressIndicator() : const Text('Pin File'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
          const SizedBox(height: 4),
          Text(content, style: const TextStyle(color: Colors.green)),
        ],
      ),
    );
  }
}

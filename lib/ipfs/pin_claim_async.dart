import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../memo/base/memo_bitcoin_base.dart';

class PinClaimAsync {
  final MemoBitcoinBase wallet;
  final String server;

  PinClaimAsync({required this.wallet, required this.server});

  Future<double> fetchBCHWritePrice(File file) async {
    try {
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }

      print('Calculating BCH cost for file');

      final fileSizeInMegabytes = file.lengthSync() / pow(10, 6); // get file size in MB

      final response = await http.post(
        Uri.parse('$server/ipfs/getBchCost'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sizeInMb': fileSizeInMegabytes}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch BCH cost: ${response.statusCode}');
      }

      final bchCost = double.parse(response.body);
      print('Bch Cost $bchCost');
      return bchCost;
    } catch (error) {
      print('Error fetching BCH cost: $error');
      rethrow;
    }
  }

  Future<Map<String, String>> pinClaimBCH(File file, String cid, String mnemonic) async {
    try {
      // await wallet.initialize();

      print('Try to pin file with BCH Payment');
      final fileSizeInMegabytes = file.lengthSync() / pow(10, 6); // get file size in MB

      final response = await http.post(
        Uri.parse('$server/ipfs/getPaymentAddr'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sizeInMb': fileSizeInMegabytes}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get payment address: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);
      final address = responseData['address'];
      final bchCost = responseData['bchCost'];

      // Convert BCH cost to satoshis using the helper method
      final amountSat = _toSatoshi(bchCost);

      // Use the send method with proper outputs format
      final outputs = [
        {'address': address, 'amountSat': amountSat},
      ];

      final txid = await wallet.sendIpfs(outputs, mnemonic);
      print('txid: $txid');

      // Wait for the transaction delay
      await Future.delayed(Duration(seconds: 1));

      // Generate a Pin Claim
      final pinObj = {
        'cid': cid,
        'filename': file.uri.pathSegments.last, // Get filename from path
        'address': address,
      };

      final pinClaimResponse = await http.post(
        Uri.parse('$server/ipfs/createPinClaim'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(pinObj),
      );

      if (pinClaimResponse.statusCode != 200) {
        throw Exception('Failed to create pin claim: ${pinClaimResponse.statusCode}');
      }

      final pinClaimData = json.decode(pinClaimResponse.body);
      final pobTxid = pinClaimData['pobTxid'];
      final claimTxid = pinClaimData['claimTxid'];

      return {'pobTxid': pobTxid, 'claimTxid': claimTxid};
    } catch (error) {
      print('Error pinning file with BCH: $error');
      rethrow;
    }
  }

  // Helper method to convert BCH amount to satoshis
  BigInt _toSatoshi(dynamic bchCost) {
    if (bchCost is String) {
      return BigInt.from((double.parse(bchCost) * 100000000).round());
    } else if (bchCost is num) {
      return BigInt.from((bchCost.toDouble() * 100000000).round());
    } else {
      throw Exception('Invalid BCH cost format: $bchCost');
    }
  }
}

// Add this to your pubspec.yaml dependencies:
// http: ^1.1.0

// Usage example:
// final pinClaim = PinClaimAsync(
//   wallet: yourMemoBitcoinBaseInstance,
//   server: 'https://file-stage.fullstack.cash'
// );
//
// final price = await pinClaim.fetchBCHWritePrice(file);
// final result = await pinClaim.pinClaimBCH(file, cid);

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';

class IpfsPinClaimService {
  final MemoBitcoinBase bitcoinBase;
  final String serverUrl;

  IpfsPinClaimService({required this.bitcoinBase, required this.serverUrl});

  Future<double> fetchBCHWritePrice(File file) async {
    try {
      if (!file.existsSync()) {
        throw Exception('File does not exist');
      }

      print('IpfsPinClaimService: Calculating BCH cost for file');

      var lengthSync = file.lengthSync();
      final fileSizeInMegabytes = lengthSync / pow(10, 6); // get file size in MB
      final fileSizeInMegabytes1024 = lengthSync / (1024 * 1024);
      print("SIZE IN MB $fileSizeInMegabytes");
      print("SIZE IN MB $fileSizeInMegabytes");
      print("SIZE IN MB $fileSizeInMegabytes");
      print("SIZE IN 1024 $fileSizeInMegabytes1024");
      print("SIZE IN 1024 $fileSizeInMegabytes1024");
      print("SIZE IN 1024 $fileSizeInMegabytes1024");

      final fileSizeWithPadding = fileSizeInMegabytes1024 * 1.01;
      print("SIZE IN fileSizeWithPadding $fileSizeWithPadding");
      print("SIZE IN fileSizeWithPadding $fileSizeWithPadding");
      print("SIZE IN fileSizeWithPadding $fileSizeWithPadding");

      final response = await http.post(
        Uri.parse('$serverUrl/ipfs/getBchCost'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'sizeInMb': fileSizeWithPadding}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch BCH cost: ${response.statusCode}');
      }

      final bchCost = double.parse(response.body);
      print('IpfsPinClaimService: BCH cost calculated: $bchCost');
      return bchCost;
    } catch (error) {
      print('IpfsPinClaimService: Error fetching BCH cost: $error');
      rethrow;
    }
  }

  Future<Map<String, String>> pinClaimBCH(File file, String cid, String mnemonic) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        attempt++;
        print('IpfsPinClaimService: Attempt $attempt to pin file with BCH Payment');

        // Check if socket is connected, reconnect if necessary
        if (bitcoinBase.service?.isConnected == false) {
          print('IpfsPinClaimService: Socket disconnected, attempting to reconnect...');
          await _reconnectBitcoinBase();
        }

        final fileSizeInMegabytes = file.lengthSync() / pow(10, 6); // get file size in MB

        final response = await http.post(
          Uri.parse('$serverUrl/ipfs/getPaymentAddr'),
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

        final txid = await bitcoinBase.sendIpfs(outputs, mnemonic);
        print('IpfsPinClaimService: Transaction sent successfully, txid: $txid');

        // Wait for the transaction delay
        await Future.delayed(Duration(seconds: 3));

        // Generate a Pin Claim
        final pinObj = {
          'cid': cid,
          'filename': file.uri.pathSegments.last, // Get filename from path
          'address': address,
        };

        final pinClaimResponse = await http.post(
          Uri.parse('$serverUrl/ipfs/createPinClaim'),
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
        print('IpfsPinClaimService: Error in attempt $attempt: $error');

        if (attempt == maxRetries) {
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(Duration(seconds: 2 * attempt));
      }
    }

    throw Exception('Failed to pin file after $maxRetries attempts');
  }

  Future<void> _reconnectBitcoinBase() async {
    try {
      print('IpfsPinClaimService: Reconnecting to Electrum server...');
      // This would need access to the provider to recreate the connection
      // For now, we'll rely on the auto-reconnect functionality
      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      print('IpfsPinClaimService: Error reconnecting: $e');
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

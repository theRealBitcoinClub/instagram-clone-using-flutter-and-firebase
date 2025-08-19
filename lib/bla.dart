import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:crypto/crypto.dart';

String convertLegacyToCashAddress(String legacyAddress) {
  // Remove prefix (if present)
  if (legacyAddress.startsWith('1')) {
    legacyAddress = legacyAddress.substring(1);
  }

  // Convert to bytes
  final bytes = base58Decode(legacyAddress);

  // Perform SHA256 hash
  final sha256Hash = sha256.convert(bytes).bytes;

  // Perform RIPEMD160 hash
  final ripemd160Hash = RIPEMD160.hash(sha256Hash);

  // Add checksum
  final checksum = sha256.convert(sha256.convert(ripemd160Hash).bytes).bytes.sublist(0, 4);
  final hashWithChecksum = Uint8List.fromList([...ripemd160Hash, ...checksum]);

  // Base32 encoding
  final cashAddress = base32Encode(hashWithChecksum);

  // Prefix
  return 'bitcoincash:${cashAddress}';
}

// Helper functions
Uint8List base58Decode(String base58String) {
  final alphabet = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  final base58Bytes = Uint8List(base58String.length);
  for (var i = 0; i < base58String.length; i++) {
    base58Bytes[i] = alphabet.indexOf(base58String[i]).toUnsigned(8);
  }
  return base58Bytes;
}

String base32Encode(Uint8List bytes) {
  final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final encoded = StringBuffer();
  for (var i = 0; i < bytes.length; i += 5) {
    final chunk = bytes.sublist(i, min(i + 5, bytes.length));
    final word = _base32EncodeChunk(chunk);
    encoded.write(word);
  }
  return encoded.toString();
}

String _base32EncodeChunk(Uint8List chunk) {
  final alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  var result = 0;
  for (var i = 0; i < chunk.length; i++) {
    result = (result << 8) | chunk[i];
  }
  final padding = 5 - chunk.length;
  var word = '';
  for (var i = 0; i < 8; i++) {
    final index = (result >> (27 - i * 5)) & 0x1f;
    word += alphabet[index];
  }
  if (padding > 0) {
    word = word.substring(0, 8 - padding);
  }
  return word;
}

void main() {
  final legacyAddress = '1J1zn7fza1Gq42K4uZ3xTMhzfWJUDEZ8bJ';
  final cashAddress = convertLegacyToCashAddress(legacyAddress);
  print(cashAddress);
}

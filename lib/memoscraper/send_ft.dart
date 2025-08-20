import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:instagram_clone1/memoscraper/socket/electrum_websocket_service.dart';

void main() async {
  final service = await ElectrumWebSocketService.connect(
      "wss://bch.imaginary.cash:50004");

  final provider = ElectrumProvider(service);
  final List<int> senderSeed = Bip39SeedGenerator(Mnemonic.fromString(
      "xxx-xxx-xxx..."))
      .generate();

  final Bip32Slip10Secp256k1 bip32Sender = Bip32Slip10Secp256k1.fromSeed(senderSeed);
  final bip44Sender = bip32Sender.derivePath("m/44'/145'/0'/0/0");

  final ECPrivate privateKeySender = ECPrivate.fromBytes(bip44Sender.privateKey.raw);

  final ECPublic publicKeySender = privateKeySender.getPublic();

  final P2pkhAddress senderP2PKHWT = P2pkhAddress.fromHash160(
      addrHash: publicKeySender.toAddress().addressProgram,
      type: P2pkhAddressType.p2pkhwt);

  final electrumUTXOs = await provider.request(ElectrumRequestScriptHashListUnspent(
    scriptHash: senderP2PKHWT.pubKeyHash(),
    includeTokens: true,
  ));

  if (electrumUTXOs.length == 0) {
    print("Zero UTXOs found");
  } else {
    print("Successfully imported a valid seed phrase with UTXOs");
  }
}

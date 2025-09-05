import 'package:bitcoin_base/bitcoin_base.dart';

class MemoTip {
  static const int dust = 777;
  final String receiverAddress;
  final int amountInSats;
  final BasedUtxoNetwork network;

  MemoTip(this.receiverAddress, this.amountInSats, {this.network = BitcoinNetwork.mainnet});

  BigInt get amountAsBigInt {
    return BigInt.from(amountInSats);
  }

  BitcoinCashAddress get cashtokenReceiverAsBchAddress {
    return BitcoinCashAddress(receiverAddress);
  }

  BitcoinCashAddress get receiverAsBchAddress {
    if (receiverAddress.startsWith("bitcoincash:")) {
      return BitcoinCashAddress(receiverAddress);
    }

    P2pkhAddress legacy = P2pkhAddress.fromAddress(address: receiverAddress, network: network);
    // String addr = legacyToBchAddress(addressProgram: legacy.addressProgram, network: network, type: P2pkhAddressType.p2pkh);
    return BitcoinCashAddress.fromBaseAddress(legacy);
  }
}

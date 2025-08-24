import 'package:bitcoin_base/bitcoin_base.dart';

class MemoTip {
  static const int dust = 777;
  final String receiverAddress;
  final int amountInSats;
  final BasedUtxoNetwork network;

  MemoTip(this.receiverAddress, this.amountInSats, {this.network = BitcoinNetwork.mainnet});
}

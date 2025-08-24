import 'package:bitcoin_base/bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../memobase/memo_bitcoin_base.dart';

class MemoModelUser {
  static MemoModelUser? dummy;
  String mnemonic;
  String _bchAddressCashtokenAware = "";
  String _legacyAddressMemoBch = "";
  String _legacyAddressMemoBchAsCashaddress = "";
  String _legacyAddressMemoSlp = "";
  ECPrivate? _privateKeyBchCashtoken;
  ECPrivate? _privateKeyLegacy;
  ECPrivate? _privateKeyLegacySlp;
  String? _wifBchCashtoken;
  String? _wifLegacy;
  MemoModelCreator? creator;
  String balanceCashtokensDevPath145 = "?";
  String balanceBchDevPath145 = "?";
  String balanceBchDevPath0Memo = "?";

  MemoModelUser({required this.mnemonic, this.creator});

  Future<String> refreshBalanceDevPath0() async {
    MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressLegacy(_pkLegacy);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress);

    if (utxos.isEmpty) {
      balanceBchDevPath0Memo = "0";
      return "noutxos";
    }

    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, _pkLegacy);
    BigInt totalAmountInSatoshisAvailable = utxosWA.sumOfUtxosValue();
    if (totalAmountInSatoshisAvailable == BigInt.zero) {
      balanceBchDevPath0Memo = "0";
      return "nofunds";
    }

    balanceBchDevPath0Memo = totalAmountInSatoshisAvailable.toString();
    return "success";
  }

  Future<String> refreshBalanceDevPath145() async {
    MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressP2PKHWT(_pkBchCashtoken);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress);

    if (utxos.isEmpty) {
      balanceBchDevPath145 = "0";
      return "noutxos";
    }

    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, _pkBchCashtoken);
    BigInt totalAmountInSatoshisAvailable = utxosWA.sumOfUtxosValue();
    if (totalAmountInSatoshisAvailable == BigInt.zero) {
      balanceBchDevPath145 = "0";
      return "nofunds";
    }

    balanceBchDevPath145 = totalAmountInSatoshisAvailable.toString();
    return "success";
  }

  Future<String> refreshBalanceTokens() async {
    MemoBitcoinBase base = await MemoBitcoinBase.create();
    P2pkhAddress p2pkhwt = base.createAddressP2PKHWT(_pkBchCashtoken);
    BitcoinCashAddress cashAddress = BitcoinCashAddress.fromBaseAddress(p2pkhwt);
    List<ElectrumUtxo> utxos = await base.requestElectrumUtxos(cashAddress, includeCashtokens: true);

    if (utxos.isEmpty) {
      balanceCashtokensDevPath145 = "0";
      return "noutxos";
    }

    List<UtxoWithAddress> utxosWA = base.transformUtxosAddAddressDetails(utxos, cashAddress, _pkBchCashtoken);

    BigInt totalAmountOfTokenAvailable = base.calculateTotalAmountOfThatToken(utxosWA, MemoBitcoinBase.tokenId);
    balanceCashtokensDevPath145 = totalAmountOfTokenAvailable.toString();
    return "success";
  }

  String get profileIdMemoBch {
    return legacyAddressMemoBch;
  }

  String get profileIdMemoSlp {
    return legacyAddressMemoSlp;
  }

  String get wifLegacy {
    _wifLegacy = _wifLegacy ?? _pkLegacy.toWif();
    return _wifLegacy!;
  }

  String get wifBchCashtoken {
    _wifBchCashtoken = _wifBchCashtoken ?? _pkBchCashtoken.toWif();
    return _wifBchCashtoken!;
  }

  String get legacyAddressMemoSlp {
    if (_legacyAddressMemoSlp.isEmpty) {
      _legacyAddressMemoSlp = _pkLegacySlp.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    //TODO save it in regards of mnemonic, add mnemonic hash to key
    return _legacyAddressMemoSlp;
  }

  String get legacyAddressMemoBchAsCashaddress {
    if (_legacyAddressMemoBchAsCashaddress.isEmpty) {
      _legacyAddressMemoBchAsCashaddress = _pkLegacy.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddressMemoBchAsCashaddress;
  }

  String get legacyAddressMemoBch {
    if (_legacyAddressMemoBch.isEmpty) {
      _legacyAddressMemoBch = _pkLegacy.getPublic().toAddress().toAddress(BitcoinNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _legacyAddressMemoBch;
  }

  ECPrivate get _pkLegacySlp {
    _privateKeyLegacySlp =
        _privateKeyLegacySlp ?? MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoSlp);
    return _privateKeyLegacySlp!;
  }

  ECPrivate get _pkLegacy {
    _privateKeyLegacy =
        _privateKeyLegacy ?? MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathMemoBch);
    return _privateKeyLegacy!;
  }

  ECPrivate get _pkBchCashtoken {
    _privateKeyBchCashtoken =
        _privateKeyBchCashtoken ??
        MemoBitcoinBase.createBip44PrivateKey(mnemonic, MemoBitcoinBase.derivationPathCashtoken);
    return _privateKeyBchCashtoken!;
  }

  String get bchAddressCashtokenAware {
    if (_bchAddressCashtokenAware.isEmpty) {
      _bchAddressCashtokenAware = _pkBchCashtoken.getPublic().toAddress().toAddress(BitcoinCashNetwork.mainnet);
    }
    //TODO SAVE THIS IN SHARED PREFS AS IT IS INTENSE CALCULATION
    return _bchAddressCashtokenAware;
  }

  static Future<MemoModelUser> createDummy({MemoModelCreator? creator}) async {
    if (dummy == null) {
      String? mne = await SharedPreferencesAsync().getString("mnemonic");
      dummy = MemoModelUser(mnemonic: mne ?? "", creator: creator);
    }
    return dummy!;
  }

  String profileImage() {
    return "https://memo.cash/img/profilepics/${legacyAddressMemoBch}-128x128.jpg";
  }
}

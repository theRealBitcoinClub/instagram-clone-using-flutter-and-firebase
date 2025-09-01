// import 'package:isar_community/isar.dart';
// import 'package:mahakka/memo/model/memo_model_user.dart';
//
// part 'memo_model_user_db.g.dart';
//
// @Collection()
// class MemoModelUserDb {
//   Id id = Isar.autoIncrement;
//
//   @Index(unique: true)
//   late String userId;
//
//   late String bchAddressCashtokenAware;
//   late String legacyAddressMemoBch;
//   late String legacyAddressMemoBchAsCashaddress;
//
//   @Enumerated(EnumType.name)
//   late TipReceiver tipReceiver;
//
//   late int tipAmountValue;
//
//   // Store creator ID for relationship
//   late String creatorId;
//
//   // Store balances for caching
//   late String balanceCashtokensDevPath145;
//   late String balanceBchDevPath145;
//   late String balanceBchDevPath0Memo;
//
//   // Add required unnamed constructor
//   MemoModelUserDb();
//
//   // Convert from app model to DB model
//   factory MemoModelUserDb.fromAppModel(MemoModelUser user) {
//     return MemoModelUserDb()
//       ..userId = user.id
//       ..bchAddressCashtokenAware = user.bchAddressCashtokenAware
//       ..legacyAddressMemoBch = user.legacyAddressMemoBch
//       ..legacyAddressMemoBchAsCashaddress = user.legacyAddressMemoBchAsCashaddress
//       ..tipReceiver = user.tipReceiver
//       ..tipAmountValue = user.tipAmount
//       ..creatorId = user.creator.id
//       ..balanceCashtokensDevPath145 = user.balanceCashtokensDevPath145
//       ..balanceBchDevPath145 = user.balanceBchDevPath145
//       ..balanceBchDevPath0Memo = user.balanceBchDevPath0Memo;
//   }
//
//   // Convert back to app model (partial - needs mnemonic to fully reconstruct)
//   MemoModelUser toPartialAppModel() {
//     return MemoModelUser(
//       id: userId,
//       bchAddressCashtokenAware: bchAddressCashtokenAware,
//       legacyAddressMemoBch: legacyAddressMemoBch,
//       legacyAddressMemoBchAsCashaddress: legacyAddressMemoBchAsCashaddress,
//       tipReceiver: tipReceiver,
//       tipAmount: TipAmount.values.firstWhere((e) => e.value == tipAmountValue, orElse: () => TipAmount.zero),
//     );
//   }
// }

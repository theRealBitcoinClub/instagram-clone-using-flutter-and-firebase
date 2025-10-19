// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoModelUser _$MemoModelUserFromJson(Map<String, dynamic> json) =>
    MemoModelUser(
        id: json['id'] as String,
        bchAddressCashtokenAware: json['bchAddressCashTokenAware'] as String,
        legacyAddressMemoBch: json['legacyAddressMemoBch'] as String,
        legacyAddressMemoBchAsCashaddress:
            json['legacyAddressMemoBchAsCashaddress'] as String,
        tipReceiver: $enumDecode(_$TipReceiverEnumMap, json['tipReceiver']),
        tipAmount: $enumDecode(_$TipAmountEnumMap, json['tipAmount']),
        ipfsCids:
            (json['ipfsCids'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      )
      ..tipReceiverSerialized = $enumDecode(
        _$TipReceiverEnumMap,
        json['tipReceiverSerialized'],
      )
      ..tipAmountSerialized = $enumDecode(
        _$TipAmountEnumMap,
        json['tipAmountSerialized'],
      );

Map<String, dynamic> _$MemoModelUserToJson(MemoModelUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bchAddressCashTokenAware': instance.bchAddressCashtokenAware,
      'legacyAddressMemoBch': instance.legacyAddressMemoBch,
      'legacyAddressMemoBchAsCashaddress':
          instance.legacyAddressMemoBchAsCashaddress,
      'tipReceiverSerialized':
          _$TipReceiverEnumMap[instance.tipReceiverSerialized]!,
      'tipAmountSerialized': _$TipAmountEnumMap[instance.tipAmountSerialized]!,
      'ipfsCids': instance.ipfsCids,
      'tipAmount': instance.tipAmount,
      'tipReceiver': _$TipReceiverEnumMap[instance.tipReceiver]!,
    };

const _$TipReceiverEnumMap = {
  TipReceiver.creator: 'creator',
  TipReceiver.burn25Creator75: 'burn25Creator75',
  TipReceiver.both: 'both',
  TipReceiver.burn75Creator25: 'burn75Creator25',
  TipReceiver.app: 'app',
};

const _$TipAmountEnumMap = {
  TipAmount.survival: 4567,
  TipAmount.nice: 7777,
  TipAmount.fren: 9999,
  TipAmount.wagmi: 12345,
  TipAmount.moon: 21212,
  TipAmount.sohigh: 42069,
};

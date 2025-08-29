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
    );

Map<String, dynamic> _$MemoModelUserToJson(MemoModelUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bchAddressCashTokenAware': instance.bchAddressCashtokenAware,
      'legacyAddressMemoBch': instance.legacyAddressMemoBch,
      'legacyAddressMemoBchAsCashaddress':
          instance.legacyAddressMemoBchAsCashaddress,
      'tipAmount': instance.tipAmount,
      'tipReceiver': _$TipReceiverEnumMap[instance.tipReceiver]!,
    };

const _$TipReceiverEnumMap = {
  TipReceiver.app: 'app',
  TipReceiver.creator: 'creator',
  TipReceiver.both: 'both',
};

const _$TipAmountEnumMap = {
  TipAmount.zero: 0,
  TipAmount.maintenance: 1,
  TipAmount.growth: 2,
  TipAmount.moon: 3,
};

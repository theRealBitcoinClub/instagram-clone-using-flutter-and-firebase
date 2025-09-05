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
  TipReceiver.burn20Creator80: 'burn20Creator80',
  TipReceiver.burn40Creator60: 'burn40Creator60',
  TipReceiver.burn60Creator40: 'burn60Creator40',
  TipReceiver.burn80Creator20: 'burn80Creator20',
};

const _$TipAmountEnumMap = {
  TipAmount.survival: 2345,
  TipAmount.nice: 4567,
  TipAmount.fren: 7777,
  TipAmount.wagmi: 9999,
  TipAmount.moon: 12345,
  TipAmount.sohigh: 42069,
};

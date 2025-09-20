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
  TipReceiver.creator: 'creator',
  TipReceiver.burn20Creator80: 'burn20Creator80',
  TipReceiver.burn40Creator60: 'burn40Creator60',
  TipReceiver.both: 'both',
  TipReceiver.burn60Creator40: 'burn60Creator40',
  TipReceiver.burn80Creator20: 'burn80Creator20',
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

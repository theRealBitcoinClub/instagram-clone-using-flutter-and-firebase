// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_creator.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoModelCreator _$MemoModelCreatorFromJson(Map<String, dynamic> json) => MemoModelCreator(
  id: json['id'] as String? ?? "",
  name: json['name'] as String? ?? "",
  profileText: json['profileText'] as String? ?? "",
  followerCount: (json['followerCount'] as num?)?.toInt() ?? 0,
  actions: (json['actions'] as num?)?.toInt() ?? 0,
  created: json['created'] as String? ?? "",
  lastActionDate: json['lastActionDate'] as String? ?? "",
);

Map<String, dynamic> _$MemoModelCreatorToJson(MemoModelCreator instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'profileText': instance.profileText,
  'followerCount': instance.followerCount,
  'actions': instance.actions,
  'created': instance.created,
  'lastActionDate': instance.lastActionDate,
};

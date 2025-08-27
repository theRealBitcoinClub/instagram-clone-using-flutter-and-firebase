// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoModelTag _$MemoModelTagFromJson(Map<String, dynamic> json) =>
    MemoModelTag(id: json['id'] as String, postCount: (json['postCount'] as num?)?.toInt(), lastPost: json['lastPost'] as String?);

Map<String, dynamic> _$MemoModelTagToJson(MemoModelTag instance) => <String, dynamic>{
  'id': instance.id,
  'postCount': instance.postCount,
  'lastPost': instance.lastPost,
};

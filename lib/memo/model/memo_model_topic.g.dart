// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_topic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoModelTopic _$MemoModelTopicFromJson(Map<String, dynamic> json) => MemoModelTopic(
  id: json['id'] as String,
  url: json['url'] as String?,
  postCount: (json['postCount'] as num?)?.toInt(),
  followerCount: (json['followerCount'] as num?)?.toInt(),
  lastPost: json['lastPost'] as String?,
);

Map<String, dynamic> _$MemoModelTopicToJson(MemoModelTopic instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'postCount': instance.postCount,
  'followerCount': instance.followerCount,
  'lastPost': instance.lastPost,
};

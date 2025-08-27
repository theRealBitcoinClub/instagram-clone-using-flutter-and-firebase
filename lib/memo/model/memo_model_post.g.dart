// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoModelPost _$MemoModelPostFromJson(Map<String, dynamic> json) => MemoModelPost(
  id: json['id'] as String? ?? '',
  text: json['text'] as String?,
  uniqueContentId: json['uniqueContentId'] as String?,
  imgurUrl: json['imgurUrl'] as String?,
  youtubeId: json['youtubeId'] as String?,
  popularityScore: (json['popularityScore'] as num?)?.toInt(),
  likeCounter: (json['likeCounter'] as num?)?.toInt(),
  replyCounter: (json['replyCounter'] as num?)?.toInt(),
  creatorId: json['creatorId'] as String? ?? '',
  topicId: json['topicId'] as String? ?? '',
  tagIds: (json['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  createdDateTime: _dateTimeFromJson(json['createdDateTime'] as Timestamp?),
);

Map<String, dynamic> _$MemoModelPostToJson(MemoModelPost instance) => <String, dynamic>{
  'id': instance.id,
  'popularityScore': instance.popularityScore,
  'text': instance.text,
  'uniqueContentId': instance.uniqueContentId,
  'imgurUrl': instance.imgurUrl,
  'youtubeId': instance.youtubeId,
  'createdDateTime': _dateTimeToJson(instance.createdDateTime),
  'likeCounter': instance.likeCounter,
  'replyCounter': instance.replyCounter,
  'creatorId': instance.creatorId,
  'topicId': instance.topicId,
  'tagIds': instance.tagIds,
};

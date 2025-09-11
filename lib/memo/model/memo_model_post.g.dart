// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memo_model_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemoModelPost _$MemoModelPostFromJson(Map<String, dynamic> json) =>
    MemoModelPost(
        id: json['id'] as String?,
        text: json['text'] as String?,
        imgurUrl: json['imgurUrl'] as String?,
        youtubeId: json['youtubeId'] as String?,
        createdDateTime: _dateTimeFromJson(json['createdDateTime'] as Timestamp?),
        popularityScore: (json['popularityScore'] as num?)?.toInt() ?? 0,
        likeCounter: (json['likeCounter'] as num?)?.toInt(),
        replyCounter: (json['replyCounter'] as num?)?.toInt(),
        creatorId: json['creatorId'] as String? ?? '',
        topicId: json['topicId'] as String? ?? '',
        tagIds: (json['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      )
      ..imageUrl = json['imageUrl'] as String?
      ..videoUrl = json['videoUrl'] as String?
      ..showOnFeed = json['showOnFeed'] as bool?
      ..ipfsCid = json['ipfsCid'] as String?;

Map<String, dynamic> _$MemoModelPostToJson(MemoModelPost instance) => <String, dynamic>{
  if (instance.id case final value?) 'id': value,
  if (instance.text case final value?) 'text': value,
  if (instance.imgurUrl case final value?) 'imgurUrl': value,
  if (instance.youtubeId case final value?) 'youtubeId': value,
  if (instance.imageUrl case final value?) 'imageUrl': value,
  if (instance.videoUrl case final value?) 'videoUrl': value,
  'showOnFeed': instance.showOnFeed,
  if (instance.ipfsCid case final value?) 'ipfsCid': value,
  if (_dateTimeToJson(instance.createdDateTime) case final value?) 'createdDateTime': value,
  'popularityScore': instance.popularityScore,
  if (instance.likeCounter case final value?) 'likeCounter': value,
  if (instance.replyCounter case final value?) 'replyCounter': value,
  'creatorId': instance.creatorId,
  'topicId': instance.topicId,
  'tagIds': instance.tagIds,
};

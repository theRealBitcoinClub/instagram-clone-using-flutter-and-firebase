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
      popularityScore: (json['popularityScore'] as num?)?.toInt(),
      likeCounter: (json['likeCounter'] as num?)?.toInt(),
      replyCounter: (json['replyCounter'] as num?)?.toInt(),
      creatorId: json['creatorId'] as String? ?? '',
      topicId: json['topicId'] as String? ?? '',
      tagIds:
          (json['tagIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MemoModelPostToJson(MemoModelPost instance) =>
    <String, dynamic>{
      if (instance.id case final value?) 'id': value,
      if (instance.text case final value?) 'text': value,
      if (instance.imgurUrl case final value?) 'imgurUrl': value,
      if (instance.youtubeId case final value?) 'youtubeId': value,
      if (_dateTimeToJson(instance.createdDateTime) case final value?)
        'createdDateTime': value,
      if (instance.popularityScore case final value?) 'popularityScore': value,
      if (instance.likeCounter case final value?) 'likeCounter': value,
      if (instance.replyCounter case final value?) 'replyCounter': value,
      'creatorId': instance.creatorId,
      'topicId': instance.topicId,
      'tagIds': instance.tagIds,
    };

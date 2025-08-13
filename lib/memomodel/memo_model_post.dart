import 'memo_model_creator.dart';
import 'memo_model_topic.dart';

class MemoModelPost {
  MemoModelPost({
    this.text,
    this.txHash,
    this.imageUrl,
    this.videoUrl,
    this.urls,
    this.creator,
    this.tipsInSatoshi,
    this.likeCounter,
    this.replyCounter,
    this.created,
    this.age,
    this.hashtags,
    this.topic
  });

  final int? tipsInSatoshi;
  final String? text;
  final String? txHash;
  final String? imageUrl;
  String? videoUrl;
  final String? created;
  final int? likeCounter;
  final int? replyCounter;
  final List<String>? urls;
  final List<String>? hashtags;
  late final MemoModelCreator? creator;
  late final MemoModelTopic? topic;
  final String? age;
}
import 'package:instagram_clone1/memomodel/memo_model_user.dart';

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
  String? text;
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
  static final List<MemoModelPost> globalPosts = [];

  static MemoModelPost createDummy() {
    MemoModelUser memoModelUser = MemoModelUser.createDummy();
    MemoModelCreator memoModelCreator = memoModelUser.creator!;
    
    MemoModelTopic topic = MemoModelTopic.createDummy();
    memoModelCreator.topics.add(topic);
    MemoModelPost memoModelPost = MemoModelPost(
                    age: "11d",
                    created: "11.11.1911 11:11",
                    creator: memoModelCreator,
                    imageUrl: "https://i.imgur.com/YbduTBp.png",
                    likeCounter: 33,
                    replyCounter: 2,
                    text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
                    tipsInSatoshi: 123456,
                    txHash: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
                    topic: topic);

    for (int i=0; i<20; i++) {
      topic.posts.add(memoModelPost);
    }
    memoModelCreator.posts=topic.posts;

    return memoModelPost;
  }

  static void addToGlobalPostList(List<MemoModelPost> createMemoModelPostList) {
    globalPosts.addAll(createMemoModelPostList);

  }
}
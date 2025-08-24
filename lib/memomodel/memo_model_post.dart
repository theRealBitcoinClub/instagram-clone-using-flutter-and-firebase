import 'package:instagram_clone1/memomodel/memo_model_user.dart';

import '../memobase/memo_accountant.dart';
import '../memobase/memo_verifier.dart';
import 'memo_model_creator.dart';
import 'memo_model_topic.dart';

class MemoModelPost {
  MemoModelPost({
    this.text,
    this.txHash,
    this.imgurUrl,
    this.youtubeId,
    this.creator,
    this.tipsInSatoshi,
    this.likeCounter,
    this.replyCounter,
    this.created,
    this.age,
    this.topic,
  });

  final int? tipsInSatoshi;
  String? text;
  final String? txHash;
  final String? imgurUrl;
  String? youtubeId;
  final String? created;
  final int? likeCounter;
  final int? replyCounter;
  final List<String> urls = [];
  final List<String> hashtags = [];
  late final MemoModelCreator? creator;
  late final MemoModelTopic? topic;
  final String? age;
  static final List<MemoModelPost> posts = [];
  static final List<MemoModelPost> ytPosts = [];
  static final List<MemoModelPost> imgurPosts = [];
  static final List<MemoModelPost> hashTagPosts = [];

  // static final List<MemoModelPost> urlPosts = [];
  static final List<MemoModelPost> topicPosts = [];

  static Future<MemoModelPost> createDummy(MemoModelCreator memoModelCreator) async {
    MemoModelTopic topic = MemoModelTopic.createDummy();
    MemoModelPost memoModelPost = MemoModelPost(
      age: "11d",
      created: "11.11.1911 11:11",
      creator: memoModelCreator,
      imgurUrl: "https://i.imgur.com/YbduTBp.png",
      likeCounter: 33,
      replyCounter: 2,
      text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
      tipsInSatoshi: 123456,
      txHash: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
      topic: topic,
    );

    for (int i = 0; i < 20; i++) {
      topic.posts.add(memoModelPost);
    }
    memoModelCreator.posts = topic.posts;

    return memoModelPost;
  }

  static void clearLists() {
    posts.clear();
    imgurPosts.clear();
    ytPosts.clear();
    hashTagPosts.clear();
    topicPosts.clear();
  }

  static void addToGlobalPostList(List<MemoModelPost> p) {
    MemoModelPost.posts.addAll(p);

    //TODO DO NOT ITERATE THROUGH ALL POSTS HERE AS YOU ALREADY DID THAT BEFORE,
    for (var element in p) {
      // if (element.creator!.id != MemoModelCreator.createDummy().id)
      //   continue; //TODO ONLY SHOW OWN POSTS ON PROFILE

      if (element.imgurUrl != null && element.imgurUrl!.isNotEmpty) {
        imgurPosts.add(element);
      } else if (element.youtubeId != null && element.youtubeId!.isNotEmpty) {
        ytPosts.add(element);
      } else if (element.hashtags.isNotEmpty) {
        hashTagPosts.add(element);
        // } else if (element.urls.isNotEmpty) {
        //   urlPosts.add(element);
      } else if (element.topic != null) {
        topicPosts.add(element);
      }
    }
  }

  //Returns either MemoVerificationResponse or MemoAccountantResponse
  //On return MemoAccountantResponse.yes everything worked fine and text can be cleared
  //Any other response should invoke a snackbar and later even better QR codes to insta deposit

  Future<dynamic> publishReply(String text, String topic) async {
    MemoVerificationResponse verifier = MemoVerifier().checkIsValidText(text);
    if (verifier == MemoVerificationResponse.valid) {
      //TODO at this point accountant should never throw error as it is already checking balances before allowing the user to write
      MemoAccountantResponse accountant = await MemoAccountant(
        await MemoModelUser.getUser(),
        creator!,
        text,
      ).publishReply(topic);

      return accountant;
    } else
      return verifier;
  }

  //TODO IMPLEMENT EQUALS METHOD, CHECK TX HASH
}

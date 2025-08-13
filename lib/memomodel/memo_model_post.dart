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

  static MemoModelPost createDummy() {
    return MemoModelPost(
        age: "11d",
        created: "11.11.1911 11:11",
        creator: MemoModelCreator(
            created: "12.12.1912 12:12",
            id: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
            followerCount: 123,
            actions: 4324,
            followingCount: 22,
            name: "Feliz-TRBC",
            profileText: "Inshalla \n Porke No \n BLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLA"),
        imageUrl: "https://i.imgur.com/YbduTBp.png",
        likeCounter: 33,
        replyCounter: 2,
        text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
        tipsInSatoshi: 123456,
        txHash: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
        topic: MemoModelTopic(
            followerCount: 12,
            postCount: 33,
            lastPost: "13.09.2001 23:22",
            header: "Super Topic",
            url: "https://memo.cash/topic/Bitcoin+Map",
            posts: [MemoModelPost(
                age: "11d",
                created: "11.11.1911 11:11",
                creator: MemoModelCreator(
                    created: "12.12.1912 12:12",
                    id: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
                    followerCount: 123,
                    actions: 4324,
                    followingCount: 22,
                    name: "Feliz-TRBC",
                    profileText: "Inshalla \n Porke No \n BLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLA"),
                imageUrl: "https://i.imgur.com/YbduTBp.png",
                likeCounter: 33,
                replyCounter: 2,
                text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
                tipsInSatoshi: 123456,
                txHash: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
                topic: MemoModelTopic(
                    followerCount: 12,
                    postCount: 33,
                    lastPost: "13.09.2001 23:22",
                    header: "Super Topic",
                    url: "https://memo.cash/topic/Bitcoin+Map")),
                MemoModelPost(
                    age: "11d",
                    created: "11.11.1911 11:11",
                    creator: MemoModelCreator(
                        created: "12.12.1912 12:12",
                        id: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
                        followerCount: 123,
                        actions: 4324,
                        followingCount: 22,
                        name: "Feliz-TRBC",
                        profileText: "Inshalla \n Porke No \n BLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLABLA"),
                    imageUrl: "https://i.imgur.com/YbduTBp.png",
                    likeCounter: 33,
                    replyCounter: 2,
                    text: "SAFDHSF DSF HDSFHDSKJ HFDSKJ HFDSJHF DHSFKJH DSJFHDSKJ HFKJDSH",
                    tipsInSatoshi: 123456,
                    txHash: "3228faaa15d9512ee6ecc29b8808876a7680e6d7493c22014b942825c975c0ca",
                    topic: MemoModelTopic(
                        followerCount: 12,
                        postCount: 33,
                        lastPost: "13.09.2001 23:22",
                        header: "Super Topic",
                        url: "https://memo.cash/topic/Bitcoin+Map"))]));
  }
}
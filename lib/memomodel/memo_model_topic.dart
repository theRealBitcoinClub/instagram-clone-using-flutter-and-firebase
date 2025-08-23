import 'package:flutter/material.dart';
import 'package:instagram_clone1/taggable/taggable.dart';

import 'memo_model_post.dart';

class MemoModelTopic extends Taggable{
  static List<MemoModelTopic> topics = [];

  MemoModelTopic({
    this.header,
    this.url,
    this.postCount,
    this.followerCount,
    this.lastPost, required super.id, required super.name, super.icon = Icons.topic_outlined
  }) {
    id = id.replaceAll(" ", "_");
  }

  List<MemoModelPost> posts = [];
  final String? header;
  final String? url;
  final int? postCount;
  final int? followerCount;
  final String? lastPost;

  static MemoModelTopic createDummy() {
    return MemoModelTopic(
        followerCount: 12,
        postCount: 0,
        lastPost: "13.09.2001 23:22",
        header: "Super Topic",
        url: "https://memo.cash/topic/Bitcoin+Map", id: "Super Topic", name: "Super Topic");
  }
}
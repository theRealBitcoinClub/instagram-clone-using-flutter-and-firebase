import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import '../taggable/taggable.dart';

class MemoModelTag extends Taggable {
  static List<MemoModelTag> tags = [];

  MemoModelTag({
    this.postCount,
    this.lastPost, required super.id, required super.name, super.icon = Icons.tag_rounded
  });

  final int? postCount;
  final String? lastPost;
  final List<MemoModelPost> posts = [];


  //TODO IMPLEMENT EQUALS METHOD, CHECK ID
}
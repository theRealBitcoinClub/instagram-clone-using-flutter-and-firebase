import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_tag.dart';
import 'package:instagram_clone1/memomodel/memo_model_topic.dart';

///Search view model
final searchViewModel = SearchViewModel();

enum SearchResultView {
  // users,
  hashtag,
  topics,
  none,
}

class SearchViewModel {
  late final ValueNotifier<List<MemoModelTopic>> _topics = ValueNotifier([]);

  ValueNotifier<List<MemoModelTopic>> get topics => _topics;

  // late final ValueNotifier<List<User>> _users = ValueNotifier([]);
  // ValueNotifier<List<User>> get users => _users;

  late final ValueNotifier<List<MemoModelTag>> _hashtags = ValueNotifier([]);

  ValueNotifier<List<MemoModelTag>> get hashtags => _hashtags;

  late final ValueNotifier<bool> _loading = ValueNotifier(false);

  ValueNotifier<bool> get loading => _loading;

  late final ValueNotifier<SearchResultView> _activeView = ValueNotifier(SearchResultView.none);

  ValueNotifier<SearchResultView> get activeView => _activeView;

  void _setLoading(bool val) {
    if (val != _loading.value) {
      _loading.value = val;
    }
  }

  Future<void> searchTopic(String query) async {
    _activeView.value = SearchResultView.topics;
    if (query.isEmpty) return;

    query = query.toLowerCase().trim();

    _topics.value = [];

    _setLoading(true);

    await Future.delayed(const Duration(milliseconds: 250));

    final result = MemoModelTopic.topics.where((topic) => topic.header.toLowerCase().contains(query)).toList();

    _topics.value = [...result];
    _setLoading(false);
  }

  //
  // Future<void> searchUser(String query) async {
  //   _activeView.value = SearchResultView.users;
  //   if (query.isEmpty) return;
  //
  //   query = query.toLowerCase().trim();
  //
  //   _users.value = [];
  //
  //   _setLoading(true);
  //
  //   await Future.delayed(const Duration(milliseconds: 250));
  //
  //   final result = User.allUsers
  //       .where(
  //         (user) =>
  //             user.userName.toLowerCase().contains(query) ||
  //             user.fullName.toLowerCase().contains(query),
  //       )
  //       .toList();
  //
  //   _users.value = [...result];
  //   _setLoading(false);
  // }

  Future<void> searchHashtag(String query) async {
    _activeView.value = SearchResultView.hashtag;
    if (query.isEmpty) return;

    query = query.toLowerCase().trim();

    _hashtags.value = [];

    _setLoading(true);

    await Future.delayed(const Duration(milliseconds: 250));

    final result = MemoModelTag.tags.where((tag) => tag.name!.toLowerCase().contains(query)).toList();

    _hashtags.value = [...result];
    _setLoading(false);
  }
}

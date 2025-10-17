// view_models/search_view_model.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/tag_service.dart';
import 'package:mahakka/memo/firebase/topic_service.dart';

import '../../memo/model/memo_model_tag_light.dart';
import '../../memo/model/memo_model_topic_light.dart';

enum SearchResultView { hashtag, topics, hintText }

final topicServiceProvider = Provider<TopicService>((ref) => TopicService());
final tagServiceProvider = Provider<TagService>((ref) => TagService());

final searchViewModelProvider = StateNotifierProvider<SearchViewModel, SearchState>(
  (ref) => SearchViewModel(topicService: ref.watch(topicServiceProvider), tagService: ref.watch(tagServiceProvider)),
);

class SearchState {
  final List<MemoModelTopicLight> topics;
  final List<MemoModelTagLight> hashtags;
  final SearchResultView activeView;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.topics = const [],
    this.hashtags = const [],
    this.activeView = SearchResultView.hintText,
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    List<MemoModelTopicLight>? topics,
    List<MemoModelTagLight>? hashtags,
    SearchResultView? activeView,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      topics: topics ?? this.topics,
      hashtags: hashtags ?? this.hashtags,
      activeView: activeView ?? this.activeView,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SearchViewModel extends StateNotifier<SearchState> {
  final TopicService _topicService;
  final TagService _tagService;

  List<MemoModelTopicLight>? _cachedTopics;
  List<MemoModelTagLight>? _cachedTags;

  bool get _isTopicsCacheValid => _cachedTopics != null;
  bool get _isTagsCacheValid => _cachedTags != null;

  SearchViewModel({required TopicService topicService, required TagService tagService})
    : _topicService = topicService,
      _tagService = tagService,
      super(const SearchState());

  Future<void> refreshCache() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([_topicService.getLightweightTopics(), _tagService.getAllTags()]);

      _cachedTopics = results[0] as List<MemoModelTopicLight>;
      _cachedTags = results[1] as List<MemoModelTagLight>;

      state = state.copyWith(isLoading: false);
    } catch (error, stackTrace) {
      state = state.copyWith(isLoading: false, error: 'Failed to refresh cache: $error');
      _print('Cache refresh error: $error\n$stackTrace');
    }
  }

  Future<bool> _ensureCacheLoaded() async {
    if (_isTopicsCacheValid && _isTagsCacheValid) return true;

    try {
      if (!_isTopicsCacheValid) {
        _cachedTopics = await _topicService.getLightweightTopics();
      }
      if (!_isTagsCacheValid) {
        _cachedTags = await _tagService.getLightweightTags();
      }

      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(isLoading: false, error: 'Failed to load cache: $error');
      _print('Cache loading error: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> searchTopic(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(topics: [], activeView: SearchResultView.topics, isLoading: false);
      return;
    }

    state = state.copyWith(activeView: SearchResultView.topics, isLoading: true, error: null);

    if (!mounted) return;
    final cacheLoaded = await _ensureCacheLoaded();
    if (!mounted) return;
    if (!cacheLoaded) return;

    await Future.delayed(const Duration(milliseconds: 250));

    final trimmedQuery = query.toLowerCase().trim();
    final results = _cachedTopics!.where((topic) => topic.id.toLowerCase().startsWith(trimmedQuery)).toList();
    results.sort((a, b) => b.count.compareTo(a.count));

    state = state.copyWith(topics: results, isLoading: false);
  }

  Future<void> searchHashtag(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(hashtags: [], activeView: SearchResultView.hashtag, isLoading: false);
      return;
    }

    state = state.copyWith(activeView: SearchResultView.hashtag, isLoading: true, error: null);

    final cacheLoaded = await _ensureCacheLoaded();
    if (!cacheLoaded) return;

    await Future.delayed(const Duration(milliseconds: 250));

    final trimmedQuery = query.toLowerCase().trim();
    final results = _cachedTags!.where((tag) => tag.id.toLowerCase().startsWith(trimmedQuery)).toList();
    results.sort((a, b) => b.count.compareTo(a.count));

    state = state.copyWith(hashtags: results, isLoading: false);
  }

  void clearSearch() {
    state = state.copyWith(topics: [], hashtags: [], activeView: SearchResultView.hintText, error: null, isLoading: false);
  }

  @override
  void dispose() {
    clearSearch();
    super.dispose();
  }

  void _print(String s) {
    if (kDebugMode) print(s);
  }
}

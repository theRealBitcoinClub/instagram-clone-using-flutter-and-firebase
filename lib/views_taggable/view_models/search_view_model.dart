// view_models/search_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/firebase/tag_service.dart';
import 'package:mahakka/memo/firebase/topic_service.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

enum SearchResultView { hashtag, topics, hintText }

final topicServiceProvider = Provider<TopicService>((ref) => TopicService());
final tagServiceProvider = Provider<TagService>((ref) => TagService());

final searchViewModelProvider = StateNotifierProvider<SearchViewModel, SearchState>(
  (ref) => SearchViewModel(topicService: ref.watch(topicServiceProvider), tagService: ref.watch(tagServiceProvider)),
);

class SearchState {
  final List<MemoModelTopic> topics;
  final List<MemoModelTag> hashtags;
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
    List<MemoModelTopic>? topics,
    List<MemoModelTag>? hashtags,
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

  List<MemoModelTopic>? _cachedTopics;
  List<MemoModelTag>? _cachedTags;

  bool get _isTopicsCacheValid => _cachedTopics != null;
  bool get _isTagsCacheValid => _cachedTags != null;

  SearchViewModel({required TopicService topicService, required TagService tagService})
    : _topicService = topicService,
      _tagService = tagService,
      super(const SearchState());

  Future<void> refreshCache() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([_topicService.getAllTopics(), _tagService.getAllTags()]);

      _cachedTopics = results[0] as List<MemoModelTopic>;
      _cachedTags = results[1] as List<MemoModelTag>;

      state = state.copyWith(isLoading: false);
    } catch (error, stackTrace) {
      state = state.copyWith(isLoading: false, error: 'Failed to refresh cache: $error');
      print('Cache refresh error: $error\n$stackTrace');
    }
  }

  Future<bool> _ensureCacheLoaded() async {
    if (_isTopicsCacheValid && _isTagsCacheValid) return true;

    // state = state.copyWith(isLoading: true, error: null);

    try {
      if (!_isTopicsCacheValid) {
        _cachedTopics = await _topicService.getAllTopics();
      }
      // if (!mounted) return false;
      if (!_isTagsCacheValid) {
        _cachedTags = await _tagService.getAllTags();
      }

      // if (!mounted) return false;
      // state = state.copyWith(isLoading: false);
      return true;
    } catch (error, stackTrace) {
      state = state.copyWith(isLoading: false, error: 'Failed to load cache: $error');
      print('Cache loading error: $error\n$stackTrace');
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
    final results = _cachedTopics!.where((topic) => topic.header.toLowerCase().contains(trimmedQuery)).toList();

    state = state.copyWith(topics: results, isLoading: false);
  }

  Future<void> searchHashtag(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(hashtags: [], activeView: SearchResultView.hashtag, isLoading: false);
      return;
    }

    state = state.copyWith(activeView: SearchResultView.hashtag, isLoading: true, error: null);

    // if (!mounted) return;
    final cacheLoaded = await _ensureCacheLoaded();
    // if (!mounted) return;
    if (!cacheLoaded) return;

    await Future.delayed(const Duration(milliseconds: 250));

    final trimmedQuery = query.toLowerCase().trim();
    final results = _cachedTags!.where((tag) => tag.name.toLowerCase().contains(trimmedQuery)).toList();

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
}

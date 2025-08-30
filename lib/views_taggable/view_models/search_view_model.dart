import 'package:flutter/foundation.dart'; // For ValueNotifier
import 'package:mahakka/memo/firebase/tag_service.dart';
// TODO: Import your actual TopicService and TagService
import 'package:mahakka/memo/firebase/topic_service.dart';
import 'package:mahakka/memo/model/memo_model_tag.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';

final searchViewModel = SearchViewModel();

enum SearchResultView { hashtag, topics, none }

class SearchViewModel {
  final TopicService _topicService = TopicService();
  final TagService _tagService = TagService();

  // In-memory caches
  List<MemoModelTopic> _allTopicsCache = [];
  List<MemoModelTag> _allTagsCache = [];

  bool _areTopicsCached = false;
  bool _areTagsCached = false;
  bool _isCacheLoading = false; // To prevent multiple concurrent cache loads

  final ValueNotifier<List<MemoModelTopic>> _topicsSearchResults = ValueNotifier([]);
  ValueNotifier<List<MemoModelTopic>> get topics => _topicsSearchResults;

  final ValueNotifier<List<MemoModelTag>> _hashtagsSearchResults = ValueNotifier([]);
  ValueNotifier<List<MemoModelTag>> get hashtags => _hashtagsSearchResults;

  final ValueNotifier<bool> _loadingSearch = ValueNotifier(false); // For search operation itself
  ValueNotifier<bool> get loading => _loadingSearch;

  final ValueNotifier<SearchResultView> _activeView = ValueNotifier(SearchResultView.none);
  ValueNotifier<SearchResultView> get activeView => _activeView;

  SearchViewModel() {
    // Optionally, load caches when the ViewModel is created
    // Or, you can have an explicit method like `initializeCache()`
    // to be called from your app's initialization logic.
    _loadAllTopicsAndTagsCache();
  }

  void _setSearchLoading(bool val) {
    if (val != _loadingSearch.value) {
      _loadingSearch.value = val;
    }
  }

  /// Loads all topics and tags from Firebase into local caches.
  /// Includes a flag to prevent multiple concurrent loads.
  Future<void> _loadAllTopicsAndTagsCache({bool forceRefresh = false}) async {
    if (_isCacheLoading && !forceRefresh) {
      print("SearchViewModel: Cache loading already in progress.");
      return;
    }
    if ((_areTopicsCached && _areTagsCached) && !forceRefresh) {
      print("SearchViewModel: Topics and Tags already cached.");
      return;
    }

    _isCacheLoading = true;
    _setSearchLoading(true); // Indicate overall loading for initial cache
    print("SearchViewModel: Starting to load/refresh caches...");

    try {
      if (!_areTopicsCached || forceRefresh) {
        _allTopicsCache = await _topicService.getAllTopics();
        _areTopicsCached = true;
        print("SearchViewModel: All topics cached (${_allTopicsCache.length} items).");
      }
      if (!_areTagsCached || forceRefresh) {
        _allTagsCache = await _tagService.getAllTags();
        _areTagsCached = true;
        print("SearchViewModel: All tags cached (${_allTagsCache.length} items).");
      }
    } catch (e, s) {
      print("SearchViewModel: Error loading caches: $e");
      print(s);
      // Decide how to handle cache loading errors (e.g., retry logic, error state)
      _areTopicsCached = false; // Reset flags on error so it can retry
      _areTagsCached = false;
    } finally {
      _isCacheLoading = false;
      _setSearchLoading(false);
    }
  }

  /// Call this method if you want to manually refresh the cache from Firebase.
  Future<void> refreshCache() async {
    await _loadAllTopicsAndTagsCache(forceRefresh: true);
  }

  Future<void> searchTopic(String query) async {
    _activeView.value = SearchResultView.topics;
    _topicsSearchResults.value = []; // Clear previous search results

    if (query.isEmpty) {
      _setSearchLoading(false);
      return;
    }

    final String trimmedQuery = query.toLowerCase().trim();
    if (trimmedQuery.isEmpty) {
      _setSearchLoading(false);
      return;
    }

    _setSearchLoading(true);

    // Ensure cache is loaded before searching
    if (!_areTopicsCached && !_isCacheLoading) {
      print("SearchViewModel: Topics cache not ready, attempting to load...");
      await _loadAllTopicsAndTagsCache(); // Wait for cache to load
      if (!_areTopicsCached) {
        // Check again if loading failed
        print("SearchViewModel: Failed to load topics cache for search.");
        _setSearchLoading(false);
        return;
      }
    } else if (_isCacheLoading) {
      // If cache is currently loading, wait a bit then retry search or return empty
      // This is a simple wait; a more robust solution might use a Completer or listen to a cache loaded event.
      await Future.delayed(const Duration(seconds: 1));
      if (!_areTopicsCached) {
        print("SearchViewModel: Topics cache still not ready after waiting.");
        _setSearchLoading(false);
        return;
      }
    }

    // Perform search on the cached list
    // The Future.delayed is just to simulate a slight processing delay for UX,
    // as local filtering is very fast. You can remove it.
    await Future.delayed(const Duration(milliseconds: 50));

    final result = _allTopicsCache.where((topic) => topic.header.toLowerCase().startsWith(trimmedQuery)).toList();

    _topicsSearchResults.value = result;
    _setSearchLoading(false);
  }

  Future<void> searchHashtag(String query) async {
    _activeView.value = SearchResultView.hashtag;
    _hashtagsSearchResults.value = [];

    if (query.isEmpty) {
      _setSearchLoading(false);
      return;
    }

    final String trimmedQuery = query.toLowerCase().trim();
    if (trimmedQuery.isEmpty) {
      _setSearchLoading(false);
      return;
    }

    _setSearchLoading(true);

    // Ensure cache is loaded
    if (!_areTagsCached && !_isCacheLoading) {
      print("SearchViewModel: Tags cache not ready, attempting to load...");
      await _loadAllTopicsAndTagsCache();
      if (!_areTagsCached) {
        print("SearchViewModel: Failed to load tags cache for search.");
        _setSearchLoading(false);
        return;
      }
    } else if (_isCacheLoading) {
      await Future.delayed(const Duration(seconds: 1));
      if (!_areTagsCached) {
        print("SearchViewModel: Tags cache still not ready after waiting.");
        _setSearchLoading(false);
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 50));

    final result = _allTagsCache.where((tag) => tag.name.toLowerCase().startsWith(trimmedQuery)).toList();

    _hashtagsSearchResults.value = result;
    _setSearchLoading(false);
  }

  void clearSearch() {
    _topicsSearchResults.value = [];
    _hashtagsSearchResults.value = [];
    _activeView.value = SearchResultView.none;
    _setSearchLoading(false);
  }
}

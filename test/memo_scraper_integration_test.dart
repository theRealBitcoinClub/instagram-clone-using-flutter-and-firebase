import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahakka/memo/firebase/post_service.dart';
import 'package:mahakka/memo/firebase/topic_service.dart';
import 'package:mahakka/memo/memo_reg_exp.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/memo/model/memo_model_topic.dart';
import 'package:mahakka/memo/scraper/memo_scraper_topics.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock Firebase setup
void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
}

void main() {
  group('MemoScraperTopic Integration Tests with Firebase', () {
    late MemoScraperTopic scraper;
    late String mockHtmlContent;
    late FakeFirebaseFirestore fakeFirestore;
    late PostService postService;
    late TopicService topicService;
    late SharedPreferences prefs;

    setUpAll(() async {
      setupFirebaseMocks();

      // Load the mock HTML file
      final file = File('test/resources/mock_topic_html.html');
      mockHtmlContent = await file.readAsString();
    });

    setUp(() async {
      // Setup fake Firestore
      fakeFirestore = FakeFirebaseFirestore();

      // Setup services with dependency injection
      postService = PostService(firestore: fakeFirestore, collectionName: 'test_posts');

      // topicService = TopicService(firestore: fakeFirestore, collectionName: 'test_topics');

      // Setup mock shared preferences
      // prefs = await SharedPreferences.getInstance();

      scraper = MemoScraperTopic();
    });

    test('Full integration: Scrape -> Persist -> Validate with MemoRegExp', () async {
      // 1. Create a mock topic
      final topic = MemoModelTopic(
        id: 'mahakka.com',
        url: 'topic/mahakka.com',
        followerCount: 0,
        lastPost: 'recent',
        postCount: 7, // Total posts in mock HTML
        lastPostCount: 0, // No previous posts
      );

      // 2. Scrape posts from mock HTML
      final scrapedPosts = await scraper.scrapeTopicHarvestPosts(topic, 'test-cache', mockData: mockHtmlContent);

      expect(scrapedPosts, isNotEmpty);
      //TODO ADD TEST TO MOCK YOUTUBE VIDEO CHECKER, FOR NOW ONE VIDEO IS SUCCESSFULLY REMOVED AS CHECK FAILED
      expect(scrapedPosts.length, 6);

      // 3. Persist posts to Firebase (test collection)
      for (final post in scrapedPosts) {
        await postService.savePost(post);
      }

      // 4. Retrieve posts one by one and validate properties
      for (final originalPost in scrapedPosts) {
        final retrievedPost = await postService.getPostOnce(originalPost.id!);

        expect(retrievedPost, isNotNull);
        expect(retrievedPost!.id, equals(originalPost.id));
        expect(retrievedPost.text, equals(originalPost.text));
        // expect(retrievedPost.creator?.id, equals(originalPost.creator?.id));

        // 5. Test MemoRegExp extraction on retrieved posts
        final memoRegExp = MemoRegExp(retrievedPost.text ?? '');

        // Test all extraction methods
        _testMemoRegExpMethods(memoRegExp, retrievedPost);
      }

      // 6. Additional validation: Check specific post properties
      await _validateSpecificPosts(scrapedPosts, postService);
    });

    test('Scrape and validate specific media types', () async {
      final topic = MemoModelTopic(
        id: 'mahakka.com',
        url: 'topic/mahakka.com',
        followerCount: 0,
        lastPost: 'recent',
        postCount: 7,
        lastPostCount: 0,
      );

      final scrapedPosts = await scraper.scrapeTopicHarvestPosts(topic, 'test-cache', mockData: mockHtmlContent);

      // Persist posts
      for (final post in scrapedPosts) {
        await postService.savePost(post);
      }

      // Validate specific media types
      final postsWithImages = scrapedPosts.where((post) {
        final memoRegExp = MemoRegExp(post.imgurUrl ?? '');
        return memoRegExp.hasAnyWhitelistedImageUrl();
      }).toList();

      final postsWithVideos = scrapedPosts.where((post) {
        final memoRegExp = MemoRegExp(post.text ?? '');
        return memoRegExp.hasAnyWhitelistedVideoUrl();
      }).toList();

      // Should find posts with images based on mock HTML
      expect(postsWithImages.length, greaterThan(0));

      // Should find posts with videos based on mock HTML
      //TODO IMPLEMENT MOCK VIDEO CHECKER TO LET THE VIDEO PASS
      expect(postsWithVideos.length, equals(0));
      // expect(postsWithVideos.length, greaterThan(0));

      // Verify specific URLs are extracted correctly
      for (final post in postsWithImages) {
        final retrievedPost = await postService.getPostOnce(post.id!);
        final memoRegExp = MemoRegExp(retrievedPost!.imgurUrl ?? '');

        final imageUrls = memoRegExp.extractAllWhitelistedImageUrls();
        expect(imageUrls, isNotEmpty);

        // Verify URLs are valid
        for (final url in imageUrls) {
          expect(MemoRegExp.isUrlWhitelisted(url), isTrue);
        }
      }
    });

    test('Validate IPFS CID extraction from persisted posts', () async {
      final topic = MemoModelTopic(
        id: 'mahakka.com',
        url: 'topic/mahakka.com',
        followerCount: 0,
        lastPost: 'recent',
        postCount: 7,
        lastPostCount: 0,
      );

      final scrapedPosts = await scraper.scrapeTopicHarvestPosts(topic, 'test-cache', mockData: mockHtmlContent);

      // Persist posts
      for (final post in scrapedPosts) {
        await postService.savePost(post);
      }

      // Check for IPFS CIDs in posts
      for (final post in scrapedPosts) {
        final retrievedPost = await postService.getPostOnce(post.id!);
        final memoRegExp = MemoRegExp(retrievedPost!.text ?? '');

        final ipfsCid = memoRegExp.extractIpfsCid();
        if (ipfsCid.isNotEmpty) {
          // Validate IPFS CID format
          expect(ipfsCid, matches(RegExp(r'^(Qm[1-9A-HJ-NP-Za-km-z]{44}|bafy[1-9A-HJ-NP-Za-km-z]{59})$')));
        }
      }
    });
  });
}

void _testMemoRegExpMethods(MemoRegExp memoRegExp, MemoModelPost post) {
  // Test all extraction methods
  final mediaUrls = memoRegExp.extractAllWhitelistedMediaUrls();
  final imageUrls = memoRegExp.extractAllWhitelistedImageUrls();
  final videoUrls = memoRegExp.extractAllWhitelistedVideoUrls();
  final ipfsCid = memoRegExp.extractIpfsCid();

  // Test boolean checks
  final hasMedia = memoRegExp.hasAnyWhitelistedMediaUrl();
  final hasImages = memoRegExp.hasAnyWhitelistedImageUrl();
  final hasVideos = memoRegExp.hasAnyWhitelistedVideoUrl();

  // Test specific domain extractions
  final imgurUrl = memoRegExp.extractValidImgurOrGiphyUrl();
  final youtubeUrl = memoRegExp.extractYoutubeUrl();
  final odyseeUrl = memoRegExp.extractOdyseeUrl();

  // Verify consistency between methods
  if (hasMedia) {
    expect(mediaUrls, isNotEmpty);
  }

  if (hasImages) {
    expect(imageUrls, isNotEmpty);
  }

  if (hasVideos) {
    expect(videoUrls, isNotEmpty);
  }

  // Test static methods
  final topics = MemoRegExp.extractTopics(post.text);
  final hashtags = MemoRegExp.extractHashtags(post.text);
  final allUrls = MemoRegExp.extractUrls(post.text);

  // Verify URL whitelisting
  for (final url in mediaUrls) {
    expect(MemoRegExp.isUrlWhitelisted(url), isTrue);
  }
}

Future<void> _validateSpecificPosts(List<MemoModelPost> scrapedPosts, PostService postService) async {
  // Find specific posts by their content patterns
  final imagePost = scrapedPosts.firstWhere((post) => post.text?.contains('imgur.com') ?? false, orElse: () => MemoModelPost(id: 'not-found'));

  if (imagePost.id != 'not-found') {
    final retrievedImagePost = await postService.getPostOnce(imagePost.id!);
    expect(retrievedImagePost, isNotNull);

    final memoRegExp = MemoRegExp(retrievedImagePost!.text ?? '');
    final imageUrls = memoRegExp.extractAllWhitelistedImageUrls();
    expect(imageUrls, isNotEmpty);
    expect(imageUrls.any((url) => url.contains('imgur.com')), isTrue);
  }

  final videoPost = scrapedPosts.firstWhere(
    (post) => post.text?.contains('youtube.com') ?? false || post.text!.contains('odysee.com') ?? false,
    orElse: () => MemoModelPost(id: 'not-found'),
  );

  if (videoPost.id != 'not-found') {
    final retrievedVideoPost = await postService.getPostOnce(videoPost.id!);
    expect(retrievedVideoPost, isNotNull);

    final memoRegExp = MemoRegExp(retrievedVideoPost!.text ?? '');
    final videoUrls = memoRegExp.extractAllWhitelistedVideoUrls();
    expect(videoUrls, isNotEmpty);
  }
}

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../firebase_options.dart';
import '../memo/firebase/post_service.dart';
import '../memo/model/memo_model_post.dart';
import '../memo/scraper/memo_post_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // scrapeTopics("");
  // runSequentialBatchJobDateCreated();
  // MemoPostService().scrapePostsPaginated(baseUrl: , initialOffset: initialOffset, cacheId: cacheId)
}

Future<void> runSequentialBatchJobDateCreated() async {
  // 1. Instantiate your PostService
  final PostService postService = PostService();

  // 2. Fetch all posts from the database using a one-time read.
  // This is a single, efficient database request.
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('posts').get();

    var memoPostService = MemoPostService();
    if (snapshot.docs.isEmpty) {
      print('No posts found to process.');
      return;
    }

    print('Starting sequential processing of ${snapshot.docs.length} posts...');

    int index = 0;
    // 3. Iterate over each document and perform the necessary calculations and saves.
    for (DocumentSnapshot doc in snapshot.docs) {
      index++;
      // a. Convert the Firestore document to your MemoModelPost.
      // This is necessary to work with your defined model methods.
      // Ensure your MemoModelPost.fromJson can handle the data.
      final Map<String, dynamic> docData = doc.data()! as Map<String, dynamic>;
      final MemoModelPost post = MemoModelPost.fromJson(docData)..id = doc.id;

      //SKIP ALL THESE THAT HAVE BEEN PROCESSED
      if (post.createdDateTime != null) continue;

      sleep(Duration(milliseconds: 1000)); //100ms worked well for some time then got me blocked

      MemoModelPost? p = await memoPostService.fetchAndParsePost(post.id!, filterOn: false);

      if (p != null)
        await postService.save(p, post.id!);
      else
        print("\n\nERROR NULL ON FETCH postId\n\n:" + post.id!);

      print("\n\nINDEX: $index\n\n");
      print('Processed and saved post: ${post.id}');
    }

    print('Batch job completed successfully!');
  } catch (e) {
    print('An error occurred during the batch job: $e');
  }
}
//
// Future<void> initData() async {
//   final String cacheId = "250825";
//   print("INFO: Starting initial data fetch...");
//
//   try {
//     var postService = MemoPostService();
//     PostService().getAllPostsStream().forEach((List<MemoModelPost> list) async {
//       int index = 0;
//       for (MemoModelPost post in list) {
//         index++;
//         //SKIP ALL THESE THAT HAVE BEEN PROCESSED
//         if (post.createdDateTime != null) continue;
//
//         //TODO use existing post object to update fields only?
//         MemoModelPost? p = await postService.fetchAndParsePost(post.id, filterOn: false);
//
//         sleep(Duration(seconds: 1));
//
//         if (p != null)
//           PostService().savePost(p);
//         else
//           print("\n\nERROR NULL ON FETCH postId\n\n:" + post.id);
//
//         print("\n\nINDEX: $index\n\n");
//       }
//     });

// int index = 0;
// for (int off = 525; off <= 1000; off += 25) {
//   var result = MemoCreatorService().fetchAndProcessCreators(["/most-actions?offset=$off"]);
//   List<MemoModelCreator> creators = await result;
//   for (var c in creators) {
//     CreatorService().saveCreator(c);
//     index++;
//   }
//   sleep(Duration(seconds: 1));
// }

// await scrapeTopics(cacheId);

// await scrapeTags(cacheId);

//     // Optional: You can inspect the results if your methods return values
//     // For example, if startScrapeTopics returned a list of topics:
//     // List<Topic> topics = results[0] as List<Topic>;
//     // print("INFO: Fetched ${topics.length} topics.");
//     print("INFO: All initial data fetched successfully.");
//   } catch (e, stackTrace) {
//     // Handle any error that occurred during any of the concurrent operations
//     print("ERROR: Failed to fetch initial data: $e");
//     print("Stack trace: $stackTrace");
//     // You might want to implement retry logic or show an error to the user
//   } finally {
//     // This will be called whether the operations succeeded or failed
//     print("INFO: Removing splash screen.");
//     FlutterNativeSplash.remove();
//   }
// }

Future<void> scrapeTopics(String cacheId) async {
  // int indexTopics = 0;
  // int indexPosts = 0;
  // List<MemoModelTopic> topics = [];
  // try {
  // await MemoScraperTopic().startScrapeTopics(topics, cacheId, 950, 200);
  // await MemoScraperTag().startScrapeTags(["/most-posts"], 500, 100, cacheId);
  // await MemoScraperTag().startScrapeTags(["/recent"], 500, 0, cacheId);
  // await MemoScraperTag().startScrapeTags(["/popular"], 500, 0, cacheId);
  // } finally {
  //   var topicService = TopicService();
  //   var postService = PostService();
  //   for (MemoModelTopic t in topics) {
  //     topicService.saveTopic(t);
  //     indexTopics++;
  //     for (MemoModelPost p in t.posts) {
  //       postService.savePost(p);
  //       indexPosts++;
  //     }
  //   }
  //
  //   print("TOTAL AMOUNT TOPICS $indexTopics");
  //   print("TOTAL AMOUNT POSTS $indexPosts");
  // }
}

// Future<void> scrapeTags(String cacheId) async {
//   int indexTags = 0;
//   int indexPosts = 0;
//   await MemoScraperTag().startScrapeTags(["/most-posts"], 125, 100, cacheId);
//
//   for (MemoModelTag t in MemoModelTag.tags) {
//     TagService().saveTag(t);
//     indexTags++;
//   }
//
//   for (MemoModelPost p in MemoModelPost.allPosts) {
//     PostService().savePost(p);
//     indexPosts++;
//   }
//
//   print("TOTAL AMOUNT TAGS $indexTags");
//   print("TOTAL AMOUNT POSTS $indexPosts");
// }

import 'package:dynamic_themes/dynamic_themes.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/resources/auth_method.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/widgets/post_card.dart';

import '../app_themes.dart';
import '../utils/snackbar.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  bool hasFilter(int i) {
    return true;
  }

  void signUserOut() async {
    // final GoogleSignIn googleSignIn = GoogleSignIn();
    // await FirebaseAuth.instance.signOut();
    // await googleSignIn.signOut();TODO SIGN OUT
    AuthChecker().logOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: true,
        toolbarHeight: 40,
        title: Text("Spend > Share > Inspire", style: TextStyle(fontFamily: "Open Sans")),

        // SvgPicture.asset(
        //   'assets/images/instagram.svg',
        //   color: blackColor,
        //   height: 50,
        // ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                DynamicTheme.of(context)?.setTheme(AppThemes.Dark);
              });
            },
            icon: Icon(Icons.color_lens_outlined),
          ),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    children: [
                      SimpleDialogOption(
                        onPressed: () {
                          onFilter(0);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.image_rounded),
                            const Spacer(),
                            const Text('IMAGES'),
                            Checkbox(
                              value: hasFilter(0),
                              onChanged: (value) {
                                onFilter(0);
                              },
                            ),
                          ],
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          onFilter(1);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.video_library_rounded),
                            const Spacer(),
                            const Text('VIDEOS'),
                            Checkbox(
                              value: hasFilter(1),
                              onChanged: (value) {
                                onFilter(1);
                              },
                            ),
                          ],
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          onFilter(2);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.tag_rounded),
                            const Spacer(),
                            const Text('HASHTAGS'),
                            Checkbox(
                              value: hasFilter(2),
                              onChanged: (value) {
                                onFilter(2);
                              },
                            ),
                          ],
                        ),
                      ),
                      SimpleDialogOption(
                        onPressed: () {
                          onFilter(3);
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.topic_rounded),
                            const Spacer(),
                            const Text('TOPICS'),
                            Checkbox(
                              value: hasFilter(3),
                              onChanged: (value) {
                                onFilter(3);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
              // signUserOut();
            },
            icon: Icon(Icons.filter_list, color: blackColor),
          ),
        ],
      ),
      body:
          // StreamBuilder(
          //     stream: FirebaseFirestore.instance
          //         .collection('posts')
          //         .orderBy('datePublished', descending: true)
          //         .snapshots(),
          //     builder: (context,
          //         AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
          //       if (snapshot.connectionState == ConnectionState.waiting) {
          //         return const Center(
          //           child: CircularProgressIndicator(),
          //         );
          //       } TODO FEED POSTS
          ListView.builder(
            itemCount: MemoModelPost.posts.length,
            itemBuilder: (context, index) => PostCard(MemoModelPost.posts[index]),
            // PostCard(snap: snapshot.data!.docs[index].data()),
          ),
      // })
    );
  }

  void onFilter(int i) {
    showSnackBar("filter$i", context);
  }
}

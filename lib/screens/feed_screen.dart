import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  void signUserOut() async {
    // final GoogleSignIn googleSignIn = GoogleSignIn();
    // await FirebaseAuth.instance.signOut();
    // await googleSignIn.signOut();TODO SIGN OUT
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: mobileBackgroundColor,
          centerTitle: false,
          title: SvgPicture.asset(
            'assets/images/instagram.svg',
            color: blackColor,
            height: 50,
          ),
          actions: [
            IconButton(
                onPressed: () {
                  signUserOut();
                },
                icon: Icon(
                  Icons.messenger_outline,
                  color: blackColor,
                ))
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
                itemCount: MemoModelPost.globalPosts.length,
                itemBuilder: (context, index) =>
                    PostCard(MemoModelPost.globalPosts[index]),
                // PostCard(snap: snapshot.data!.docs[index].data()),
              )
            // })
  );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/model/user.dart';
import 'package:instagram_clone1/provider/user_provider.dart';
import 'package:instagram_clone1/resources/firestore_method.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:instagram_clone1/widgets/comment_card.dart';
import 'package:provider/provider.dart';

import '../memomodel/memo_model_post.dart';

class CommentScreen extends StatefulWidget {
  // final snap;
  // const CommentScreen({super.key, required this.snap});
  const CommentScreen({super.key});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final TextEditingController commentController = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    commentController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //TODO GET USER DATA
    // final User user = Provider.of<UserProvider>(context).getUser;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: BackButton(color: Colors.black),
        title: Text(
          'Comments',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: mobileBackgroundColor,
      ),
      body:

      // StreamBuilder(
      //   stream: FirebaseFirestore.instance
      //       .collection('posts')
      //       .doc(widget.snap['postId'])
      //       .collection('comments')
      //       .orderBy('date',descending: true)
      //       .snapshots(),
      //   builder: (context,
      //       AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return const Center(
      //         child: CircularProgressIndicator(),
      //       );
      //     } TODO LOAD REPLIES TO SPECIFIC POST HERE

          ListView.builder(
            itemCount: 0,
            itemBuilder: (context, index) => CommentsCard(post: MemoModelPost.createDummy()),
            // itemCount: snapshot.data!.docs.length,
            // itemBuilder: (context, index) => CommentsCard(snap: snapshot.data!.docs[index].data(),),

      ),
      bottomSheet: SafeArea(
          child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10)
            .copyWith(bottom: 30),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              // backgroundImage: NetworkImage(user.photoURL),TODO PHOTO
              backgroundImage: NetworkImage("https://memo.cash/img/profilepics/17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ-128x128.jpg"),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    // enabledBorder: OutlineInputBorder(
                    // borderSide: BorderSide(
                    // width: 1, color: Colors.grey
                    // )
                    // ),
                    hintText: 'comment as xxxFELIZxxx', //TODO LOAD USER NAME
                  ),
                ),
              ),
            ),
            IconButton(
                onPressed: () async {

                  //TODO UPLOAD REPLY
                  print('post pressed');
                  // String res = await FireStoreMethods().postComment(
                  //     widget.snap['postId'],
                  //     commentController.text,
                  //     user.uid,
                  //     user.username,
                  //     user.photoURL);
                  showSnackBar("UPLOAD REPLY", context);

                  setState(() {
                    commentController.text = '';
                  });
                },
                icon: Icon(CupertinoIcons.paperplane))
          ],
        ),
      )),
    );
  }
}

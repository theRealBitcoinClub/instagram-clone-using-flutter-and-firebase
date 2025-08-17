import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/utils/imgur_utils.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:instagram_clone1/widgets/like_animtion.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';
import 'dart:ui' as ui;

import '../memomodel/memo_model_post.dart';

class PostCard extends StatefulWidget {
  final MemoModelPost post;
  // const PostCard({super.key, required this.snap});
  const PostCard(this.post, {super.key});

  @override
  State<PostCard> createState() => _PostCardState(post);
}

class _PostCardState extends State<PostCard> {
  bool isAnimating = false;
  MemoModelPost post;

  _PostCardState(this.post);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final model.User user = Provider.of<UserProvider>(context).getUser;
  
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16)
              .copyWith(right: 0),
          color: Colors.white,
          //headerbar
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(post.creator!.profileImage()),
                //TODO LOAD PROFILE IMAGE
                // backgroundImage: NetworkImage(widget.snap['profileImage']),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.creator!.name!,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const Spacer(),

                      Text("${post.age} - ${post.created}",
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => Dialog(
                              // backgroundColor: Colors.white10,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                              child: ListView(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shrinkWrap: true,
                                children: ["Tip", "Share", "Mute Post"]
                                    .map((e) => InkWell(
                                          onTap: () {
                                          //   TODO DELETEPOST LOLL
                                          // async {
                                          //   String res =
                                          //       await FireStoreMethods()
                                          //           .deletePost(
                                          //               widget.snap['postId']);
                                            showSnackBar("LOL", context);
                                            Navigator.pop(context);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12, horizontal: 16),
                                            child: Center(child: Text(e)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ));
                  },
                  icon: const Icon(
                    Icons.more_vert,
                  ))
            ],
          ),
        ),
        GestureDetector(
          onDoubleTap: () async {
            // TODO TIP POST WITH STANDARD TIP
            // FireStoreMethods().likePost(widget.snap['postId'],
            //     user.uid, widget.snap['likes']);
            setState(() {
              isAnimating = true;
            });
          },
          child: ZoomOverlay(
            modalBarrierColor: Colors.black12, // optional
            minScale: 0.5, // optional
            maxScale: 3.0, // optional
            twoTouchOnly: true,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.fastOutSlowIn,
            child: Stack(
              alignment: Alignment.center,
              children: [post.youtubeId != null 
                  ? YoutubePlayer(
                      controller: YoutubePlayerController(
                        initialVideoId: post.youtubeId!,
                        flags: YoutubePlayerFlags(
                          hideThumbnail: true,
                          hideControls: true,
                          mute: false,
                          autoPlay: false,
                        ),
                      ),
                      showVideoProgressIndicator: true,
                      onReady: () {
                        // print('Player is ready.');
                      },
                    )
                  :
                      // CachedNetworkImage(
                      //   imageUrl: post.imgurUrl == null ? "https://i.imgur.com/yhN4cfs.png" : post.imgurUrl!,
                      //   fit: BoxFit.cover,
                      //   placeholder: (context, url) => CircularProgressIndicator(),
                      //
                      //   imageBuilder: (ctx, builder) => onBuildImage(ctx, builder) ,
                      //   errorWidget: (context, url, error) => Icon(Icons.error),
                      //   errorListener: (error) => onErrorLoadImage(error),
                      // )
                      Image(
                              image: NetworkImage(post.imgurUrl == null ? "https://i.imgur.com/yhN4cfs.png" : post.imgurUrl!),
                              height: MediaQuery.of(context).size.height * 0.45,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => ImgurUtils.errorLoadImage(context, error, stackTrace),
                              loadingBuilder: (context, child, loadingProgress) => ImgurUtils.loadingImage(context, child, loadingProgress),
                            )

                    , //TODO HANDLE TEXT ONLY AND HANDLE TOPICS SO PEOPLE CAN REPLY
                      //TODO LET USERS INTERACT WITH HASHTAGS IN TEXT AND URLS IN TEXT
                      //TODO ADD MENTIONED HASHTAGS AS CLICKABLE BUTTONS BELOW POST
                      //TODO ADD TOPIC AS CLICKABLE BUTTON
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isAnimating ? 1 : 0,
                      child: LikeAnimation(
                        child: const Icon(
                          Icons.currency_bitcoin,
                          color: Color.fromRGBO(255, 255, 255, 1),
                          size: 130,
                        ),
                        isAnimating: isAnimating,
                        duration: const Duration(
                          milliseconds: 400,
                        ),
                        onEnd: () {
                          setState(() {
                            isAnimating = false;
                          });
                        },
                      ),
                    )
              ],
            ),
          ),
        ),

        //number of likes , description and number of comments
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  height: 8,
                ),

                Column(
                  children: <Widget>[
                    ExpandableText(post.text ?? "",
                      // widget.snap['discription'], TODO TEXT
                      prefixText: post.creator!.name,
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                      expandText: 'show more',
                      collapseText: 'show less',
                      maxLines: 5,
                      linkColor: Colors.blue,
                    ), Row(children: [(post.topic != null ?
                    TextButton(onPressed: () => onReplyTopic(post.topic!.url!), child: Text(post.topic!.header!))
                        : SizedBox())]),
                      // (post.hashtags.isNotEmpty ? post.hashtags.forEach((element) {
                      // TextButton(onPressed: () => onHashTag(element)
                      // ,child: Text(element)) //TODO SHOW BUTTON FOR EACH HASHTAG IN TEXT OR MAKE THE TEXT CLICKABLE ?
                    // }) : SizedBox())])
                  ],
                ),
          ]),
        )
      ]),
    );
  }

  void onReplyTopic(String s) {

  }

  // onErrorLoadImage(error) {
  //   print("object");
  // }
  //
  // Widget onBuildImage(BuildContext ctx, ImageProvider<Object> builder) {
  //   print("object");
  //   return builder;
  // }
}

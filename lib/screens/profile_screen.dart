import 'dart:typed_data';

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/widgets/profile_buttons.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../utils/imgur_utils.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // var userData = {};
  MemoModelPost post = MemoModelPost.createDummy();
  late MemoModelCreator creator;
  bool isFollowing = false;
  bool isLoading = false;
  int viewMode = 0; //0 - all, 1 - foto, 2 - video, 3 - text

  @override
  void initState() {
    super.initState();

    creator = post.creator!;
    
    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });

    // TODO LOAD USER BY ID
    // try {
    //   var userSnap = await FirebaseFirestore.instance
    //       .collection('users')
    //       .doc(widget.uid)
    //       .get();
    //
    //   // get post lENGTH
    //   var postSnap = await FirebaseFirestore.instance
    //       .collection('posts')
    //       .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
    //       .get();
    //
    //   postLen = postSnap.docs.length;
    //   userData = userSnap.data()!;
    //   followers = userSnap.data()!['followers'].length;
    //   following = userSnap.data()!['followings'].length;
    //   isFollowing = userSnap
    //       .data()!['followers']
    //       .contains(FirebaseAuth.instance.currentUser!.uid);
    //   setState(() {});
    // } catch (e) {
    //   showSnackBar(
    //     e.toString(),
    //     context,
    //   );
    // }
    setState(() {
      isLoading = false;
    });
  }

  Column buildStatColumn(String title, int count) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(15).copyWith(bottom: 0),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
              )
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              toolbarHeight: 50,
              backgroundColor: mobileBackgroundColor,
              centerTitle: false,
              title:
              Row(children: [
                // Text(
                //   creator.name!,
                //   // userData['username'],
                //   style: TextStyle(color: Colors.black, fontFamily: "Arial", fontSize: 12),
                // ),
                TextButton(
                    onPressed: () {
                      //TODO LAUNCH PROFILE ON MEMO WITH THAT ID
                      print("object");
                    },
                    child: Text(
                      creator.id!,
                      // userData['username'],
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                )
              ]),
              actions: [
                IconButton(
                    onPressed: () {
                      //TODO LAUNCH SIDESHIFT EXCHANGE
                      //TODO SHOW BCH DEPOSIT QR CODE
                      //TODO IMPLEMENT WALLETCONNECT
                    },
                    icon: Icon(
                      Icons.currency_exchange,
                      color: blackColor,
                    ))
              ],
            ),
            body: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16).copyWith(top: 0),
                    child: Row(
                      children: [
                        Container(
                          // padding: EdgeInsets.all(10).copyWith(top: 20),
                          child: CircleAvatar(
                            backgroundImage: NetworkImage(creator.profileImage()),
                            // backgroundImage: NetworkImage(userData['photoURL']),
                            radius: 40,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(padding: EdgeInsets.only(left: 25)),
                                  buildStatColumn('Posts', creator.actions!),
                                  buildStatColumn('followers', creator.followerCount!)
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    child: true
                                    //TODO LET THEM AUTO POST TO TWITTER, INSTA & FBOOK FROM MEMO
                                    //TODO FOLLOWING WITHOUT ANY EFFECT OR OFFER TO JUMP TO THEIR MEMO.CASH FOLLOWER FEED
                                    //TODO INTENSE MUTING TO FILTER FEED TO WHAT USER WANTS
                                    //TODO MUTED USERS CAN PAY TO BE UNMUTED
                                    //TODO IF USERS HAVE MORE MUTES THAN WEEKS OF AGE THEIR OUTREACH SUFFERS
                                    //TODO OUTREACH GOES DOWN IF AMOUNT OF POSTS GOES UP
                                    //TODO USER HAVE TO PAY TO HAVE HIGHER OUTREACH
                                    //TODO LET USER MUTE SPECIFIC POSTS, AFTER MUTING SAME USERS POST FOR X TIMES THE USER IS MUTED BUT STILL APPEARS ON SEARCH TO BE UNMUTED
                                    //TODO implement check user id is same user
                                    // FirebaseAuth
                                    //             .instance.currentUser!.uid ==
                                    //         widget.uid
                                        ? FollowButton(
                                            backgroundColor: Colors.transparent,
                                            borderColor: Colors.black,
                                            text: 'Edit Profile',
                                            //TODO Profile contains WIF and seed phrase for export
                                            //TODO ALLOW FOR MULTIPLE ACCOUNT SWITCHES HERE, SAVE MULTIPLE WIFS
                                            textColor: Colors.black)
                                        : isFollowing
                                            ? FollowButton(
                                                backgroundColor:
                                                    Colors.transparent,
                                                borderColor: Colors.black,
                                                text: 'unfollow',
                                                textColor: Colors.black)
                                            : FollowButton(
                                                backgroundColor: Colors.blue,
                                                borderColor: Colors.black,
                                                text: 'follow',
                                                textColor: Colors.black),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  //full name
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      creator.name!,
                      // userData['fullName'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  //bio
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20).copyWith(top: 10),
                    alignment: Alignment.bottomLeft,
                    child: ExpandableText(creator.profileText ?? "",
                      expandText: 'show more',
                      collapseText: 'show less',
                      maxLines: 3,
                      linkColor: Colors.blue,
                    ),
                  ),

                  new Divider(
                    color: Colors.grey.shade400,
                  ),

                  //posts or reels

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () {setState(() {
                            viewMode = 0;
                          });},
                          icon: Icon(
                            Icons.image_rounded,
                            size: 32,
                            color: activeOrNot(0),
                          )),
                      IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          onPressed: () {setState(() {
                            viewMode = 1;
                          });},
                          icon: Icon(
                            Icons.video_library_rounded,
                            size: 32,
                            color: activeOrNot(1),
                          )),
                      IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () {setState(() {
                            viewMode = 2;
                          });},
                          icon: Icon(Icons.tag_rounded,
                              size: 32, color : activeOrNot(2))),
                      IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () {setState(() {
                            viewMode = 3;
                          });},
                          icon: Icon(Icons.format_color_text_rounded,
                              size: 32, color: activeOrNot(3))),
                      IconButton(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          onPressed: () {setState(() {
                            viewMode = 4;
                          });},
                          icon: Icon(Icons.topic,
                              size: 32, color: activeOrNot(4)))
                    ],
                  ),
                  SizedBox(height: 447, child:
                        viewMode != 0 ?
                            ListView.builder(
                                itemCount:
                                    viewMode == 1 ? MemoModelPost.ytPosts.length :
                                    viewMode == 2 ? MemoModelPost.tagPosts.length :
                                    // viewMode == 3 ? MemoModelPost.urlPosts.length :
                                    viewMode == 4 ? MemoModelPost.topicPosts.length : 0,
                                itemBuilder: (context, index) {
                                    switch (viewMode) {
                                      case 1:
                                        return YoutubePlayer(
                                          controller: YoutubePlayerController(
                                              initialVideoId: MemoModelPost.ytPosts[index].youtubeId!,
                                              flags: YoutubePlayerFlags(
                                                hideThumbnail: true,
                                                hideControls: true,
                                                mute: false,
                                                autoPlay: false,
                                              )),
                                        );
                                      case 2:
                                        return buildTextBox(MemoModelPost.tagPosts, index);
                                      // case 3:
                                      //   return buildTextBox(MemoModelPost.urlPosts, index);
                                      case 4:
                                        return buildTextBox(MemoModelPost.topicPosts, index);
                                    }
                                    return null;
                                }
                            )
                        : GridView.builder(
                            itemBuilder:  (context, index) {
                                    return Image(image: NetworkImage(MemoModelPost.imgurPosts[index].imgurUrl!),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => ImgurUtils.errorLoadImage(context, error, stackTrace),
                                      loadingBuilder: (context, child, loadingProgress) => ImgurUtils.loadingImage(context, child, loadingProgress),
                                    );},
                            itemCount: MemoModelPost.imgurPosts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3))
                  )

                            //     } //TODO WHAT YA GONNA PRIORITIZE, TOPIC OR IMAGE, TOPIC OR VIDEO, TOPIC MUST BE PRIORITY AS IT OFFERS RESPONSE
                            //   });
                      ])
                  )
          );
  }

  SizedBox buildTextBox(List<MemoModelPost> posts, int index) => SizedBox(height: 100, child: Text(posts[index].text!));

  Color activeOrNot(int index) => viewMode == index ? Colors.grey.shade800 : Colors.grey.shade500;
}

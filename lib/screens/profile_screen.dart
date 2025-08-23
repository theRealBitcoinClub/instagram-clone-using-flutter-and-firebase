import 'dart:typed_data';

import 'package:clipboard/clipboard.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memomodel/memo_model_creator.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_creator.dart';
import 'package:instagram_clone1/resources/auth_method.dart';
import 'package:instagram_clone1/utils/colors.dart';
import 'package:instagram_clone1/widgets/profile_buttons.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../provider/user_provider.dart';
import '../utils/imgur_utils.dart';
import '../utils/snackbar.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MemoModelUser? user;
  bool showDefaultAvatar = false;
  bool isCashtoken145addressOrMemoDevPath0 = true;
  // MemoModelPost? post;
  late MemoModelCreator creator;
  bool isFollowing = false;
  bool isLoading = false;
  int viewMode = 0; //0 - all, 1 - foto, 2 - video, 3 - text

  @override
  void initState() {
    super.initState();

    creator = MemoModelCreator.createDummy();
    // ProviderUser provider = Provider.of<ProviderUser>(context);
    // user = provider.memoUser!;

    getData();
  }

  getData() async {
    setState(() {
      isLoading = true;
    });
    user = await MemoModelUser.createDummy(creator: creator);
    creator = await MemoScraperCreator().loadCreatorNameAndText(user!.profileIdMemoBch, nocache: true);
    // post = await MemoModelPost.createDummy(creator);
    setState(() {
      isLoading = false;
    });
    String refreshBch = await user!.refreshBalanceDevPath145();
    String refreshTokens = await user!.refreshBalanceTokens();
    String refreshMemo = await user!.refreshBalanceDevPath0();
    setState(() {
      // showSnackBar("refreshBCH", context);
    });
  }

  Column buildStatColumn(String title, String count) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(15).copyWith(bottom: 0),
          child: Column(
            children: [
              Text(
                count,
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
                      // print("object");
                      showSnackBar("launch memo profile url or register on memo if 404 on profile", context);
                    },
                    child: Text(
                      user!.profileIdMemoBch,
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
                      showBchQR();
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
                          child: 
                          showDefaultAvatar ?
                          CircleAvatar(radius: 40,
                              backgroundImage: AssetImage("assets/images/default_profile.png"),)
                          :
                          CircleAvatar(
                            onBackgroundImageError: (exception, stackTrace) {
                              setState(() {
                                showDefaultAvatar = true;
                              });
                            },
                            backgroundImage: NetworkImage(user!.profileImage()),
                            // backgroundImage: NetworkImage(userData['photoURL']),
                            radius: 40,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(padding: EdgeInsets.only(left: 30)),
                                  buildStatColumn('BCH', user!.balanceBchDevPath145),
                                  Spacer(),
                                  buildStatColumn('Token', user!.balanceCashtokensDevPath145),
                                  Spacer(),
                                  buildStatColumn('Memo', user!.balanceBchDevPath0Memo),
                                  Padding(padding: EdgeInsets.only(right: 30))
                                  //TODO SHOW SATOSHIS NOT FOLLOWERCOUNT
                                  //TODO SHOW TOKEN AMOUNT
                                  //TODO SHOW CTSATS, MEMOSATS
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                      onTap: () {
                                        onProfileSettings();
                                      },
                                      child: Container(
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
                                  ))
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildIconButton(0, Icons.image_rounded),
                      buildIconButton(1, Icons.video_library_rounded),
                      buildIconButton(2, Icons.tag_rounded),
                      buildIconButton(4, Icons.topic)
                    ],
                  ),
                  SizedBox(height: 447, child:
                        viewMode != 0 ?
                            ListView.builder(
                                itemCount:
                                    viewMode == 1 ? MemoModelPost.ytPosts.length :
                                    viewMode == 2 ? MemoModelPost.hashTagPosts.length :
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
                                        return buildTextBox(MemoModelPost.hashTagPosts, index);
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
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => ImgurUtils.errorLoadImage(context, error, stackTrace),
                                      loadingBuilder: (context, child, loadingProgress) => ImgurUtils.loadingImage(context, child, loadingProgress),
                                    );
                            },
                            itemCount: MemoModelPost.imgurPosts.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3))
                  )

                            //     } //TODO WHAT YA GONNA PRIORITIZE, TOPIC OR IMAGE, TOPIC OR VIDEO, TOPIC MUST BE PRIORITY AS IT OFFERS RESPONSE
                            //   });
                      ])
                  )
          );
  }

  IconButton buildIconButton(index, icon) {
    return IconButton(
                        padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
                        onPressed: () {setState(() {
                          viewMode = index;
                        });},
                        icon: Icon(
                          icon,
                          size: 36,
                          color: activeOrNot(index),
                        ));
  }

  SizedBox buildTextBox(List<MemoModelPost> posts, int index) => SizedBox(height: 100, child: Text(posts[index].text!));

  Color activeOrNot(int index) => viewMode == index ? Colors.grey.shade800 : Colors.grey.shade500;

  void onProfileSettings() {
    showDialog(
        context: context,
        builder: (ctxDialog) {
          return SimpleDialog(
              title: const Row(
                  children: [
                    const Icon(Icons.settings),
                    const Spacer(),
                    const Text("PROFILE SETTINGS")]),
              children: [
                settingsOption(Icons.verified_user_outlined, "NAME", ctxDialog, () {
                  showSnackBar("set profile name", context);
                }),
                settingsOption(Icons.verified_outlined, "DESCRIPTION", ctxDialog, () {
                  showSnackBar("set profile description", context);
                }),
                settingsOption(Icons.account_circle_outlined, "IMGUR", ctxDialog, () {
                  showSnackBar("set profile IMGUR", context);
                }),
                settingsOption(Icons.logout_outlined, "LOGOUT", ctxDialog, () {
                  AuthChecker().logOut(context);
                }),
                settingsOption(Icons.backup_outlined, "BACKUP", ctxDialog, () {
                  copyToClip(user!.mnemonic, context);
                }),
                settingsOption(Icons.link_rounded, "TWITTER", ctxDialog, () {
                  showSnackBar("link twitter account", context);
                }),
              ]);
        });
  }

  SimpleDialogOption settingsOption(IconData ico, String txt, BuildContext ctxDialog, onSelect) {
    return SimpleDialogOption(
                padding: const EdgeInsets.all(20),
                onPressed: () async {
                  onSelect();
                  Navigator.of(ctxDialog).pop();
                },
                child: Row(children: [
                  Icon(ico),
                  const Spacer(),
                  Text(txt)
                ]),
              );
  }

  void showBchQR() {
    showDialog(context: context, builder: (dialogCtx) {
      return SimpleDialog(
        children: [
          isCashtoken145addressOrMemoDevPath0
              ?
          qrCode(user!.bchAddressCashtokenAware, "cashtoken", dialogCtx)
              :
          qrCode(user!.legacyAddressMemoBchAsCashaddress, "memo-128x128", dialogCtx)
        ]
            //TODO observe balance change of wallet, show snackbar on deposit
      );
    });
  }

  SimpleDialogOption qrCode(String address, String img, BuildContext dialogCtx) {
    return SimpleDialogOption(
              onPressed: () {
                copyToClip(address, dialogCtx);
                Navigator.of(dialogCtx).pop();
        }, child: Column(children: [
                    PrettyQrView.data(decoration:
                          PrettyQrDecoration(image: PrettyQrDecorationImage(image:
                          AssetImage("assets/images/$img.png"))),
                        data: address
                    ), GestureDetector(
                          onTap: () {
                            setState(() {
                              isCashtoken145addressOrMemoDevPath0 = !isCashtoken145addressOrMemoDevPath0;
                            });
                            Navigator.of(dialogCtx).pop();
                            showBchQR();
                          },
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(50),
                            child: Text(
                              isCashtoken145addressOrMemoDevPath0 
                                  ? "SHOW MEMO QR"
                                  : "SHOW CASHONIZE QR",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: blueColor),
                            ),
                          ),
                        )
                  ])
    );
  }

  Future<void> copyToClip(String txt, ctx) async {
    await FlutterClipboard.copyWithCallback(
      text: txt,
      onSuccess: () {
        showSnackBar(txt, ctx);

      },
      onError: (error) {
        showSnackBar('Copy failed: $error', ctx);
      },
    );
  }
}

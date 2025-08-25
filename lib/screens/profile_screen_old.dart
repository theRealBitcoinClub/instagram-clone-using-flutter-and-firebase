// import 'package:clipboard/clipboard.dart';
// import 'package:expandable_text/expandable_text.dart';
// import 'package:flutter/material.dart';
// import 'package:mahakka/memomodel/memo_model_creator.dart';
// import 'package:mahakka/memomodel/memo_model_post.dart';
// import 'package:mahakka/memomodel/memo_model_user.dart';
// import 'package:mahakka/memoscraper/memo_creator_service.dart';
// import 'package:mahakka/resources/auth_method.dart';
// import 'package:mahakka/utils/colors.dart';
// import 'package:mahakka/widgets/profile_buttons.dart';
// import 'package:pretty_qr_code/pretty_qr_code.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// import '../utils/imgur_utils.dart';
// import '../utils/snackbar.dart';
//
// class ProfileScreen extends StatefulWidget {
//   final String uid;
//
//   const ProfileScreen({Key? key, required this.uid}) : super(key: key);
//
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen> {
//   MemoModelUser? user;
//   bool showDefaultAvatar = false;
//   bool toggleAddressType = true;
//
//   // MemoModelPost? post;
//   late MemoModelCreator creator;
//   bool isFollowing = false;
//   bool isLoading = false;
//   bool isRefreshing = false;
//   int viewMode = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     // ProviderUser provider = Provider.of<ProviderUser>(context);
//     // user = provider.memoUser!;
//
//     getData();
//   }
//
//   // getData() async {
//   //   setState(() {
//   //     isLoading = true;
//   //   });
//   //   user = await MemoModelUser.getUser();
//   //   creator = MemoModelCreator.createDummy(id: user!.profileIdMemoBch);
//   //   // post = await MemoModelPost.createDummy(creator);
//   //   setState(() {
//   //     isLoading = false;
//   //   });
//   //   setState(() {
//   //     isRefreshing = true;
//   //   });
//   //   creator = await MemoCreatorService().fetchCreatorDetails(creator, noCache: true);
//   //   String refreshBch = await user!.refreshBalanceDevPath145();
//   //   String refreshTokens = await user!.refreshBalanceTokens();
//   //   String refreshMemo = await user!.refreshBalanceDevPath0();
//   //   setState(() {
//   //     isRefreshing = false;
//   //     if (refreshBch != "success")
//   //       showSnackBar("You haz no BCH, please deposit if you want to publish and earn token", context);
//   //     if (refreshTokens != "success")
//   //       showSnackBar("You haz no tokens, deposit tokens to post/like/reply with discount", context);
//   //     if (refreshMemo != "success")
//   //       showSnackBar("You haz no memo balance, likes/replies of OG memo posts will not send tips", context);
//   //   });
//   // }
//
//   Future<void> getData() async {
//     // Return Future<void>
//     if (!mounted) return; // Check if widget is still in the tree
//     setState(() {
//       isLoading = true;
//       isRefreshing = false; // Potentially reset refreshing state here if needed
//     });
//
//     try {
//       // Initial data fetch
//       final localUser = await MemoModelUser.getUser();
//       if (!mounted) return;
//
//       // Create a dummy creator first, then update isLoading
//       // This allows the screen to show something quicker if getUser() is fast
//       final initialCreator = MemoModelCreator.createDummy(id: localUser.profileIdMemoBch);
//       setState(() {
//         user = localUser;
//         creator = initialCreator;
//         isLoading = false; // Stop initial loading indicator
//         isRefreshing = true; // Start refresh indicator for subsequent calls
//       });
//
//       // Background data refresh
//       // These can potentially run in parallel if independent
//       final results = await Future.wait([
//         MemoCreatorService().fetchCreatorDetails(initialCreator, noCache: true),
//         localUser.refreshBalanceDevPath145(),
//         localUser.refreshBalanceTokens(),
//         localUser.refreshBalanceDevPath0(),
//       ]);
//
//       if (!mounted) return;
//
//       final refreshedCreator = results[0] as MemoModelCreator;
//       final refreshBch = results[1] as String;
//       final refreshTokens = results[2] as String;
//       final refreshMemo = results[3] as String;
//
//       setState(() {
//         creator = refreshedCreator; // Update with details
//         isRefreshing = false;
//       });
//
//       // Show SnackBars after final state update
//       if (refreshBch != "success") {
//         showSnackBar("You haz no BCH...", context);
//       }
//       if (refreshTokens != "success") {
//         showSnackBar("You haz no tokens...", context);
//       }
//       if (refreshMemo != "success") {
//         showSnackBar("You haz no memo balance...", context);
//       }
//     } catch (e, s) {
//       if (!mounted) return;
//       // _logError("Error in getData", e, s); // Add logging
//       setState(() {
//         isLoading = false;
//         isRefreshing = false;
//         // Optionally show an error message to the user
//       });
//       showSnackBar("Failed to load profile data.", context);
//     }
//   }
//
//   Column buildStatColumn(String title, String count) {
//     return Column(
//       children: [
//         Padding(
//           padding: const EdgeInsets.fromLTRB(0, 15, 0, 0), // const
//           child: Column(
//             children: [
//               Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), // const style
//               Text(
//                 title,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400), // const style
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return isLoading
//         ? const Center(child: CircularProgressIndicator())
//         : Scaffold(
//             appBar: AppBar(
//               toolbarHeight: 50,
//               backgroundColor: mobileBackgroundColor,
//               centerTitle: false,
//               title: Row(
//                 children: [
//                   TextButton(
//                     onPressed: () {
//                       //TODO LAUNCH PROFILE ON MEMO WITH THAT ID
//                       showSnackBar("launch memo profile url or register on memo if 404 on profile", context);
//                     },
//                     child: Text(user!.profileIdMemoBch, style: TextStyle(color: Colors.grey, fontSize: 12)),
//                   ),
//                 ],
//               ),
//               actions: [
//                 IconButton(
//                   onPressed: () {
//                     //TODO ADD LINK TO SWAP BTC TO BCH
//                     showBchQR();
//                   },
//                   icon: Icon(Icons.currency_exchange, color: blackColor),
//                 ),
//               ],
//             ),
//             body: SafeArea(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   isRefreshing ? SizedBox(height: 1, child: LinearProgressIndicator()) : SizedBox(),
//                   Container(
//                     height: 265,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.max,
//                       children: [
//                         createTopDetails(),
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 20),
//                           alignment: Alignment.bottomLeft,
//                           child: Text(creator.name, style: TextStyle(fontWeight: FontWeight.bold)),
//                         ),
//                         Container(
//                           padding: EdgeInsets.symmetric(horizontal: 20).copyWith(top: 10),
//                           alignment: Alignment.bottomLeft,
//                           child: ExpandableText(
//                             creator.profileText,
//                             expandText: 'show more',
//                             collapseText: 'show less',
//                             maxLines: 3,
//                             linkColor: Colors.blue,
//                           ),
//                         ),
//                         Divider(color: Colors.grey.shade300),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             buildIconButton(0, Icons.image_rounded),
//                             buildIconButton(1, Icons.video_library_rounded),
//                             buildIconButton(2, Icons.tag_rounded),
//                             buildIconButton(4, Icons.topic),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   Container(
//                     height: 480,
//                     child: viewMode != 0
//                         ? buildListView()
//                         : GridView.builder(
//                             itemBuilder: (context, index) {
//                               MemoModelPost post = MemoModelPost.imgurPosts[index];
//                               final img = Image(
//                                 image: NetworkImage(post.imgurUrl!),
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) =>
//                                     ImgurUtils.errorLoadImage(context, error, stackTrace),
//                                 loadingBuilder: (context, child, loadingProgress) =>
//                                     ImgurUtils.loadingImage(context, child, loadingProgress),
//                               );
//                               return GestureDetector(
//                                 onDoubleTap: () {
//                                   showDialog(
//                                     context: context,
//                                     builder: (dialogCtx) {
//                                       return SimpleDialog(
//                                         title: Row(
//                                           children: [
//                                             CircleAvatar(backgroundImage: NetworkImage(post.creator!.profileImage())),
//                                             SizedBox(width: 10),
//                                             Text(post.creator!.name),
//                                           ],
//                                         ),
//                                         children: [
//                                           img,
//                                           SizedBox(
//                                             height: post.text == null || post.text!.isEmpty ? 0 : 100,
//                                             child: Padding(
//                                               padding: EdgeInsetsGeometry.all(20),
//                                               child: Text(post.text ?? "", maxLines: 4),
//                                             ),
//                                           ),
//                                         ],
//                                       );
//                                     },
//                                   );
//                                 },
//                                 child: img,
//                               );
//                             },
//                             itemCount: MemoModelPost.imgurPosts.length,
//                             gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
//                           ),
//                   ),
//
//                   //     } //TODO WHAT YA GONNA PRIORITIZE, TOPIC OR IMAGE, TOPIC OR VIDEO, TOPIC MUST BE PRIORITY AS IT OFFERS RESPONSE
//                   //   });
//                 ],
//               ),
//             ),
//           );
//   }
//
//   ListView buildListView() {
//     return ListView.builder(
//       itemCount: viewMode == 1
//           ? MemoModelPost.ytPosts.length
//           : viewMode == 2
//           ? MemoModelPost.hashTagPosts.length
//           :
//             // viewMode == 3 ? MemoModelPost.urlPosts.length :
//             viewMode == 4
//           ? MemoModelPost.topicPosts.length
//           : 0,
//       itemBuilder: (context, index) {
//         switch (viewMode) {
//           case 1:
//             var ytPost = MemoModelPost.ytPosts[index];
//             return Container(
//               height: 369,
//               child: Column(
//                 children: [
//                   YoutubePlayer(
//                     controller: YoutubePlayerController(
//                       initialVideoId: ytPost.youtubeId!,
//                       flags: YoutubePlayerFlags(hideThumbnail: true, hideControls: true, mute: false, autoPlay: false),
//                     ),
//                   ),
//                   Padding(
//                     padding: EdgeInsetsGeometry.all(10),
//                     child: SizedBox(
//                       height: 116,
//                       child: Column(
//                         children: [
//                           Text(ytPost.text ?? "", maxLines: 4),
//                           Divider(),
//                           Text("^^^   ${ytPost.creator!.name}   ^^^", style: TextStyle(fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           case 2:
//             return buildTextBox(MemoModelPost.hashTagPosts[index]);
//           // case 3:
//           //   return buildTextBox(MemoModelPost.urlPosts, index);
//           case 4:
//             return buildTextBox(MemoModelPost.topicPosts[index]);
//         }
//         return null;
//       },
//     );
//   }
//
//   Padding createTopDetails() {
//     return Padding(
//       padding: const EdgeInsets.all(16).copyWith(top: 0),
//       child: Row(
//         children: [
//           Container(
//             child: showDefaultAvatar
//                 ? CircleAvatar(radius: 40, backgroundImage: AssetImage("assets/images/default_profile.png"))
//                 : CircleAvatar(
//                     onBackgroundImageError: (exception, stackTrace) {
//                       setState(() {
//                         showDefaultAvatar = true;
//                       });
//                     },
//                     backgroundImage: NetworkImage(user!.profileImage()),
//                     radius: 40,
//                   ),
//           ),
//           Expanded(
//             child: Column(
//               children: [
//                 Row(
//                   children: [
//                     Padding(padding: EdgeInsets.only(left: 30)),
//                     buildStatColumn('BCH', user!.balanceBchDevPath145),
//                     Spacer(),
//                     buildStatColumn('Token', user!.balanceCashtokensDevPath145),
//                     Spacer(),
//                     buildStatColumn('Memo', user!.balanceBchDevPath0Memo),
//                     Padding(padding: EdgeInsets.only(right: 30)),
//                   ],
//                 ),
//                 buildSettingsButton(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Column buildSettingsButton() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         GestureDetector(
//           onTap: () {
//             onProfileSettings();
//           },
//           child: Container(
//             child: SettingsButton(
//               backgroundColor: Colors.transparent,
//               borderColor: Colors.black,
//               text: 'Edit Profile',
//               textColor: Colors.black,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   IconButton buildIconButton(index, icon) {
//     return IconButton(
//       padding: EdgeInsets.fromLTRB(20, 10, 20, 20),
//       onPressed: () {
//         setState(() {
//           viewMode = index;
//         });
//       },
//       icon: Icon(icon, size: 36, color: activeOrNot(index)),
//     );
//   }
//
//   SizedBox buildTextBox(MemoModelPost post) {
//     return SizedBox(
//       height: 176,
//       child: Padding(
//         padding: EdgeInsetsGeometry.all(20),
//         child: Column(
//           children: [
//             Row(children: [Text(post.creator!.name), Spacer(), Text(post.created!)]),
//             Divider(),
//             Text(post.text!),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Color activeOrNot(int index) => viewMode == index ? Colors.grey.shade800 : Colors.grey.shade500;
//
//   void onProfileSettings() {
//     showDialog(
//       context: context,
//       builder: (ctxDialog) {
//         return SimpleDialog(
//           title: const Row(children: [const Icon(Icons.settings), const Spacer(), const Text("PROFILE SETTINGS")]),
//           children: [
//             settingsOption(Icons.verified_user_outlined, "NAME", ctxDialog, () {
//               // Memo
//               showSnackBar("set profile name", context);
//             }),
//             settingsOption(Icons.verified_outlined, "DESCRIPTION", ctxDialog, () {
//               showSnackBar("set profile description", context);
//             }),
//             settingsOption(Icons.account_circle_outlined, "IMGUR", ctxDialog, () {
//               showSnackBar("set profile IMGUR", context);
//             }),
//             settingsOption(Icons.logout_outlined, "LOGOUT", ctxDialog, () {
//               AuthChecker().logOut(context);
//             }),
//             settingsOption(Icons.backup_outlined, "BACKUP", ctxDialog, () {
//               copyToClip(user!.mnemonic, context);
//             }),
//             settingsOption(Icons.link_rounded, "TWITTER", ctxDialog, () {
//               showSnackBar("link twitter account", context);
//             }),
//           ],
//         );
//       },
//     );
//   }
//
//   SimpleDialogOption settingsOption(IconData ico, String txt, BuildContext ctxDialog, onSelect) {
//     return SimpleDialogOption(
//       padding: const EdgeInsets.all(20),
//       onPressed: () async {
//         onSelect();
//         Navigator.of(ctxDialog).pop();
//       },
//       child: Row(children: [Icon(ico), const Spacer(), Text(txt)]),
//     );
//   }
//
//   void showBchQR() {
//     showDialog(
//       context: context,
//       builder: (dialogCtx) {
//         return SimpleDialog(
//           children: [
//             toggleAddressType
//                 ? qrCode(user!.bchAddressCashtokenAwareCtFormat, "cashtoken", dialogCtx)
//                 : qrCode(user!.legacyAddressMemoBchAsCashaddress, "memo-128x128", dialogCtx),
//           ],
//           //TODO observe balance change of wallet, show snackbar on deposit
//         );
//       },
//     );
//   }
//
//   SimpleDialogOption qrCode(String address, String img, BuildContext dialogCtx) {
//     return SimpleDialogOption(
//       onPressed: () {
//         copyToClip(address, dialogCtx);
//         Navigator.of(dialogCtx).pop();
//       },
//       child: Column(
//         children: [
//           PrettyQrView.data(
//             decoration: PrettyQrDecoration(image: PrettyQrDecorationImage(image: AssetImage("assets/images/$img.png"))),
//             data: address,
//           ),
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 toggleAddressType = !toggleAddressType;
//               });
//               Navigator.of(dialogCtx).pop();
//               showBchQR();
//             },
//             child: Container(
//               alignment: Alignment.center,
//               padding: const EdgeInsets.all(50),
//               child: Text(
//                 toggleAddressType ? "SHOW MEMO QR" : "SHOW CASHONIZE QR",
//                 style: const TextStyle(fontWeight: FontWeight.bold, color: blueColor),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> copyToClip(String txt, ctx) async {
//     await FlutterClipboard.copyWithCallback(
//       text: txt,
//       onSuccess: () {
//         showSnackBar(txt, ctx);
//       },
//       onError: (error) {
//         showSnackBar('Copy failed: $error', ctx);
//       },
//     );
//   }
// }

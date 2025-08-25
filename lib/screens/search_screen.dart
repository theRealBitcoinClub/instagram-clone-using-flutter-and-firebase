// import 'package:flutter/material.dart';
// import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
// import 'package:mahakka/memomodel/memo_model_post.dart';
// import 'package:mahakka/screens/profile_screen.dart';
// import 'package:mahakka/utils/colors.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});
//
//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }
//
// class _SearchScreenState extends State<SearchScreen> {
//   final TextEditingController searchController = TextEditingController();
//   bool isShowUsers = false;
//   bool isLoading = true;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: mobileBackgroundColor,
//         title: Form(
//           child: TextFormField(
//             controller: searchController,
//             decoration: const InputDecoration(labelText: 'Search for a user...'),
//             onFieldSubmitted: (String _) {
//               setState(() {
//                 isShowUsers = true;
//               });
//             },
//           ),
//         ),
//       ),
//       body: isShowUsers
//           ? FutureBuilder(
//               future: null,
//               // TODO SEARCH USERS BY NAME
//               // FirebaseFirestore.instance
//               //     .collection('users')
//               //     .where(
//               //       'username',
//               //       isGreaterThanOrEqualTo: searchController.text,
//               //     )
//               //     .get(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 return ListView.builder(
//                   itemCount: (snapshot.data! as dynamic).docs.length,
//                   itemBuilder: (context, index) {
//                     return InkWell(
//                       onTap: () {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(
//                             builder: (context) => ProfileScreen(
//                               //TODO USER ID OF SEARCHED USER
//                               // uid: (snapshot.data! as dynamic).docs[index]
//                               //     ['uid']
//                               uid: "17ZY9npgMXstBGXHDCz1umWUEAc9ZU1hSZ",
//                             ),
//                           ),
//                         );
//                       },
//                       child: ListTile(
//                         leading: CircleAvatar(
//                           backgroundImage: NetworkImage((snapshot.data! as dynamic).docs[index]['photoURL']),
//                           radius: 16,
//                         ),
//                         title: Text((snapshot.data! as dynamic).docs[index]['username']),
//                       ),
//                     );
//                   },
//                 );
//               },
//             )
//           : FutureBuilder(
//               future: null,
//               // TODO LOAD POSTS MATCHING NAME, TOPIC OR HASHTAG
//               // FirebaseFirestore.instance.collection('posts').get(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   const Center(child: CircularProgressIndicator());
//                 }
//
//                 return MasonryGridView.builder(
//                   crossAxisSpacing: 4,
//                   mainAxisSpacing: 4,
//                   gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
//                   itemCount: MemoModelPost.allPosts.length,
//                   itemBuilder: (context, index) {
//                     return ClipRRect(
//                       child: MemoModelPost.allPosts[index].youtubeId != null
//                           ? YoutubePlayer(
//                               controller: YoutubePlayerController(
//                                 initialVideoId: MemoModelPost.allPosts[index].youtubeId!,
//                                 flags: YoutubePlayerFlags(
//                                   hideThumbnail: true,
//                                   hideControls: true,
//                                   mute: false,
//                                   autoPlay: false,
//                                 ),
//                               ),
//                               showVideoProgressIndicator: true,
//                               onReady: () {
//                                 // print('Player is ready.');
//                               },
//                             )
//                           : MemoModelPost.allPosts[index].imgurUrl != null
//                           ? Image.network(MemoModelPost.allPosts[index].imgurUrl!)
//                           : Text(MemoModelPost.allPosts[index].text!),
//                     );
//                   },
//                 );
//               },
//             ),
//     );
//   }
// }

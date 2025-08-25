// import 'package:mahakka/memomodel/memo_model_post.dart';
//
// class Post {
//   final String discription;
//   final String uid;
//   final String username;
//   final String postId;
//   final datePublished;
//   final String postURL;
//   final String profileImage;
//   final  likes;
//
//   Post({
//     required this.discription,
//     required this.uid,
//     required this.username,
//     required this.postId,
//     required this.datePublished,
//     required this.postURL,
//     required this.profileImage,
//     required this.likes,
//   });
//
//
// static Post fromSnap(MemoModelPost post) {
//     return Post(
//       discription: post.text!,
//       uid: post.creator!.id!,
//       username: post.creator!.name!,
//       postId: post.txHash!,
//       datePublished: post.created!,
//       postURL: "https://memo.cash/post/" + post.txHash!,
//       profileImage: "https://memo.cash/img/profilepics/" + post.creator!.id! + "-128x128.jpg",
//       likes: post.likeCounter,
//     );
//   }
//
//   Map<String, dynamic> toJason() => {
//         'discription': discription,
//         'uid': uid,
//         'username': username,
//         'postId': postId,
//         'datePublished': datePublished,
//         'postURL': postURL,
//         'profileImage': profileImage,
//         'likes': likes,
//       };
// }

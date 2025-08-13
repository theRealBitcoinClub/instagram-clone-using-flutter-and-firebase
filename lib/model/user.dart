import 'package:instagram_clone1/memomodel/memo_model_user.dart';

class User {
  final String email;
  final String uid;
  final String fullName;
  final String username;
  final String password;
  final List followers;
  final List followings;
  final String photoURL;

  User({
    required this.email,
    required this.uid,
    required this.fullName,
    required this.username,
    required this.password,
    required this.followers,
    required this.followings,
    required this.photoURL,
  });


static User fromSnap(MemoModelUser user) {
    // var snapshot = snap.data() as Map<String, dynamic>;

    return User(
      username: user.creator!.name!,
      password: user.wif!,
      uid: user.creator!.id!,
      email: "fdfdsf@fdsfs.com",
      photoURL: "photourl",
      fullName: "full name",
      followers: [],
      followings: [],
    );
  }

  Map<String, dynamic> toJason() => {
        'email': email,
        'uid': uid,
        'fullName': fullName,
        'username': username,
        'password': password,
        'followers': followers,
        'followings': followings,
        'photoURL': photoURL,
      };
}

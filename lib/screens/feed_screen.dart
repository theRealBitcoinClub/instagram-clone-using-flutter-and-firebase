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

  void signOut() async {
    AuthChecker().logOut(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: mobileBackgroundColor,
        centerTitle: true,
        toolbarHeight: 50,
        title: Text("mahakka.com", style: TextStyle(fontFamily: "Open Sans")),
        // actions: [buildMenuTheme(context), buildMenuFilter(context)],
      ),
      body: ListView.builder(
        itemCount: MemoModelPost.allPosts.length,
        itemBuilder: (context, index) => PostCard(MemoModelPost.allPosts[index]),
      ),
      // })
    );
  }

  IconButton buildMenuFilter(BuildContext context) {
    return IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return SimpleDialog(
              children: [
                //TODO change icon if filter is on or off
                buildFilterOption(0, "IMAGES", Icons.image_not_supported),
                buildFilterOption(1, "VIDEOS", Icons.video_library_rounded),
                buildFilterOption(2, "HASHTAGS", Icons.tag_rounded),
                buildFilterOption(3, "TOPICS", Icons.topic_rounded),
              ],
            );
          },
        );
        // signUserOut();
      },
      icon: Icon(Icons.filter_list, color: blackColor),
    );
  }

  IconButton buildMenuTheme(BuildContext context) {
    return IconButton(
      onPressed: () {
        setState(() {
          DynamicTheme.of(context)?.setTheme(AppThemes.Dark);
        });
      },
      icon: Icon(Icons.color_lens_outlined),
    );
  }

  SimpleDialogOption buildFilterOption(int index, String text, icon) {
    return SimpleDialogOption(
      onPressed: () {
        onFilter(index);
      },
      child: Row(
        children: [
          Icon(icon),
          const Spacer(),
          Text(text),
          Checkbox(
            value: hasFilter(0),
            onChanged: (value) {
              onFilter(0);
            },
          ),
        ],
      ),
    );
  }

  void onFilter(int i) {
    showSnackBar("filter$i", context);
  }
}

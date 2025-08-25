import 'dart:async';

import 'package:clipboard/clipboard.dart';
import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:instagram_clone1/memobase/memo_accountant.dart';
import 'package:instagram_clone1/memomodel/memo_model_post.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/widgets/memo_confetti.dart';
import 'package:instagram_clone1/widgets/textfield_input.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../views_taggable/view_models/search_view_model.dart';
import '../views_taggable/widgets/comment_text_field.dart';
import '../views_taggable/widgets/search_result_overlay.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> with TickerProviderStateMixin {
  final TextEditingController imgurCtrl = TextEditingController();
  final TextEditingController youtubeCtrl = TextEditingController();
  bool isLoading = false;
  String validImgur = "";
  String validVideo = "";
  MemoModelUser? user;

  @override
  void initState() {
    super.initState();
    initImgurListener();
    initYouTubeListener();
    initStateTagger();
    checkClipboardHasValidYouTubeOrImgur();
    loadUser();
  }

  void loadUser() async {
    user = await MemoModelUser.getUser();
  }

  Future<void> checkClipboardHasValidYouTubeOrImgur() async {
    if (await FlutterClipboard.hasData()) {
      String url = await FlutterClipboard.paste();
      String validYtUrl = YoutubePlayer.convertUrlToId(url) ?? "";
      if (validYtUrl.isNotEmpty) {
        validVideo = validYtUrl;
        youtubeCtrl.text = url;
      } else {
        validImgur = extractValidImgurUrl(url);
        imgurCtrl.text = validImgur;
      }
    }
    setState(() {});
  }

  String extractValidImgurUrl(String url) {
    if (url.contains("i.imgur.com")) {
      return url;
    }

    return "";
    // final RegExp exp = RegExp(r'(^(http|https):\/\/)?(i\.)?imgur.com\/((?P<gallery>gallery\/)(?P<galleryid>\w+)|(?P<album>a\/)(?P<albumid>\w+)#?)?(?P<imgid>\w*)');
    // RegExpMatch? match = exp.firstMatch(url);
    //
    // return match != null ? url.substring(match.start, match.end) : "";
  }

  void initImgurListener() {
    imgurCtrl.addListener(() {
      validImgur = "";
      if (imgurCtrl.text.isNotEmpty) {
        validImgur = imgurCtrl.text.trim();
      }
      //TODO RUN RegExp on input to check if it is an URL
      //TODO Make a http request to see if response code is 200
      //TODO validate against own imgur regexp, reverse engineer a regexp
      setState(() {});
    });
  }

  void initYouTubeListener() {
    youtubeCtrl.addListener(() {
      validVideo = "";
      if (youtubeCtrl.text.isNotEmpty) {
        validVideo = youtubeCtrl.text.trim();
        validVideo = YoutubePlayer.convertUrlToId(validVideo) ?? "";
      }
      //TODO RUN RegExp on input to check if it is an URL
      //TODO Make a http request to see if response code is 200
      //TODO validate against own youtube regexp, reverse engineer a regexp
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
    imgurCtrl.dispose();
    youtubeCtrl.dispose();
    disposeTagger();
  }

  @override
  Widget build(BuildContext context) {
    // final UserProvider userProvider = Provider.of<UserProvider>(context);
    var addImageIcon = Icon(Icons.image_search_outlined, size: 100);
    var addVideoIcon = Icon(Icons.video_settings_rounded, size: 100);
    var insets = MediaQuery.of(context).viewInsets;
    return GestureDetector(
      onTap: _focusNode.unfocus,
      child: Scaffold(
        appBar: AppBar(title: Text("Share to earn Bitcoin")),
        body: Column(
          children: [
            Row(
              children: [
                validVideo.isEmpty
                    ? GestureDetector(
                        onTap: () {
                          showDialogImgur();
                        },
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: validImgur.isNotEmpty
                              ? Image(
                                  height: 230,
                                  image: NetworkImage(validImgur),
                                  errorBuilder: (context, error, stackTrace) {
                                    validImgur = "";
                                    return placeHolderImage(addImageIcon);
                                  },
                                )
                              : placeHolderImage(addImageIcon),
                        ),
                      )
                    : SizedBox(),
                validImgur.isEmpty
                    ? GestureDetector(
                        onTap: () {
                          showDialogVideo();
                        },
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: validVideo.isNotEmpty
                              ? YoutubePlayer(
                                  width: 350,
                                  controller: YoutubePlayerController(
                                    initialVideoId: validVideo,
                                    flags: YoutubePlayerFlags(autoPlay: false),
                                  ),
                                )
                              : Column(children: [Text("ADD VIDEO"), addVideoIcon]),
                        ),
                      )
                    : SizedBox(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: validVideo.isNotEmpty || validImgur.isNotEmpty
            ? createTaggableInput(context, insets)
            : SizedBox(),
      ),
    );
  }

  Column placeHolderImage(Icon addImageIcon) {
    return Column(children: [Text("ADD IMAGE"), addImageIcon]);
  }

  Future<void> showDialogImgur() async {
    showUrlDialog("Paste an imgur URL", imgurCtrl, "e.g. https://i.imgur.com/GLXwHJU.jpeg");
  }

  Future<void> showDialogVideo() async {
    showUrlDialog("Paste a YouTube URL", youtubeCtrl, "e.g. https://youtu.be/Ft2jo9spIHg");
  }

  void showUrlDialog(header, ctrl, hint) {
    checkClipboardHasValidYouTubeOrImgur();
    showDialog(
      builder: (dialogCtx) {
        return SimpleDialog(
          children: [
            Padding(padding: EdgeInsetsGeometry.all(10), child: Text(header)),
            Padding(
              padding: EdgeInsetsGeometry.all(10),
              child: TextInputField(textEditingController: ctrl, hintText: hint, textInputType: TextInputType.url),
            ),
          ],
        );
      },
      context: context,
    );
  }

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  double overlayHeight = 300;

  // late final homeViewModel = HomeViewModel();
  late final _tagController = FlutterTaggerController(
    //Initial text value with tag is formatted internally
    //following the construction of FlutterTaggerController.
    //After this controller is constructed, if you
    //wish to update its text value with raw tag string,
    //call (_controller.formatTags) after that.
    text: "I like the topic @Bitcoin#Bitcoin# It's time to earn #bch#bch# and #cashtoken#cashtoken#!",
  );
  late final _focusNode = FocusNode();

  void initStateTagger() {
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));

    _animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _tagController.addListener(() {
      //TODO CHECK ONLY ONE TOPIC, ONLY ONE @ sign is allowed
      //TODO Check only three hashtags, only three # are allowed
    });
  }

  void disposeTagger() {
    _animationController.dispose();
    _focusNode.dispose();
    _tagController.dispose();
  }

  Widget createTaggableInput(BuildContext context, insets) {
    return FlutterTagger(
      triggerStrategy: TriggerStrategy.eager,
      controller: _tagController,
      animationController: _animationController,
      onSearch: (query, triggerChar) {
        if (triggerChar == "@") {
          searchViewModel.searchTopic(query);
        }
        if (triggerChar == "#") {
          searchViewModel.searchHashtag(query);
        }
      },
      triggerCharacterAndStyles: const {
        "@": TextStyle(color: Colors.pinkAccent),
        "#": TextStyle(color: Colors.blueAccent),
      },
      tagTextFormatter: (id, tag, triggerCharacter) {
        return "$triggerCharacter$id#$tag#";
      },
      overlayHeight: overlayHeight,
      overlay: SearchResultOverlay(animation: _animation, tagController: _tagController),
      builder: (context, containerKey) {
        return CommentTextField(
          focusNode: _focusNode,
          containerKey: containerKey,
          insets: insets,
          controller: _tagController,
          onSend: () {
            FocusScope.of(context).unfocus();

            //TODO Check cant have multiple topics
            //TODO Check cant have more than three hashtags
            //TODO Check max length
            publishImageOrVideo(context);

            //TODO IF LAST SELECTED HASHTAG IS UNKOWN THE WHOLE MSG GETS FORMAT RESET
            //IF I TOUCH THE KEY WHEN THERE IS AN EMPTY HASHTAG LIST IT GOES WRONG
          },
        );
      },
    );
  }

  Future<void> publishImageOrVideo(BuildContext ctx) async {
    String text = _tagController.text;
    text = appendVideoOrImgurUrl(text);
    String? topic = extractTopic(text);

    var response = await MemoModelPost.publishImageOrVideo(text, topic);

    //TODO handle verification
    if (response == MemoAccountantResponse.yes) {
      clearInputs();
      setState(() {
        if (ctx.mounted) MemoConfetti().launch(ctx);
      });
    }
  }

  void clearInputs() {
    _tagController.clear();
    validImgur = "";
    validVideo = "";
    imgurCtrl.clear();
    youtubeCtrl.clear();
  }

  String? extractTopic(String text) {
    String? topic;
    for (Tag t in _tagController.tags) {
      if (t.triggerCharacter == "@") {
        topic = t.text;
      }
    }
    if (topic == null) {
      if (text.contains("@")) {
        for (String t in text.split(" ")) {
          if (t.startsWith("@")) {
            topic = t.substring(1);
          }
        }
      }
    }
    return topic;
  }

  //TODO MAKE SURE THAT WHEN IMAGE WAS LOADED BEFORE THEN VIDEO AFTERWARDS OR REVERSE ITS NOT GOING WRONG
  String appendVideoOrImgurUrl(String text) {
    return validVideo.isNotEmpty
        ? "$text https://youtu.be/${validVideo}"
        : validImgur.isNotEmpty
        ? "$text $validImgur"
        : text;
  }
}

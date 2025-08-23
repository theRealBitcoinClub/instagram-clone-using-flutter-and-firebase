import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:instagram_clone1/widgets/textfield_input.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../memomodel/memo_model_tag.dart';
import '../memomodel/memo_model_topic.dart';
import '../models/post.dart';
import '../views/view_models/home_view_model.dart';
import '../views/view_models/search_view_model.dart';
import '../views/widgets/comment_text_field.dart';
import '../views/widgets/post_widget.dart';
import '../views/widgets/search_result_overlay.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> with TickerProviderStateMixin {
  final TextEditingController imgurCtrl = TextEditingController();
  final TextEditingController youtubeCtrl = TextEditingController();
  final TextEditingController topicCtrl = TextEditingController();
  final TextEditingController hashtagCtrl = TextEditingController();
  final TextEditingController textCtrl = TextEditingController();
  bool isLoading = false;
  String validImgur = "";
  String validVideo = "";
  /// The [LayerLink] is used to link the [CompositedTransformTarget] and
  /// [CompositedTransformFollower] widgets required to show the overlay.
  // final _layerLink = LayerLink();

  /// The [_formKey] is used to get the [RenderBox] of the [Form] widget to
  /// position the overlay.
  // final _formKey = GlobalKey<FormState>();

  /// The [_focusNode] is used to focus the [TextField] when the overlay is
  /// closed.
  // late FocusNode _focusNode;

  /// A list of comments made using the [TagTextEditingController].
  // final List<List<InlineSpan>> comments = [];

  /// The [TagTextEditingController] is used to control the [TextField] and
  /// handle the tagging logic.
  // late final TagTextEditingController _controller;

  /// The [_overlayEntry] is used to show the overlay with the list of
  /// taggables.
  // OverlayEntry? _overlayEntry;

  /// The [backendFormat] is used to display the backend format of the text
  // String backendFormat = '';

  @override
  void initState() {
    super.initState();
    imgurCtrl.addListener(() {
      validImgur = "";
      if (imgurCtrl.text.isNotEmpty) {
        validImgur = imgurCtrl.text.trim();
      }
      //TODO RUN RegExp on input to check if it is an URL
      //TODO Make a http request to see if response code is 200
      //TODO validate against own imgur regexp, reverse engineer a regexp
      setState(() {
      });
    },);
    youtubeCtrl.addListener(() {
      validVideo = "";
      if (youtubeCtrl.text.isNotEmpty) {
        validVideo = youtubeCtrl.text.trim();
        validVideo = YoutubePlayer.convertUrlToId(validVideo) ?? "";
      }
      //TODO RUN RegExp on input to check if it is an URL
      //TODO Make a http request to see if response code is 200
      //TODO validate against own youtube regexp, reverse engineer a regexp
      setState(() {
      });
    },);

    // _focusNode = FocusNode();

    // Initialize the [TagTextEditingController] with the required parameters.
    // _controller = TagTextEditingController<Taggable>(
    //   searchTaggables: searchTaggables,
    //   buildTaggables: buildTaggables,
    //   toFrontendConverter: (taggable) => taggable.name,
    //   toBackendConverter: (taggable) => taggable.id,
    //   textStyleBuilder: textStyleBuilder,
    //   tagStyles: const [TagStyle(prefix: '@'), TagStyle(prefix: '#')],
    // );

    // Add a listener to update the [backendFormat] when the text changes.
    // _controller.addListener(
    //         () => setState(() => backendFormat = _controller.textInBackendFormat));
    initStateTagger();
  }

  @override
  void dispose() {
    super.dispose();
    imgurCtrl.dispose();
    youtubeCtrl.dispose();
    topicCtrl.dispose();
    hashtagCtrl.dispose();
    textCtrl.dispose();
    // _focusNode.dispose();
    // _controller.dispose();
    // _overlayEntry?.remove();
    disposeTagger();
  }

  @override
  Widget build(BuildContext context) {
    // final UserProvider userProvider = Provider.of<UserProvider>(context);
    var addImageIcon = Icon(Icons.image_search_outlined, size: 100,);
    var addVideoIcon = Icon(Icons.video_settings_rounded, size: 100,);
    var insets = MediaQuery.of(context).viewInsets;
    return GestureDetector(
        onTap: _focusNode.unfocus,
        child: Scaffold(appBar: AppBar(title: Text("Share to earn Bitcoin"),),
      body: Column(
        children: [
          Row(children: [
            validVideo.isEmpty ?
              GestureDetector(onTap: () {
                showDialogImgur();
              }, child: Padding(
                padding: EdgeInsets.all(15),
                child:
                validImgur.isNotEmpty
                    ? Image(height: 230,
                              image: NetworkImage(validImgur), errorBuilder: (context, error, stackTrace) {
                                validImgur="";
                                return placeHolderImage(addImageIcon);
                              },
                          )
                    : placeHolderImage(addImageIcon)
              ),) : SizedBox(),
            validImgur.isEmpty ?
            GestureDetector(onTap: () {
              showDialogVideo();
            }, child: Padding(
                padding: EdgeInsets.all(15),
                child:
                    validVideo.isNotEmpty ? YoutubePlayer(width:350, controller:
                                              YoutubePlayerController(initialVideoId: validVideo, flags:
                                                YoutubePlayerFlags(autoPlay: false)))
                        : Column(children: [
                            Text("ADD VIDEO"),
                            addVideoIcon]
                          )
                  )) : SizedBox()
          ]),
        ]),
            bottomNavigationBar:
                validVideo.isNotEmpty || validImgur.isNotEmpty
                ? createTaggableInput(context, insets)
                : SizedBox(),
        )
    );
  }

  Column placeHolderImage(Icon addImageIcon) {
    return Column(
      children: [
      Text("ADD IMAGE"),addImageIcon]);
  }

  Future<void> showDialogImgur() async {
    //TODO check clipboard first and if it contains valid imgur url no need for dialog
    showDialog(builder: (dialogCtx) {
          return SimpleDialog(children: [Text("Imgur URL"),
            TextInputField(
                textEditingController: imgurCtrl, 
                hintText: "e.g. https://i.imgur.com/GLXwHJU.jpeg",
                textInputType: TextInputType.url)]);
        }, context: context,);
  }

  Future<void> showDialogVideo() async {
    //TODO check clipboard first and if it contains valid imgur url no need for dialog
    showDialog(builder: (dialogCtx) {
      return SimpleDialog(children: [Text("YouTube URL"),
        TextInputField(
            textEditingController: youtubeCtrl,
            hintText: "e.g. https://youtu.be/Qx7OlKoryzE",
            textInputType: TextInputType.url)]);
    }, context: context,);
  }
  late AnimationController _animationController;
  late Animation<Offset> _animation;

  double overlayHeight = 300;

  late final homeViewModel = HomeViewModel();
  late final _controller = FlutterTaggerController(
    //Initial text value with tag is formatted internally
    //following the construction of FlutterTaggerController.
    //After this controller is constructed, if you
    //wish to update its text value with raw tag string,
    //call (_controller.formatTags) after that.
    text:
    "I like the topic @Bitcoin#Bitcoin#. It's time to earn #bch#bch#!",
  );
  late final _focusNode = FocusNode();

  void initStateTagger() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void disposeTagger() {
    _animationController.dispose();
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget createTaggableInput(BuildContext context, insets) {
        return FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: _controller,
          animationController: _animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchTopic(query);
            }
            // if (triggerChar == "@") {
            //   searchViewModel.searchUser(query);
            // }
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
          overlay: SearchResultOverlay(
            animation: _animation,
            tagController: _controller,
          ),
          builder: (context, containerKey) {
            return CommentTextField(
              focusNode: _focusNode,
              containerKey: containerKey,
              insets: insets,
              controller: _controller,
              onSend: () {
                FocusScope.of(context).unfocus();
                // homeViewModel.addPost(_controller.formattedText);
                _controller.clear();
              },
            );
          },
        );
  }
}

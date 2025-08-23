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
          validVideo.isNotEmpty || validImgur.isNotEmpty
              ? createTaggableInput(context, insets)
              : SizedBox()
        ])
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
    "Hey @11a27531b866ce0016f9e582#brad#. It's time to #93f27531f294jp0016f9k013#Flutter#!",
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
                homeViewModel.addPost(_controller.formattedText);
                _controller.clear();
              },
            );
          },
        );
  }
  /*
  Widget createTaggableInput() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SizedBox(
          width: 600,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...comments.map((comment) {
                return Card(
                  margin: const EdgeInsets.all(4),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text.rich(
                      TextSpan(
                        children: comment,
                      ),
                    ),
                  ),
                );
              }),
              Form(
                key: _formKey,
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Type @ to tag a user or # to tag a topic',
                      helperText: 'Backend format: $backendFormat',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () async {
                          final textSpans =
                          await _buildTextSpans(_controller.text, context);
                          setState(() {
                            comments.add(textSpans);
                            _controller.clear();
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // This is an example of setting the initial text.
                  _controller.setText(
                    "Hello @aliceUniqueId and welcome to #myFlutterId",
                    backendToTaggable,
                  );
                },
                child: const Text('Set initial text'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle? textStyleBuilder(
      BuildContext context, String prefix, Taggable taggable) {
    // if (taggable.id == 'hawkingUniqueId') {
    //   return const TextStyle(
    //     color: Colors.red,
    //     decoration: TextDecoration.underline,
    //     fontWeight: FontWeight.bold,
    //   );
    // }
    return switch (prefix) {
      '@' => TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold),
      '#' => TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.bold),
      _ => null,
    };
  }

  /// This method is used to build the [InlineSpan]s from the backend format.
  FutureOr<List<InlineSpan>> _buildTextSpans(
      String backendFormat,
      BuildContext context,
      ) async {
    return convertTagTextToInlineSpans<Taggable>(
      backendFormat,
      tagStyles: _controller.tagStyles,
      backendToTaggable: backendToTaggable,
      taggableToInlineSpan: (taggable, tagStyle) {
        return TextSpan(
          text: '${tagStyle.prefix}${taggable.name}',
          style: textStyleBuilder(context, tagStyle.prefix, taggable),
          recognizer: TapGestureRecognizer()
            ..onTap = () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tapped ${taggable.name} with id ${taggable.id}',
                ),
                duration: const Duration(seconds: 2),
              ),
            ),
        );
      },
    );
  }

  /// Shows the overlay with the list of taggables.
  Future<Taggable?> buildTaggables(
      FutureOr<Iterable<Taggable>> taggables) async {
    final availableTaggables = await taggables;

    // We use a [Completer] to return the selected taggable from the overlay.
    // This is because overlays do not return values directly.
    Completer<Taggable?> completer = Completer();

    // Remove the existing overlay if it exists.
    _overlayEntry?.remove();
    if (availableTaggables.isEmpty) {
      // If there are no taggables to show, we return null.
      _overlayEntry = null;
      completer.complete(null);
    } else {
      _overlayEntry = OverlayEntry(builder: (context) {
        // The following few lines are used to position the overlay above the
        // [TextField]. It moves along if the [TextField] moves.
        final renderBox =
        _formKey.currentContext!.findRenderObject() as RenderBox;
        return Positioned(
          width: renderBox.size.width,
          bottom: renderBox.size.height + 8,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            followerAnchor: Alignment.bottomLeft,
            child: Material(
              child: ListView(
                shrinkWrap: true,
                children: availableTaggables.map((taggable) {
                  // We show the list of taggables in a [ListView].
                  return ListTile(
                    leading: Icon(taggable.icon),
                    title: Text(taggable.name),
                    tileColor: Theme.of(context).colorScheme.primaryContainer,
                    onTap: () {
                      // When a taggable is selected, remove the overlay
                      _overlayEntry?.remove();
                      _overlayEntry = null;
                      // and complete the Completer with the selected taggable.
                      completer.complete(taggable);
                      // Focus the [TextField] to continue typing.
                      // Do this after completing the Completer to avoid
                      // interfering with the logic of adding the taggable.
                      _focusNode.requestFocus();
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      });
      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    }
    return completer.future;
  }

  /// This method searches for taggables based on the tag prefix and tag name.
  ///
  /// You can specify different behaviour based on the tag prefix.
  Future<Iterable<Taggable>> searchTaggables(
      String tagPrefix, String? tagName) async {
    if (tagName == null || tagName.isEmpty) {
      return [];
    }
    return switch (tagPrefix) {
      '#' => MemoModelTag.tags
          .where((user) =>
          user.name.toLowerCase().startsWith(tagName.toLowerCase()))
          .toList(),
      '@' => MemoModelTopic.topics
          .where((topic) =>
          topic.name.toLowerCase().startsWith(tagName.toLowerCase()))
          .toList(),
      'all:' => [...MemoModelTag.tags, ...MemoModelTopic.topics].where((taggable) =>
          taggable.name.toLowerCase().startsWith(tagName.toLowerCase())),
      _ => [],
    };
  }

  /// This method converts the backend format to the taggable object.
  FutureOr<Taggable?> backendToTaggable(String prefix, String id) {
    return switch (prefix) {
      '@' => MemoModelTag.tags.where((user) => user.id == id).firstOrNull,
      '#' => MemoModelTopic.topics.where((topic) => topic.id == id).firstOrNull,
      'all:' => [...MemoModelTag.tags, ...MemoModelTopic.topics]
          .where((taggable) => taggable.id == id)
          .firstOrNull,
      _ => null,
    };
  }*/
}

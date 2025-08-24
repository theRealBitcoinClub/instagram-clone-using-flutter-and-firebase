import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone1/memobase/memo_bitcoin_base.dart';
import 'package:instagram_clone1/memomodel/memo_model_user.dart';
import 'package:instagram_clone1/memoscraper/memo_scraper_utils.dart';
import 'package:instagram_clone1/utils/imgur_utils.dart';
import 'package:instagram_clone1/utils/snackbar.dart';
import 'package:instagram_clone1/widgets/like_animtion.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:zoom_pinch_overlay/zoom_pinch_overlay.dart';

import '../memobase/memo_code.dart';
import '../memobase/memo_publisher.dart';
import '../memomodel/memo_model_post.dart';

class PostCard extends StatefulWidget {
  final MemoModelPost post;

  // const PostCard({super.key, required this.snap});
  const PostCard(this.post, {super.key});

  @override
  State<PostCard> createState() => _PostCardState(post);
}

class _PostCardState extends State<PostCard> {
  MemoModelUser? user;
  bool isAnimating = false;
  MemoModelPost post;
  bool showInput = false;
  bool showSend = false;
  bool hasSelectedTags = false;
  bool hasSelectedTopic = false;
  TextEditingController textEdit = TextEditingController();
  List<bool> selectedHashtags = [false, false, false];
  final int maxTagsCounter = 3;
  final int minTextLength = 20;

  _PostCardState(this.post);

  @override
  void initState() {
    super.initState();

    loadUser();
  }

  void loadUser() async {
    user = await MemoModelUser.createDummy();
  }

  @override
  Widget build(BuildContext context) {
    // final model.User user = Provider.of<UserProvider>(context).getUser;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 1),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16).copyWith(right: 0),
            color: Colors.white,
            //headerbar
            child: Row(
              children: [
                GestureDetector(
                  onTap: onClickCreatorName(post.creator!.id!),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(post.creator!.profileImage()),
                    //TODO LOAD PROFILE IMAGE
                    // backgroundImage: NetworkImage(widget.snap['profileImage']),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /* TextButton(onPressed: onClickCreatorName(post.creator!.id!), child: */
                        /*
                      Text(
                        post.creator!.name!,
                        style: const TextStyle(fontSize: 13),
                      ),*/
                        const Spacer(),

                        Text(post.age!, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                        Text(" - ${post.created}", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        // backgroundColor: Colors.white10,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                        child: ListView(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shrinkWrap: true,
                          children: ["Tip", "Share", "Mute Post"]
                              .map(
                                (e) => InkWell(
                                  onTap: () {
                                    //   TODO DELETEPOST LOLL
                                    // async {
                                    //   String res =
                                    //       await FireStoreMethods()
                                    //           .deletePost(
                                    //               widget.snap['postId']);
                                    showSnackBar("LOL", context);
                                    Navigator.pop(context);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Center(child: Text(e)),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () async {
              MemoPublisher().doMemoAction(
                MemoBitcoinBase.reOrderTxHash(post.txHash!),
                MemoCode.postLike,
                tipReceiver: post.creator!.id!,
                tipAmount: 1111,
              );
              // TODO TIP POST WITH STANDARD TIP
              // TODO LET USER INPUT WIF AND CHOOSE THEIR STANDARD TIP
              // TODO ALWAYS PUT HASHTAGS LAST IN POSTS
              // FireStoreMethods().likePost(widget.snap['postId'],
              //     user.uid, widget.snap['likes']);
              setState(() {
                isAnimating = true;
              });
            },
            child: ZoomOverlay(
              modalBarrierColor: Colors.black12,
              // optional
              minScale: 0.5,
              // optional
              maxScale: 3.0,
              // optional
              twoTouchOnly: true,
              animationDuration: const Duration(milliseconds: 300),
              animationCurve: Curves.fastOutSlowIn,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  post.youtubeId != null
                      ? YoutubePlayer(
                          controller: YoutubePlayerController(
                            initialVideoId: post.youtubeId!,
                            flags: YoutubePlayerFlags(
                              hideThumbnail: true,
                              hideControls: true,
                              mute: false,
                              autoPlay: false,
                            ),
                          ),
                          showVideoProgressIndicator: true,
                          onReady: () {
                            // print('Player is ready.');
                          },
                        )
                      :
                        // CachedNetworkImage(
                        //   imageUrl: post.imgurUrl == null ? "https://i.imgur.com/yhN4cfs.png" : post.imgurUrl!,
                        //   fit: BoxFit.cover,
                        //   placeholder: (context, url) => CircularProgressIndicator(),
                        //
                        //   imageBuilder: (ctx, builder) => onBuildImage(ctx, builder) ,
                        //   errorWidget: (context, url, error) => Icon(Icons.error),
                        //   errorListener: (error) => onErrorLoadImage(error),
                        // )
                        post.imgurUrl == null
                      ? Container(color: Colors.green, height: 0)
                      : Image(
                          image: NetworkImage(post.imgurUrl!),
                          // height: MediaQuery.of(context).size.height * 0.45,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              ImgurUtils.errorLoadImage(context, error, stackTrace),
                          loadingBuilder: (context, child, loadingProgress) =>
                              ImgurUtils.loadingImage(context, child, loadingProgress),
                        ),
                  //TODO HANDLE TEXT ONLY AND HANDLE TOPICS SO PEOPLE CAN REPLY
                  //TODO LET USERS INTERACT WITH HASHTAGS IN TEXT AND URLS IN TEXT
                  //TODO ADD MENTIONED HASHTAGS AS CLICKABLE BUTTONS BELOW POST
                  //TODO ADD TOPIC AS CLICKABLE BUTTON
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isAnimating ? 1 : 0,
                    child: LikeAnimation(
                      isAnimating: isAnimating,
                      duration: const Duration(milliseconds: 400),
                      onEnd: () {
                        setState(() {
                          isAnimating = false;
                        });
                      },
                      child: Icon(
                        Icons.currency_bitcoin,
                        color: Color.fromRGBO(255, 255, 255, 1),
                        size: post.imgurUrl == null ? 0 : 150,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          //number of likes , description and number of comments
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),

                Column(
                  children: <Widget>[
                    ExpandableText(
                      post.text ?? "",
                      // widget.snap['discription'], TODO TEXT
                      prefixText: post.creator!.name! + ":",
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                      expandText: 'show more',
                      collapseText: 'show less',
                      maxLines: 5,
                      linkColor: Colors.blue,
                    ),
                    showInput ? TextField(controller: textEdit, onChanged: (value) => onInputText(value)) : SizedBox(),
                    showSend
                        ? Row(
                            children: [
                              TextButton(
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(Colors.green),
                                  elevation: WidgetStatePropertyAll(5),
                                ),
                                onPressed: () => onSend(),
                                child: Text(
                                  hasSelectedTags && hasSelectedTopic
                                      ? "Topic reply with hashtags"
                                      : hasSelectedTopic
                                      ? "Reply to Topic"
                                      : "Post with hashtags",
                                ),
                              ),
                            ],
                          )
                        : SizedBox(),
                    post.topic != null
                        ? Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  onSelectTopic();
                                },
                                child: Text("TOPIC: ${post.topic!.header}"),
                              ),
                              Checkbox(
                                value: hasSelectedTopic,
                                onChanged: (value) {
                                  onSelectTopic();
                                },
                              ),
                            ],
                          )
                        : SizedBox(),
                    post.hashtags.isNotEmpty
                        ? Column(
                            children: List<Widget>.generate(
                              post.hashtags.length > maxTagsCounter ? maxTagsCounter : post.hashtags.length,
                              (index) {
                                return Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        onSelectHashtag(index);
                                      },
                                      child: Text(
                                        style: TextStyle(
                                          backgroundColor: index % 2 == 0 ? Colors.grey.shade400 : Colors.grey.shade300,
                                        ),
                                        post.hashtags[index],
                                      ),
                                    ),
                                    Checkbox(
                                      value: selectedHashtags[index],
                                      onChanged: (value) {
                                        onSelectHashtag(index);
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          )
                        : SizedBox(),

                    // CheckboxListTile(value: selectedHashtags[index], onChanged: onSelectHashtag(index));

                    // post.hashtags.forEach((element) {
                    //   GestureDetector(onTap: () => onSelectTopic(), child:
                    //   Text("${post.hashtags[0]!}")),
                    //   Checkbox(
                    //   value: hasSelectedTopic,
                    //   onChanged: (value) => onSelectTopic(),)
                    // },)
                    // ,
                    // (post.hashtags.isNotEmpty ? post.hashtags.forEach((element) {
                    // TextButton(onPressed: () => onHashTag(element)
                    // ,child: Text(element))
                    // }) : SizedBox())])
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  onClickCreatorName(String id) {
    // Navigator.of(context).push(
    //   MaterialPageRoute(builder: (context) => ProfileScreen(uid: id)),
    // );
  }

  void onSend() {
    if (hasSelectedTopic) {
      onReplyTopic();
    } else {
      onPostWithHashtags();
    }
  }

  void onSelectTopic() {
    setState(() {
      hasSelectedTopic = !hasSelectedTopic;

      if (hasSelectedTags || hasSelectedTopic) {
        showInput = true;
      } else {
        showInput = false;
      }
    });
  }

  void onInputText(String value) {
    setState(() {
      for (int run = 0; run < maxTagsCounter && post.hashtags.length != run; run++) {
        if (selectedHashtags[run] && !MemoScraperUtil.extractHashtags(value).contains(post.hashtags[run])) {
          selectedHashtags[run] = false;
        } else if (MemoScraperUtil.extractHashtags(value).contains(post.hashtags[run])) {
          selectedHashtags[run] = true;
        }
      }

      bool inputContainsHashtag = false;
      if (value.isNotEmpty) {
        String textWithoutHashtags = value;

        for (String tag in post.hashtags) {
          textWithoutHashtags = textWithoutHashtags.replaceAll(tag, "").trim();
          if (MemoScraperUtil.extractHashtags(value).contains(tag)) {
            inputContainsHashtag = true;
          }
        }

        if (textWithoutHashtags.length > minTextLength) {
          showSend = true;
          if (!inputContainsHashtag && !hasSelectedTopic) {
            showSend = false;
          } else {
            showSend = true;
          }
        } else
          showSend = false;
      } else {
        showSend = false;
      }
    });
  }

  onSelectHashtag(int index) {
    //TODO CHECK OVERALL TEXT LENGTH DOESNT EXCEED MAX
    setState(() {
      bool inputContainsHashtag = false;
      selectedHashtags[index] = !selectedHashtags[index];

      for (String t in post.hashtags) {
        textEdit.text = textEdit.text.replaceAll(t, "").trim();
      }

      hasSelectedTags = false;
      int run = 0;
      for (bool t in selectedHashtags) {
        if (post.hashtags.length == run) continue;

        var hashtag = post.hashtags[run];
        if (t) {
          hasSelectedTags = true;
          textEdit.text += " $hashtag";
        }
        if (MemoScraperUtil.extractHashtags(textEdit.text).contains(post.hashtags[run])) {
          inputContainsHashtag = true;
        }
        run++;
      }

      if (hasSelectedTags || hasSelectedTopic) {
        showInput = true;
      } else {
        showInput = false;
      }

      String textWithoutHashtags = textEdit.text;

      for (String tag in post.hashtags) {
        textWithoutHashtags = textWithoutHashtags.replaceAll(tag, "").trim();
      }

      if (!inputContainsHashtag && !hasSelectedTopic) {
        showSend = false;
      } else if (textWithoutHashtags.length > minTextLength) {
        showSend = true;
      }
    });
  }

  void onReplyTopic() async {
    //TODO let user config the tip
    // MemoPublisher().doMemoAction(textEdit.text.trim(), MemoCode.topicMessage, memoTopic: post.topic!.header!, tipReceiver: post.creator!.id);
    //TODO encapsulate the retry as all actions will be served like that
    //TODO do not handle strings, handle enum response codes
    String result = await MemoPublisher().doMemoAction(
      textEdit.text.trim(),
      MemoCode.topicMessage,
      memoTopic: post.topic!.header,
      wif: user!.wifBchCashtoken,
    );

    if (result != "success") {
      showSnackBar("trieng memo funds", context);

      result = await MemoPublisher().doMemoAction(
        textEdit.text.trim(),
        MemoCode.topicMessage,
        memoTopic: post.topic!.header,
        wif: user!.wifLegacy,
      );

      //TODO HANDLE RPCError: got code 1 with message "the transaction was rejected by network rules. DUST

      if (result != "success") {
        showSnackBar("you broke dude", context);
      } else {
        showSnackBar("show tx id link", context);
        //TODO hide on success
        //TODO SHOW ANIMATION CONFETTI OVER THE WHOLE POST
      }
    } else {
      showSnackBar("show tx id link", context);
    }
  }

  void onPostWithHashtags() {
    MemoPublisher().doMemoAction(textEdit.text.trim(), MemoCode.profileMessage);
    // MemoPublisher().doMemoAction(textEdit.text.trim(), MemoCode.profileMessage, tipReceiver: post.creator!.id);
  }

  // onErrorLoadImage(error) {
  //   print("object");
  // }
  //
  // Widget onBuildImage(BuildContext ctx, ImageProvider<Object> builder) {
  //   print("object");
  //   return builder;
  // }
}

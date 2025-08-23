import 'package:flutter/material.dart';
import 'package:instagram_clone1/widgets/textfield_input.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  State<AddPost> createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  final TextEditingController imgurCtrl = TextEditingController();
  final TextEditingController youtubeCtrl = TextEditingController();
  final TextEditingController topicCtrl = TextEditingController();
  final TextEditingController hashtagCtrl = TextEditingController();
  bool isLoading = false;
  String validImgur = "";
  String validVideo = "";
  
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
  }

  @override
  void dispose() {
    super.dispose();
    imgurCtrl.dispose();
    youtubeCtrl.dispose();
    topicCtrl.dispose();
    hashtagCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final UserProvider userProvider = Provider.of<UserProvider>(context);
    var addImageIcon = Icon(Icons.image_search_outlined, size: 100,);
    var addVideoIcon = Icon(Icons.video_settings_rounded, size: 100,);
    return Scaffold(appBar: AppBar(title: Text("Share to earn Bitcoin"),),
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
          ],),
        ])
    );
  }

  Column placeHolderImage(Icon addImageIcon) {
    return Column(
      children: [
      Text("ADD IMAGE"),addImageIcon]);
  }

  showDialogImgur() async {
    //TODO check clipboard first and if it contains valid imgur url no need for dialog
    showDialog(builder: (dialogCtx) {
          return SimpleDialog(children: [Text("Imgur URL"),
            TextInputField(
                textEditingController: imgurCtrl, 
                hintText: "e.g. https://i.imgur.com/GLXwHJU.jpeg",
                textInputType: TextInputType.url)]);
        }, context: context,);
  }

  showDialogVideo() async {
    //TODO check clipboard first and if it contains valid imgur url no need for dialog
    showDialog(builder: (dialogCtx) {
      return SimpleDialog(children: [Text("YouTube URL"),
        TextInputField(
            textEditingController: youtubeCtrl,
            hintText: "e.g. https://youtu.be/Qx7OlKoryzE",
            textInputType: TextInputType.url)]);
    }, context: context,);
  }
}

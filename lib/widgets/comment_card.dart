import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:mahakka/memo/memomodel/memo_model_post.dart';
import 'package:mahakka/utils/colors.dart';

class CommentsCard extends StatefulWidget {
  // final snap;
  // const CommentsCard({super.key, required this.snap});
  final MemoModelPost post;

  const CommentsCard({super.key, required this.post});

  @override
  State<CommentsCard> createState() => _CommentsCardState();
}

//TODO NO COMMENTS, REPLY TO TOPICS IS ALLOWED AND IS PUT IN SAME TOPIC AS POST, ONLY POSTS NO REPLIES, NO COMMENTS, NO LIKES, ONLY TIPS
class _CommentsCardState extends State<CommentsCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 20, backgroundImage: NetworkImage(widget.post.creator!.profileImage())),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        widget.post.creator!.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Text(
                        widget.post.created!,
                        // DateFormat.yMMMd().format(widget.snap['date'].toDate()),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: secondaryColor),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ExpandableText(
                    widget.post.text!,
                    expandText: 'show more',
                    collapseText: 'show less',
                    maxLines: 3,
                    linkColor: Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () async {
                      //TODO LIKE BUTTON
                      // await FireStoreMethods().likeComment(widget.snap['postId'],
                      //     widget.snap['commentId'], user.uid, widget.snap['likes']);
                    },
                    icon: // TODO COLOR MARK OWN LIKES
                        // widget.snap['likes'].contains(user.uid)? const Icon(
                        // Icons.favorite,
                        // color: Colors.red,
                        // size: 20,
                        // )
                        // :
                        const Icon(Icons.favorite_border, size: 20),
                    alignment: Alignment.topRight,
                  ),

                  Positioned(
                    bottom: 6,
                    left: 26,
                    child: Text(
                      "${widget.post.likeCounter}",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

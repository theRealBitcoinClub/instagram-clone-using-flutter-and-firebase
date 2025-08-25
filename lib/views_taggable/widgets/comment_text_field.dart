import 'package:flutter/material.dart';
import 'package:fluttertagger/fluttertagger.dart';

import 'custom_text_field.dart';

class CommentTextField extends StatelessWidget {
  final FlutterTaggerController controller;

  // final List<String> emojis;
  final VoidCallback onSend;
  final EdgeInsets insets;
  final FocusNode? focusNode;
  final String hintText;

  ///Key passed down from FlutterTagger
  final Key? containerKey;

  const CommentTextField({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.insets,
    // this.emojis = const [
    //   '😍',
    //   '😜',
    //   '👍',
    //   '🤞',
    //   '🙌',
    //   '😉',
    //   '🙏',
    // ],
    this.focusNode,
    this.containerKey,
    required this.hintText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: containerKey,
      constraints: BoxConstraints(maxHeight: insets == EdgeInsets.zero ? 150 : 150 + insets.bottom),
      padding: const EdgeInsets.fromLTRB(4, 10, 3, 20),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: insets == EdgeInsets.zero ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // SingleChildScrollView(
          //   scrollDirection: Axis.horizontal,
          //   child: SizedBox(
          //     width: width,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceAround,
          //       children: [
          //         for (var emoji in emojis)
          //           EmojiIcon(
          //             fontSize: 24,
          //             emoji: emoji,
          //             onTap: (emoji) {
          //               final baseOffset = controller.selection.baseOffset;
          //               final cursorPosition = controller.cursorPosition;
          //               final substring = controller.formattedText
          //                   .substring(0, cursorPosition);
          //               final newText = substring +
          //                   emoji +
          //                   controller.formattedText.substring(cursorPosition);
          //
          //               controller.text = newText;
          //               controller.formatTags();
          //
          //               controller.selection = TextSelection.fromPosition(
          //                 TextPosition(offset: baseOffset + emoji.length),
          //               );
          //             },
          //           )
          //       ],
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 18),
          Row(
            children: [
              // Container(
              //   height: 50,
              //   width: 50,
              //   decoration: BoxDecoration(
              //     shape: BoxShape.circle,
              //     image: DecorationImage(
              //       fit: BoxFit.cover,
              //       image: NetworkImage(User.anon().avatar),
              //     ),
              //   ),
              // ),
              // const Spacer(),
              SizedBox(
                width: 380,
                height: 115,
                // width: width * .82,
                child: CustomTextField(
                  focusNode: focusNode,
                  controller: controller,
                  hint: hintText,
                  suffix: IconButton(
                    iconSize: 45,
                    onPressed: onSend,
                    icon: const Icon(Icons.send, color: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// class EmojiIcon extends StatelessWidget {
//   final String emoji;
//   final Function(String) onTap;
//   final double fontSize;
//
//   const EmojiIcon({
//     Key? key,
//     required this.emoji,
//     required this.onTap,
//     this.fontSize = 24,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () => onTap(emoji),
//       child: Text(
//         emoji,
//         style: TextStyle(
//           fontSize: fontSize,
//         ),
//       ),
//     );
//   }
// }

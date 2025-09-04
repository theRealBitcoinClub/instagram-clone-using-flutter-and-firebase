import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';

class PostDialog extends StatelessWidget {
  final ThemeData theme;
  final MemoModelPost post;
  final MemoModelCreator? creator;
  final Widget imageWidget;

  const PostDialog({Key? key, required this.theme, required this.post, required this.creator, required this.imageWidget}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      backgroundColor: theme.dialogTheme.backgroundColor ?? theme.colorScheme.surface,
      shape: theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: _buildTitleRow(),
      titleTextStyle: theme.textTheme.titleSmall,
      children: _buildDialogContent(),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Text("${post.createdDateTime!.toString().split('.').first}"),
        Spacer(),
        PopularityScoreWidget(score: post.popularityScore),
        Spacer(),
        Text("${post.age} ago"),
      ],
    );
  }

  List<Widget> _buildDialogContent() {
    return [
      //TODO ADD THE DOUBLE TAP AND LIKE ANIMATION WITH A CLOSE OF THE DIALOG AND CONFETTI
      //TODO TRIGGER UPDATE POPULARITYSCORE
      // GestureDetector(onDoubleTap: , child:
      Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: imageWidget),
      if (post.text != null && post.text!.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(post.text!, style: theme.dialogTheme.contentTextStyle ?? theme.textTheme.bodyMedium),
        ),
    ];
  }
}

// Helper function to show the dialog
void showPostDialog({
  required BuildContext context,
  required ThemeData theme,
  required MemoModelPost post,
  required MemoModelCreator? creator,
  required Widget imageWidget,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return PostDialog(theme: theme, post: post, creator: creator, imageWidget: imageWidget);
    },
  );
}

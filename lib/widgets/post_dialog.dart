import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/memo/model/memo_model_post.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';
import 'package:mahakka/widgets/unified_image_widget.dart';

class PostDialog extends StatefulWidget {
  final ThemeData theme;
  final MemoModelPost post;
  final MemoModelCreator? creator;
  final UnifiedImageWidget imageWidget;
  final GlobalKey unifiedImageKey;

  const PostDialog({
    Key? key,
    required this.theme,
    required this.post,
    required this.creator,
    required this.imageWidget,
    required this.unifiedImageKey,
  }) : super(key: key);

  @override
  State<PostDialog> createState() => _PostDialogState();
}

class _PostDialogState extends State<PostDialog> {
  @override
  void initState() {
    super.initState();
    // Call changeFitMode when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _changeFitMode();
    });
  }

  void _changeFitMode() {
    final state = widget.unifiedImageKey.currentState as UnifiedImageWidgetState?;
    state?.changeFitMode(ImageFitMode.fitWidth);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.theme.dialogTheme.backgroundColor ?? widget.theme.colorScheme.surface,
      shape: widget.theme.dialogTheme.shape ?? RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // child: ConstrainedBox(
      //   constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.9),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title row
            Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), child: _buildTitleRow()),

            // Image
            Padding(padding: const EdgeInsets.symmetric(vertical: 12.0), child: widget.imageWidget),

            // Text content if available
            if (widget.post.text != null && widget.post.text!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Text(widget.post.text!, style: widget.theme.dialogTheme.contentTextStyle ?? widget.theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
      // ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        Expanded(child: Text("${widget.post.createdDateTime!.toString().split('.').first}", style: widget.theme.textTheme.titleSmall)),
        PopularityScoreWidget(score: widget.post.popularityScore),
        const SizedBox(width: 8),
        Text("${widget.post.age} ago", style: widget.theme.textTheme.titleSmall),
      ],
    );
  }
}

// Helper function to show the dialog
void showPostDialog({
  required BuildContext context,
  required ThemeData theme,
  required MemoModelPost post,
  required MemoModelCreator? creator,
  required UnifiedImageWidget imageWidget,
  required GlobalKey unifiedImageKey,
}) {
  showDialog(
    context: context,
    builder: (dialogCtx) {
      return PostDialog(theme: theme, post: post, creator: creator, imageWidget: imageWidget, unifiedImageKey: unifiedImageKey);
    },
  );
}

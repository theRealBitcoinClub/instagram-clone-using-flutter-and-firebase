import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

void _logDialogError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ImageDetailDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ImageDetailDialog extends StatefulWidget {
  final ThemeData theme;
  final MemoModelCreator creator;
  final bool Function() getShowDefaultAvatar;
  final Function(bool) setShowDefaultAvatar;

  const ImageDetailDialog({
    Key? key,
    required this.theme,
    required this.creator,
    required this.getShowDefaultAvatar,
    required this.setShowDefaultAvatar,
  }) : super(key: key);

  @override
  _ImageDetailDialogState createState() => _ImageDetailDialogState();
}

class _ImageDetailDialogState extends State<ImageDetailDialog> {
  @override
  void initState() {
    super.initState();
    _refreshImageDetail();
  }

  Future<void> _refreshImageDetail() async {
    await widget.creator.refreshImageDetail();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(10),
      backgroundColor: widget.theme.colorScheme.surfaceVariant.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      children: [
        CircleAvatar(
          radius: 130,
          backgroundColor: widget.theme.colorScheme.surface,
          backgroundImage: widget.getShowDefaultAvatar() || widget.creator.profileImageDetail().isEmpty
              ? const AssetImage("assets/images/default_profile.png") as ImageProvider
              : NetworkImage(widget.creator.profileImageDetail()),
          onBackgroundImageError: widget.getShowDefaultAvatar()
              ? null
              : (exception, stackTrace) {
                  _logDialogError("Error loading profile image detail in dialog", exception, stackTrace);
                  if (mounted) {
                    widget.setShowDefaultAvatar(true);
                    setState(() {});
                  }
                },
        ),
      ],
    );
  }
}

// Helper function to show the dialog
void showCreatorImageDetail({
  required BuildContext context,
  required ThemeData theme,
  required MemoModelCreator creator,
  required bool Function() getShowDefaultAvatar,
  required Function(bool) setShowDefaultAvatar,
}) async {
  await creator.refreshImageDetail();

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ImageDetailDialog(
          theme: theme,
          creator: creator,
          getShowDefaultAvatar: getShowDefaultAvatar,
          setShowDefaultAvatar: setShowDefaultAvatar,
        );
      },
    );
  }
}

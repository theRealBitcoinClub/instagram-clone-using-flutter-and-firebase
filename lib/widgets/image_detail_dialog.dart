import 'package:flutter/material.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';

void _logDialogError(String message, [dynamic error, StackTrace? stackTrace]) {
  print('ERROR: ImageDetailDialog - $message');
  if (error != null) print('  Error: $error');
  if (stackTrace != null) print('  StackTrace: $stackTrace');
}

class ImageDetailDialog extends StatefulWidget {
  final MemoModelCreator creator;

  const ImageDetailDialog({Key? key, required this.creator}) : super(key: key);

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
      contentPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.black87,
      // backgroundColor: widget.theme.colorScheme.surfaceVariant.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      children: [
        CircleAvatar(
          radius: 145,
          backgroundColor: Colors.black87,
          backgroundImage: widget.creator.profileImageDetail().isEmpty
              ? const AssetImage("assets/images/default_profile.png") as ImageProvider
              : NetworkImage(widget.creator.profileImageDetail()),
        ),
      ],
    );
  }
}

// Helper function to show the dialog
void showCreatorImageDetail({required BuildContext context, required MemoModelCreator creator}) async {
  await creator.refreshImageDetail();

  if (context.mounted) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ImageDetailDialog(creator: creator);
      },
    );
  }
}

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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = screenWidth < screenHeight ? screenWidth : screenHeight;

    return Dialog(
      backgroundColor: Colors.black87,
      insetPadding: EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(), // Tap anywhere to close
        child: Container(
          width: screenWidth,
          height: screenHeight,
          child: Center(
            child: Container(
              width: imageSize * 0.8, // 80% of smallest dimension
              height: imageSize * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: widget.creator.profileImageDetail().isEmpty
                      ? const AssetImage("assets/images/default_profile.png") as ImageProvider
                      : NetworkImage(widget.creator.profileImageDetail()),
                  fit: BoxFit.cover, // Ensure image covers the circle
                ),
              ),
            ),
          ),
        ),
      ),
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

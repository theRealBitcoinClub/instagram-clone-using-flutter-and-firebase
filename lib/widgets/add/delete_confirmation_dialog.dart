import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/screens/icon_action_button.dart';

class DeleteConfirmationDialog extends ConsumerStatefulWidget {
  final ThemeData theme;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  const DeleteConfirmationDialog({Key? key, required this.theme, required this.onCancel, required this.onContinue}) : super(key: key);

  @override
  _DeleteConfirmationDialogState createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends ConsumerState<DeleteConfirmationDialog> with SingleTickerProviderStateMixin {
  // late AnimationController _controller;
  // late Animation<double> _opacityAnimation;
  // int _countdown = 1;
  // bool _cancelEnabled = false;
  // Timer? _countdownTimer;
  // Timer? _autoCloseTimer;

  // @override
  // void initState() {
  //   super.initState();
  //   _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
  //   _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  //
  //   _controller.forward();
  //   _startTimers();
  // }
  //
  // void _startTimers() {
  //   // Countdown timer for delete button
  //   _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  //     if (_countdown > 0) {
  //       setState(() => _countdown--);
  //     } else {
  //       timer.cancel();
  //       setState(() => _cancelEnabled = true);
  //     }
  //   });
  //
  //   // Auto-close timer
  //   _autoCloseTimer = Timer(const Duration(seconds: 10), () {
  //     if (mounted) {
  //       Navigator.of(context).pop();
  //     }
  //   });
  // }
  //
  // @override
  // void dispose() {
  //   _controller.dispose();
  //   _countdownTimer?.cancel();
  //   _autoCloseTimer?.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    var s = 'Do you want to cancel this post? ';
    String translated = ref.watch(autoTranslationTextProvider(s)).value ?? s;
    return
    // FadeTransition(
    // opacity: _opacityAnimation,
    // child:
    Dialog(
      insetPadding: EdgeInsets.all(12),
      backgroundColor: widget.theme.dialogTheme.backgroundColor,
      shape: widget.theme.dialogTheme.shape,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(translated, style: widget.theme.textTheme.bodyLarge, textAlign: TextAlign.left),
            const SizedBox(height: 18),
            Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  IconAction(text: "CANCEL", onTap: widget.onCancel, type: IAB.cancel, icon: Icons.cancel_outlined),
                  IconAction(text: "Publish", onTap: widget.onContinue, type: IAB.success, icon: Icons.send_outlined),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: _cancelEnabled ? widget.theme.colorScheme.error : widget.theme.colorScheme.error.withOpacity(0.5),
                  //       foregroundColor: widget.theme.colorScheme.onError,
                  //     ),
                  //     onPressed: _cancelEnabled
                  //         ? () {
                  //             widget.onCancel();
                  //           }
                  //         : null,
                  //     child: const Text('CANCEL'),
                  //   ),
                  // ),
                  // const SizedBox(width: 12),
                  // Expanded(
                  //   child: ElevatedButton(
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: widget.theme.colorScheme.primary,
                  //       foregroundColor: widget.theme.colorScheme.onPrimary,
                  //     ),
                  //     onPressed: () {
                  //       widget.onContinue();
                  //     },
                  //     child: const Text('PUBLISH'),
                  //   ),
                  // ),
                ],
              ),
            ),
          ],
        ),
        // ),
      ),
    );
  }
}

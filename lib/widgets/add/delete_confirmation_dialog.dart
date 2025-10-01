import 'dart:async';

import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final ThemeData theme;
  final VoidCallback onCancel;
  final VoidCallback onContinue;

  const DeleteConfirmationDialog({Key? key, required this.theme, required this.onCancel, required this.onContinue}) : super(key: key);

  @override
  _DeleteConfirmationDialogState createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  int _countdown = 1;
  bool _cancelEnabled = false;
  Timer? _countdownTimer;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
    _startTimers();
  }

  void _startTimers() {
    // Countdown timer for delete button
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() => _cancelEnabled = true);
      }
    });

    // Auto-close timer
    _autoCloseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _countdownTimer?.cancel();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Dialog(
        backgroundColor: widget.theme.dialogTheme.backgroundColor,
        shape: widget.theme.dialogTheme.shape,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text('', style: widget.theme.textTheme.titleMedium),
              //     IconButton(
              //       icon: const Icon(Icons.close),
              //       onPressed: () {
              //         Navigator.of(context).pop();
              //       },
              //     ),
              //   ],
              // ),
              //
              // const SizedBox(height: 16),
              Text('Do you want to cancel this post? ', style: widget.theme.textTheme.bodyLarge, textAlign: TextAlign.left),

              const SizedBox(height: 16),

              // Countdown display
              // _deleteEnabled
              //     ? SizedBox(height: 22)
              //     : Text(
              //         'Delete button enabled in: $_countdown',
              //         style: widget.theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400, color: widget.theme.colorScheme.primary),
              //       ),
              //
              // const SizedBox(height: 24),

              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _cancelEnabled ? widget.theme.colorScheme.error : widget.theme.colorScheme.error.withOpacity(0.5),
                        foregroundColor: widget.theme.colorScheme.onError,
                      ),
                      onPressed: _cancelEnabled
                          ? () {
                              widget.onCancel();
                            }
                          : null,
                      child: const Text('CANCEL'),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.colorScheme.primary,
                        foregroundColor: widget.theme.colorScheme.onPrimary,
                      ),
                      onPressed: () {
                        widget.onContinue();
                      },
                      child: const Text('PUBLISH'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final ThemeData theme;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const DeleteConfirmationDialog({Key? key, required this.theme, required this.onDelete, required this.onCancel}) : super(key: key);

  @override
  _DeleteConfirmationDialogState createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  int _countdown = 5;
  bool _deleteEnabled = false;
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
        setState(() => _deleteEnabled = true);
      }
    });

    // Auto-close timer
    _autoCloseTimer = Timer(const Duration(seconds: 15), () {
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cancel Post?', style: widget.theme.textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                'Are you sure you want to cancel this post? '
                'This action cannot be undone.',
                style: widget.theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Countdown display
              Text(
                'Delete button enabled in: $_countdown',
                style: widget.theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: widget.theme.colorScheme.primary),
              ),

              const SizedBox(height: 24),

              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _deleteEnabled ? widget.theme.colorScheme.error : widget.theme.colorScheme.error.withOpacity(0.5),
                        foregroundColor: widget.theme.colorScheme.onError,
                      ),
                      onPressed: _deleteEnabled
                          ? () {
                              widget.onDelete();
                            }
                          : null,
                      child: const Text('DELETE POST'),
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
                        widget.onCancel();
                      },
                      child: const Text('KEEP EDITING'),
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'add_post_providers.dart';
import 'clipboard_provider.dart';

class ClipboardMonitoringDialog extends ConsumerStatefulWidget {
  final String title;
  final TextEditingController controller;
  final String hint;
  final ThemeData theme;
  final TextTheme textTheme;
  final VoidCallback onClearInputs;

  const ClipboardMonitoringDialog({
    Key? key,
    required this.title,
    required this.controller,
    required this.hint,
    required this.theme,
    required this.textTheme,
    required this.onClearInputs,
  }) : super(key: key);

  @override
  ConsumerState<ClipboardMonitoringDialog> createState() => _ClipboardMonitoringDialogState();
}

class _ClipboardMonitoringDialogState extends ConsumerState<ClipboardMonitoringDialog> {
  Timer? _clipboardTimer;
  bool _dialogOpen = true;
  bool _hasValidInput = false;
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
    _setupClipboardMonitoring();
  }

  void _setupClipboardMonitoring() {
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_dialogOpen && mounted) {
        ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleProviderChange(previous, next) {
    if (next is String && next.isNotEmpty && _dialogOpen && mounted) {
      // Use post-frame callback to avoid navigator conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  void _validateInput() {
    final text = widget.controller.text;
    final hasValidUrl = _isValidUrl(text);

    if (_hasValidInput != hasValidUrl) {
      setState(() {
        _hasValidInput = hasValidUrl;
      });
    }
  }

  bool _isValidUrl(String text) {
    // Implement your URL validation logic here
    // You can reuse the same logic from your ClipboardNotifier
    // final ytId = YoutubePlayer.convertUrlToId(text);
    // if (ytId != null && ytId.isNotEmpty) return true;

    // Add other validation checks (Imgur, IPFS, Odysee, etc.)
    //TODO check if this method can be removed as there should be only valid data inside the notifiers already
    return true;
  }

  @override
  void dispose() {
    _dialogOpen = false;
    _clipboardTimer?.cancel();
    widget.controller.removeListener(_validateInput);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isListening) {
      isListening = true;

      ref.listen(youtubeVideoIdProvider, _handleProviderChange);
      ref.listen(imgurUrlProvider, _handleProviderChange);
      ref.listen(ipfsCidProvider, _handleProviderChange);
      ref.listen(odyseeUrlProvider, _handleProviderChange);
    }

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextInputFieldAddDialog(
            textEditingController: widget.controller,
            hintText: widget.hint,
            textInputType: TextInputType.url,
            borderColor: _hasValidInput ? null : Colors.red,
            errorText: _hasValidInput ? null : 'Please enter a valid URL',
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('CLOSE', style: widget.textTheme.labelMedium!.copyWith(color: widget.theme.colorScheme.error)),
        ),
        TextButton(
          onPressed: widget.onClearInputs,
          child: Text('RESET', style: widget.textTheme.labelMedium!.copyWith(color: Colors.yellow[900])),
        ),
        TextButton(
          onPressed: _hasValidInput ? () => Navigator.of(context).pop() : null,
          child: Text(
            'DONE',
            style: widget.textTheme.labelLarge!.copyWith(
              color: _hasValidInput ? widget.theme.colorScheme.primary : widget.theme.colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
        ),
      ],
    );
  }
}

class TextInputFieldAddDialog extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final TextInputType textInputType;
  final Color? borderColor;
  final String? errorText;

  const TextInputFieldAddDialog({
    required this.textEditingController,
    required this.hintText,
    required this.textInputType,
    this.borderColor,
    this.errorText,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: textEditingController,
      decoration: InputDecoration(
        hintText: hintText,
        border: const OutlineInputBorder(),
        focusedBorder: borderColor != null ? OutlineInputBorder(borderSide: BorderSide(color: borderColor!, width: 2.0)) : null,
        enabledBorder: borderColor != null ? OutlineInputBorder(borderSide: BorderSide(color: borderColor!, width: 1.0)) : null,
        errorText: errorText,
        errorStyle: const TextStyle(letterSpacing: 1.2, height: 3),
      ),
      keyboardType: textInputType,
    );
  }
}

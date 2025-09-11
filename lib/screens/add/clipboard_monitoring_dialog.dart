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

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateInput);
    _setupClipboardMonitoring();
  }

  void _setupClipboardMonitoring() {
    // Set up periodic clipboard checking
    _clipboardTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_dialogOpen && mounted) {
        ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
      } else {
        timer.cancel();
      }
    });
  }

  void listenToMediaProviders() {
    ref.listen(youtubeVideoIdProvider, _handleProviderChange);
    ref.listen(imgurUrlProvider, _handleProviderChange);
    ref.listen(ipfsCidProvider, _handleProviderChange);
    ref.listen(odyseeUrlProvider, _handleProviderChange);
  }

  void _handleProviderChange(previous, next) {
    if (next is String && next.isNotEmpty && _dialogOpen && mounted) {
      Navigator.of(context).pop();
    }
  }

  //TODO VALIDATION IS ALREADY DONE BEFORE THE PROVIDERS ARE FILLED, THEY ONLY CONTAIN VALID URLS
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
    // // Check if any of the providers would recognize this as valid
    // final ytId = ref.read(clipboardNotifierProvider.notifier).extractYoutubeId(text);
    // if (ytId != null && ytId.isNotEmpty) return true;
    //
    // final imgur = ref.read(clipboardNotifierProvider.notifier).extractImgurOrGiphyUrl(text);
    // if (imgur.isNotEmpty) return true;
    //
    // final ipfsCid = ref.read(clipboardNotifierProvider.notifier).extractIpfsCid(text);
    // if (ipfsCid.isNotEmpty) return true;
    //
    // final odyseeUrl = ref.read(clipboardNotifierProvider.notifier).extractOdyseeUrl(text);
    // if (odyseeUrl.isNotEmpty) return true;

    return false;
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
    // Listen to all media providers
    listenToMediaProviders();

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
          // if (!_hasValidInput && widget.controller.text.isNotEmpty)
          //   Text(
          //     'Enter a valid YouTube, Imgur, Giphy, IPFS, or Odysee URL',
          //     style: widget.textTheme.bodySmall?.copyWith(color: Colors.red, fontSize: 12),
          //   ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            widget.onClearInputs();
            Navigator.of(context).pop();
          },
          child: Text('Cancel', style: widget.textTheme.labelMedium!.copyWith(color: widget.theme.colorScheme.error)),
        ),
        TextButton(
          onPressed: _hasValidInput
              ? () {
                  Navigator.of(context).pop();
                }
              : null,
          child: Text(
            'Done',
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
        border: OutlineInputBorder(),
        focusedBorder: borderColor != null ? OutlineInputBorder(borderSide: BorderSide(color: borderColor!, width: 2.0)) : null,
        enabledBorder: borderColor != null ? OutlineInputBorder(borderSide: BorderSide(color: borderColor!, width: 1.0)) : null,
        errorText: errorText,
        errorStyle: TextStyle(letterSpacing: 1.2, height: 3),
      ),
      keyboardType: textInputType,
    );
  }
}

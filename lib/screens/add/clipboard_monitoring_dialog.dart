// clipboard_monitoring_dialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/screens/add/media_placeholder_widget.dart';
import 'package:mahakka/screens/add/text_input_add.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../../provider/url_input_verification_notifier.dart';
import 'add_post_providers.dart';
import 'clipboard_provider.dart';

class ClipboardMonitoringDialog extends ConsumerStatefulWidget {
  final String title;
  final String hint;
  final ThemeData theme;
  final TextTheme textTheme;
  final VoidCallback? onCreate;
  final VoidCallback? onReuse;

  const ClipboardMonitoringDialog({
    Key? key,
    required this.title,
    required this.hint,
    required this.theme,
    required this.textTheme,
    this.onCreate,
    this.onReuse,
  }) : super(key: key);

  @override
  ConsumerState<ClipboardMonitoringDialog> createState() => _ClipboardMonitoringDialogState();
}

class _ClipboardMonitoringDialogState extends ConsumerState<ClipboardMonitoringDialog> {
  Timer? _clipboardTimer;
  bool _dialogOpen = true;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onInputChanged);
    _setupClipboardMonitoring();
  }

  void _onInputChanged() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      ref.read(urlInputVerificationProvider.notifier).verifyAndProcessInput(ref, text);
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(_dialogCtx)) {
          Navigator.of(_dialogCtx).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _dialogOpen = false;
    _clipboardTimer?.cancel();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  late BuildContext _dialogCtx;

  @override
  Widget build(BuildContext dialogCtx) {
    _dialogCtx = dialogCtx;

    final hasValidInput = ref.watch(urlInputVerificationProvider.select((state) => state.hasValidInput));

    // Listen to media provider changes
    ref.listen(youtubeVideoIdProvider, _handleProviderChange);
    ref.listen(imgurUrlProvider, _handleProviderChange);
    ref.listen(ipfsCidProvider, _handleProviderChange);
    ref.listen(odyseeUrlProvider, _handleProviderChange);

    final hasOptions = widget.onCreate != null || widget.onReuse != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(widget.title, style: theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.w400, letterSpacing: 1)),
      backgroundColor: widget.theme.scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasOptions) _buildOptionsRow(theme, colorScheme),
          if (hasOptions) const SizedBox(height: 16),
          TextInputFieldAddDialog(
            textEditingController: _controller,
            hintText: widget.hint,
            textInputType: TextInputType.url,
            borderColor: hasValidInput ? null : Colors.red,
            errorText: hasValidInput
                ? null
                : 'Paste a valid' + (widget.title.toLowerCase().contains("ipfs") ? " Ipfs Content Id" : " Url link"),
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(_dialogCtx).pop(),
          child: Text('CLOSE', style: widget.textTheme.labelMedium!.copyWith(color: widget.theme.colorScheme.error)),
        ),
        TextButton(
          onPressed: () {
            _controller.clear();
            ref.read(urlInputVerificationProvider.notifier).reset(ref);
          },
          child: Text('RESET', style: widget.textTheme.labelMedium!.copyWith(color: Colors.yellow[900])),
        ),
        TextButton(
          onPressed: hasValidInput
              ? () => Navigator.of(_dialogCtx).pop()
              : () => showSnackBar("Go and copy a valid link, then paste it here!", context, type: SnackbarType.error),
          child: Text(
            'DONE',
            style: widget.textTheme.labelLarge!.copyWith(
              color: hasValidInput ? widget.theme.colorScheme.primary : widget.theme.colorScheme.onSurface.withOpacity(0.38),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsRow(ThemeData theme, ColorScheme colorScheme) {
    return Row(
      children: [
        if (widget.onCreate != null)
          MediaPlaceholderWidget(
            label: "CREATE",
            iconData: Icons.add,
            onTap: () {
              Navigator.of(_dialogCtx).pop();
              widget.onCreate!();
            },
          ),
        if (widget.onCreate != null && widget.onReuse != null) const SizedBox(width: 12),
        if (widget.onReuse != null)
          MediaPlaceholderWidget(
            label: "GALLERY",
            iconData: Icons.image_search,
            onTap: () {
              Navigator.of(_dialogCtx).pop();
              widget.onReuse!();
            },
          ),
      ],
    );
  }
}

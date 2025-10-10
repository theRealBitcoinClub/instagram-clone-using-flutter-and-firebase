// clipboard_monitoring_widget.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/provider/translation_service.dart';
import 'package:mahakka/screens/add/media_placeholder_widget.dart';
import 'package:mahakka/screens/add/text_input_add.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../../provider/url_input_verification_notifier.dart';
import 'add_post_providers.dart';
import 'clipboard_provider.dart';

class ClipboardMonitoringWidget extends ConsumerStatefulWidget {
  final String title;
  final String hint;
  final VoidCallback? onCreate;
  final VoidCallback? onGallery;

  const ClipboardMonitoringWidget({Key? key, required this.title, required this.hint, this.onCreate, this.onGallery}) : super(key: key);

  @override
  ConsumerState<ClipboardMonitoringWidget> createState() => _ClipboardMonitoringWidgetState();
}

class _ClipboardMonitoringWidgetState extends ConsumerState<ClipboardMonitoringWidget> {
  Timer? _clipboardTimer;
  late TextEditingController _controller;
  bool _hasAutoClosed = false;

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
      if (mounted) {
        ref.read(clipboardNotifierProvider.notifier).checkClipboard(ref);
      }
    });
  }

  void _handleProviderChange(previous, next) {
    if (next is String && next.isNotEmpty && mounted && !_hasAutoClosed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasAutoClosed = true;
          });
          // Show success feedback instead of closing
          ref.read(snackbarServiceProvider).showTranslatedSnackBar("Media detected successfully!", type: SnackbarType.success);
        }
      });
    }
  }

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasValidInput = ref.watch(urlInputVerificationProvider.select((state) => state.hasValidInput));
    String error = hasValidInput ? "" : 'Paste a valid' + (widget.title.toLowerCase().contains("ipfs") ? " Ipfs Content Id" : " Url link");
    String displayError = ref.watch(autoTranslationTextProvider(error)).value ?? error;
    String displayTitle = ref.watch(autoTranslationTextProvider(widget.title)).value ?? widget.title;

    // Listen to media provider changes for auto-success feedback
    ref.listen(youtubeVideoIdProvider, _handleProviderChange);
    ref.listen(imgurUrlProvider, _handleProviderChange);
    ref.listen(ipfsCidProvider, _handleProviderChange);
    ref.listen(odyseeUrlProvider, _handleProviderChange);

    final hasOptions = widget.onCreate != null || widget.onGallery != null;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(displayTitle, style: theme.textTheme.titleMedium),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextInputFieldAddDialog(
                  textEditingController: _controller,
                  hintText: widget.hint,
                  textInputType: TextInputType.url,
                  errorText: displayError,
                ),
              ),
            ],
          ),

          if (hasOptions) ...[_buildOptionsRow(theme), const SizedBox(height: 12)],
        ],
      ),
    );
  }

  Widget _buildOptionsRow(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Row(
        children: [
          if (widget.onCreate != null) MediaPlaceholderWidget(label: "UPLOAD", iconData: Icons.cloud_upload_outlined, onTap: widget.onCreate!),
          if (widget.onCreate != null && widget.onGallery != null) const SizedBox(width: 12),
          if (widget.onGallery != null) MediaPlaceholderWidget(label: "GALLERY", iconData: Icons.image_search, onTap: widget.onGallery!),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';
import 'package:mahakka/views_taggable/view_models/search_view_model.dart';
import 'package:mahakka/views_taggable/widgets/comment_text_field.dart';
import 'package:mahakka/views_taggable/widgets/search_result_overlay.dart';

class TaggableInputWidget extends ConsumerStatefulWidget {
  final FlutterTaggerController textInputController;
  final AnimationController animationController;
  final FocusNode focusNode;
  final EdgeInsets viewInsets;
  final VoidCallback onPublish;
  final double overlayHeight;

  const TaggableInputWidget({
    Key? key,
    required this.textInputController,
    required this.animationController,
    required this.focusNode,
    required this.viewInsets,
    required this.onPublish,
    this.overlayHeight = 300,
  }) : super(key: key);

  @override
  ConsumerState<TaggableInputWidget> createState() => _TaggableInputWidgetState();
}

class _TaggableInputWidgetState extends ConsumerState<TaggableInputWidget> with SingleTickerProviderStateMixin {
  late Animation<Offset> _taggerOverlayAnimation;
  late SearchViewModel searchViewModel;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    searchViewModel = SearchViewModel();
  }

  void _initAnimations() {
    _taggerOverlayAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: widget.animationController, curve: Curves.easeInOutSine));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final TextTheme textTheme = theme.textTheme;

    return Material(
      elevation: 4.0,
      color: theme.cardColor,
      shadowColor: theme.shadowColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FlutterTagger(
          triggerStrategy: TriggerStrategy.eager,
          controller: widget.textInputController,
          animationController: widget.animationController,
          onSearch: (query, triggerChar) {
            if (triggerChar == "@") {
              searchViewModel.searchTopic(query);
            } else if (triggerChar == "#") {
              searchViewModel.searchHashtag(query);
            }
          },
          triggerCharacterAndStyles: {
            "@": textTheme.bodyLarge!.copyWith(color: colorScheme.secondary, fontWeight: FontWeight.bold),
            "#": textTheme.bodyLarge!.copyWith(color: colorScheme.tertiary, fontWeight: FontWeight.bold),
          },
          tagTextFormatter: (id, tag, triggerChar) {
            return "$triggerChar$id#$tag#";
          },
          overlayHeight: widget.overlayHeight,
          overlay: SearchResultOverlay(animation: _taggerOverlayAnimation, tagController: widget.textInputController),
          builder: (context, containerKey) {
            return CommentTextField(
              onInputText: (value) {
                if (!mounted) return;
                if (value.contains('\n')) {
                  widget.textInputController.text = value.replaceAll("\n", "");
                  widget.onPublish();
                }
              },
              focusNode: widget.focusNode,
              containerKey: containerKey,
              insets: widget.viewInsets,
              controller: widget.textInputController,
              hintText: "Add a caption... use @ for topics, # for tags",
              onSend: widget.onPublish,
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchViewModel.clearSearch();
    super.dispose();
  }
}

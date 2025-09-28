// widgets/base_scrollable_list_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class BaseScrollableListView extends ConsumerStatefulWidget {
  final double scrollAmount;
  final double scrollButtonWidth;

  const BaseScrollableListView({Key? key, this.scrollAmount = 50.0, this.scrollButtonWidth = 40.0}) : super(key: key);
}

abstract class BaseScrollableListViewState<T extends BaseScrollableListView> extends ConsumerState<T> {
  final ScrollController _scrollController = ScrollController();
  late final double _scrollAmount;
  late final double _scrollButtonWidth;

  @override
  void initState() {
    super.initState();
    _scrollAmount = widget.scrollAmount;
    _scrollButtonWidth = widget.scrollButtonWidth;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void scrollUp() {
    _scrollController.animateTo(_scrollController.offset - _scrollAmount, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void scrollDown() {
    _scrollController.animateTo(_scrollController.offset + _scrollAmount, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  bool get canScrollUp => _scrollController.hasClients && _scrollController.offset > 0;

  bool get canScrollDown {
    if (!_scrollController.hasClients) return false;
    return _scrollController.offset < _scrollController.position.maxScrollExtent;
  }

  // Abstract methods that subclasses must implement
  Widget buildContent(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme);
  Widget buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme);
  Widget buildLoadingState(BuildContext context, ThemeData theme, ColorScheme colorScheme, TextTheme textTheme);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Stack(
      children: [
        // Scrollable content with right padding to avoid overlap
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.vertical,
          child: Container(
            padding: EdgeInsets.only(top: 0, bottom: 8, left: 0, right: _scrollButtonWidth + 8),
            width: double.infinity,
            child: buildContent(context, theme, colorScheme, textTheme),
          ),
        ),

        // Scroll up indicator
        Positioned(
          top: 8,
          right: 8,
          child: AnimatedOpacity(
            opacity: canScrollUp ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: canScrollUp ? scrollUp : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: canScrollUp ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Scroll down indicator
        Positioned(
          bottom: 8,
          right: 8,
          child: AnimatedOpacity(
            opacity: canScrollDown ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: Material(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: canScrollDown ? scrollDown : null,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 1),
                  ),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: canScrollDown ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

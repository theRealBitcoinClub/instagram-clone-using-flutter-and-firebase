import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/post_update_provider.dart';

class PopularityScoreWidget extends ConsumerStatefulWidget {
  final String? postId; // Optional - when provided, enables auto-refresh
  final int initialScore;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final int maxLines;
  final bool softWrap;
  final TextOverflow overflow;
  final bool textStyleBalance;

  const PopularityScoreWidget({
    Key? key,
    this.postId, // Make postId optional
    required this.initialScore,
    this.textStyle,
    this.textStyleBalance = false,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.softWrap = false,
    this.overflow = TextOverflow.clip,
  }) : super(key: key);

  @override
  ConsumerState<PopularityScoreWidget> createState() => _PopularityScoreWidgetState();

  static String formatPopularityScore(int score) {
    if (score >= 1000000) {
      final double millions = score / 1000000;
      if (millions >= 10) {
        return '${millions.toStringAsFixed(0)}M';
      } else if (millions >= 1) {
        return '${millions.toStringAsFixed(1)}M'.replaceAll('.0', '');
      } else {
        return '${millions.toStringAsFixed(2)}M'.replaceAll(RegExp(r'\.0+$'), '');
      }
    } else if (score >= 1000) {
      final double thousands = score / 1000;
      if (thousands >= 10) {
        return '${thousands.toStringAsFixed(0)}K';
      } else if (thousands >= 1) {
        return '${thousands.toStringAsFixed(1)}K'.replaceAll('.0', '');
      } else {
        return '${thousands.toStringAsFixed(2)}K'.replaceAll(RegExp(r'\.0+$'), '');
      }
    } else {
      return score == -1 ? "?" : score.toString();
    }
  }
}

class _PopularityScoreWidgetState extends ConsumerState<PopularityScoreWidget> {
  @override
  void initState() {
    super.initState();

    // Only trigger auto-refresh if postId is provided
    if (widget.postId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(postPopularityProvider.notifier).fetchPopularityScore(widget.postId!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If postId is provided, watch for updates, otherwise use initial score
    final int displayScore;

    if (widget.postId != null) {
      final popularityUpdates = ref.watch(postPopularityProvider);
      displayScore = popularityUpdates[widget.postId!] ?? widget.initialScore;
    } else {
      displayScore = widget.initialScore;
    }

    final String formattedScore = PopularityScoreWidget.formatPopularityScore(displayScore);

    final ThemeData theme = Theme.of(context);
    TextStyle effectiveStyle;
    if (widget.textStyleBalance) {
      effectiveStyle = widget.textStyle ?? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400) ?? const TextStyle();
    } else {
      effectiveStyle = widget.textStyle ?? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w400) ?? const TextStyle();
    }

    return Text(
      formattedScore,
      style: effectiveStyle,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      softWrap: widget.softWrap,
      overflow: widget.overflow,
    );
  }
}

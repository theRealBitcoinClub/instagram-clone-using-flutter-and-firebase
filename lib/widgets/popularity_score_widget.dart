import 'package:flutter/material.dart';

class PopularityScoreWidget extends StatelessWidget {
  final int score;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final int maxLines;
  final bool softWrap;
  final TextOverflow overflow;
  final bool textStyleBalance;

  const PopularityScoreWidget({
    Key? key,
    required this.score,
    this.textStyle,
    this.textStyleBalance = false,
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.softWrap = false,
    this.overflow = TextOverflow.clip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String formattedScore = _formatPopularityScore(score);

    // Determine which style to use based on the score magnitude
    TextStyle effectiveStyle;

    // if (score >= 1000000 && largeNumberStyle != null) {
    //   effectiveStyle = largeNumberStyle!;
    // } else if (score >= 1000 && mediumNumberStyle != null) {
    //   effectiveStyle = mediumNumberStyle!;
    // } else if (smallNumberStyle != null) {
    //   effectiveStyle = smallNumberStyle!;
    // } else {
    if (textStyleBalance)
      effectiveStyle = textStyle ?? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w400) ?? const TextStyle();
    else
      effectiveStyle = textStyle ?? theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w400) ?? const TextStyle();
    // }

    return Text(formattedScore, style: effectiveStyle, textAlign: textAlign, maxLines: maxLines, softWrap: softWrap, overflow: overflow);
  }

  String _formatPopularityScore(int score) {
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

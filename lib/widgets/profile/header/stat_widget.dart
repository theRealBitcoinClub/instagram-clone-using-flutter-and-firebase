import 'package:flutter/material.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';

class StatWidget extends StatelessWidget {
  final String title;
  final int count;
  final ThemeData theme;

  const StatWidget({Key? key, required this.title, required this.count, required this.theme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 0.0, bottom: 2.0),
          child: PopularityScoreWidget(score: count, textStyleBalance: true),
        ),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';

class StatWidget extends StatelessWidget {
  final String title;
  final int count;
  final bool hasDecimals;
  final ThemeData theme;
  final onTap;

  const StatWidget({Key? key, required this.title, required this.count, required this.theme, required this.onTap, this.hasDecimals = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(33),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0, bottom: 0),
                child: PopularityScoreWidget(initialScore: count, textStyleBalance: true, hasDecimals: hasDecimals),
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

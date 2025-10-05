// lib/widgets/limit_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/limit_info_widget.dart';

class LimitInfoDialog extends ConsumerWidget {
  final LimitType limitType;

  const LimitInfoDialog({Key? key, required this.limitType}) : super(key: key);

  static Future<void> show({required BuildContext context, required LimitType limitType}) {
    return showDialog(
      context: context,
      builder: (context) => LimitInfoDialog(limitType: limitType),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Dialog(
      insetPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 3),
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [LimitInfoWidget(limitType: limitType, compact: false)],
        ),
      ),
    );
  }
}

// lib/widgets/limit_info_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
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
    final tokenEnum = ref.watch(currentTokenLimitEnumProvider);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row(
            //   children: [
            //     Icon(Icons.workspace_premium, color: theme.colorScheme.secondary, size: 28),
            //     const SizedBox(width: 12),
            //     Expanded(
            //       child: Text(
            //         '${tokenEnum.name} Plan Limits',
            //         style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface),
            //       ),
            //     ),
            //     IconButton(
            //       icon: Icon(Icons.close, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            //       onPressed: () => Navigator.of(context).pop(),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 16),
            LimitInfoWidget(limitType: limitType, compact: false),
          ],
        ),
      ),
    );
  }
}

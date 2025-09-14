import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memo/base/memo_accountant.dart';
import '../../memo/base/memo_bitcoin_base.dart';
import '../../memo/model/memo_model_post.dart';
import '../../memo/model/memo_model_user.dart';
import '../../memo/model/memo_tip.dart';
import '../../screens/add/add_post_providers.dart';

class TipInformationCard extends ConsumerWidget {
  final MemoModelPost post;
  final MemoModelUser user;

  const TipInformationCard({Key? key, required this.post, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final temporaryTipAmount = ref.watch(temporaryTipAmountProvider);

    final tipAmount = temporaryTipAmount ?? user.tipAmountEnum;
    final tipTotalAmount = tipAmount.value;

    final tips = ref.read(memoAccountantProvider).parseTips(post: post, tipTotalAmountArg: tipTotalAmount, receiverArg: user.tipReceiver);

    // Calculate percentages for visual representation
    final (burnPct, creatorPct) = user.tipReceiver.calculateAmounts(100);
    final burnPercentage = burnPct;
    final creatorPercentage = creatorPct;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.attach_money_rounded, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tip Distribution',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total amount
            _buildInfoRow('Total Tip Amount:', '${_formatSatoshi(tipTotalAmount)} satoshis', theme),

            const SizedBox(height: 12),

            // Distribution type
            _buildInfoRow('Distribution:', user.tipReceiver.displayName, theme),

            const SizedBox(height: 16),

            // Visual percentage bar
            _buildPercentageBar(burnPercentage, creatorPercentage, theme),

            const SizedBox(height: 12),

            // Percentage breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Burned: ${(user.tipReceiver.burnPercentage * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Creator: ${(user.tipReceiver.creatorPercentage * 100).round()}%',
                  style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Breakdown
            if (tips.isNotEmpty) ...[
              Text(
                'Amount Breakdown:',
                style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface.withOpacity(0.8)),
              ),

              const SizedBox(height: 8),

              ...tips.map((tip) => _buildTipBreakdownRow(tip, theme)).toList(),
            ],

            const SizedBox(height: 8),

            // Note about temporary tip
            if (temporaryTipAmount != null)
              Text(
                '⚠️ Custom tip amount for this post only',
                style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageBar(int burnPercentage, int creatorPercentage, ThemeData theme) {
    return Container(
      height: 8,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), color: theme.colorScheme.surfaceVariant),
      child: Row(
        children: [
          if (burnPercentage > 0)
            Expanded(
              flex: burnPercentage,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          if (creatorPercentage > 0)
            Expanded(
              flex: creatorPercentage,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withOpacity(0.7)),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildTipBreakdownRow(MemoTip tip, ThemeData theme) {
    final isBurn = tip.receiverAddress == MemoBitcoinBase.bchBurnerAddress;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isBurn ? Icons.local_fire_department : Icons.person,
                size: 16,
                color: isBurn ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                isBurn ? 'Burned' : 'To Creator',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
          Text(
            '${_formatSatoshi(tip.amountInSats)} sat',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isBurn ? theme.colorScheme.error : theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSatoshi(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

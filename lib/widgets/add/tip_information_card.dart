import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memo/base/memo_accountant.dart';
import '../../memo/base/memo_bitcoin_base.dart';
import '../../memo/model/memo_model_post.dart';
import '../../memo/model/memo_tip.dart';
import '../../provider/user_provider.dart';
import '../../screens/add/add_post_providers.dart';

// Assuming you have a user provider somewhere, if not, you'll need to create one
// For example: final userProvider = StateProvider<MemoModelUser>((ref) => MemoModelUser());

class TipInformationCard extends ConsumerWidget {
  final MemoModelPost post;
  var burnColor;
  var creatorColor;

  TipInformationCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the user provider to get updates when user changes
    final user = ref.watch(userProvider)!;
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
    burnColor = theme.colorScheme.primary;
    creatorColor = theme.colorScheme.secondary;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (temporaryTipAmount != user.tipAmountEnum)
              Text(
                '⚠️ Custom tip amount for this post only',
                style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary, fontStyle: FontStyle.italic),
              ),

            const SizedBox(height: 8),

            // Total amount
            _buildInfoRow('Tip Total', '${_formatSatoshi(tipTotalAmount)} satoshis', theme),

            const SizedBox(height: 16),

            // Visual percentage bar
            _buildPercentageBar(burnPercentage, creatorPercentage, theme),

            // Breakdown
            if (tips.isNotEmpty) ...[const SizedBox(height: 8), ...tips.map((tip) => _buildTipBreakdownRow(tip, theme)).toList()],

            const SizedBox(height: 8),
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
                  color: burnColor,
                ),
              ),
            ),
          if (creatorPercentage > 0)
            Expanded(
              flex: creatorPercentage,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                  color: creatorColor,
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
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
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
              Icon(isBurn ? Icons.local_fire_department : Icons.person, size: 16, color: isBurn ? burnColor : creatorColor),
              const SizedBox(width: 8),
              Text(
                isBurn ? 'Burned' : 'To Creator',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],
          ),
          Text(
            '${_formatSatoshi(tip.amountInSats)} sat',
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: isBurn ? burnColor : creatorColor),
          ),
        ],
      ),
    );
  }

  String _formatSatoshi(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

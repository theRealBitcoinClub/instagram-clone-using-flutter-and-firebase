import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../memo/base/memo_accountant.dart';
import '../../memo/base/memo_bitcoin_base.dart';
import '../../memo/model/memo_model_post.dart';
import '../../memo/model/memo_tip.dart';
import '../../provider/user_provider.dart';
import '../animations/animated_grow_fade_in.dart';

class TipInformationCard extends ConsumerWidget {
  final MemoModelPost post;
  final bool isPostCreationNotReply;

  const TipInformationCard({Key? key, required this.post, required this.isPostCreationNotReply}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final tipAmount = user.temporaryTipAmount ?? user.tipAmountEnum;
    final tipTotalAmount = tipAmount.value;

    final tips = ref
        .read(memoAccountantProvider)
        .parseTips(creatorId: isPostCreationNotReply ? null : (post.creatorId.isNotEmpty ? post.creatorId : post.creator!.id));

    // Calculate percentages for visual representation
    final (burnPct, creatorPct) = user.temporaryTipReceiver != null
        ? user.temporaryTipReceiver!.calculateAmounts(100)
        : user.tipReceiver.calculateAmounts(100);
    final burnPercentage = isPostCreationNotReply ? 100 : burnPct;
    final creatorPercentage = isPostCreationNotReply ? 0 : creatorPct;
    final burnColor = theme.colorScheme.primary;
    final creatorColor = theme.colorScheme.secondary;

    final showCustomTipWarning =
        (user.temporaryTipAmount != null && user.temporaryTipAmount != user.tipAmountEnumPersistent) ||
        (user.temporaryTipReceiver != null && user.temporaryTipReceiver != user.tipReceiverPersistent);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Custom tip warning with grow/fade animation
            AnimGrowFade(
              show: showCustomTipWarning,
              // duration: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  Text(
                    '⚠️ Custom tip ' + (isPostCreationNotReply ? '' : '& receiver ') + 'for this post only',
                    style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withAlpha(222), fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Total amount with animation
            _buildAnimatedInfoRow('Tip Total', '${_formatSatoshi(tipTotalAmount)} satoshis', theme, tipTotalAmount),

            const SizedBox(height: 16),

            // Visual percentage bar with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: KeyedSubtree(
                key: ValueKey('${burnPercentage}_${creatorPercentage}'),
                child: _buildPercentageBar(burnPercentage, creatorPercentage, burnColor, creatorColor, theme),
              ),
            ),

            // Breakdown with animations
            if (tips.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...tips
                  .map((tip) => _buildAnimatedTipBreakdownRow(tip, burnColor, creatorColor, theme, creatorPercentage, burnPercentage))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedInfoRow(String label, String value, ThemeData theme, int tipTotalAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            value,
            key: ValueKey(tipTotalAmount),
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedTipBreakdownRow(
    MemoTip tip,
    Color burnColor,
    Color creatorColor,
    ThemeData theme,
    int creatorPercentage,
    int burnPercentage,
  ) {
    final isBurn = tip.receiverAddress == MemoBitcoinBase.bchBurnerAddress;

    var colorText = theme.colorScheme.onSurface.withOpacity(0.8);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: KeyedSubtree(
        key: ValueKey('${tip.receiverAddress}_${tip.amountInSats}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(isBurn ? Icons.local_fire_department : Icons.person, size: 22, color: isBurn ? burnColor : creatorColor),
                  const SizedBox(width: 4),
                  Text(
                    isBurn ? '${burnPercentage}% Burned' : '${creatorPercentage}% Creator',
                    style: theme.textTheme.bodySmall?.copyWith(color: colorText),
                  ),
                ],
              ),
              Text(
                '${_formatSatoshi(tip.amountInSats)} sat',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: colorText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageBar(int burnPercentage, int creatorPercentage, Color burnColor, Color creatorColor, ThemeData theme) {
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

  String _formatSatoshi(int amount) {
    return amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

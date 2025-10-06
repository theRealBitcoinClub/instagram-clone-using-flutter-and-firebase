import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/provider/bch_burner_balance_provider.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/theme_provider.dart';
import 'package:mahakka/widgets/popularity_score_widget.dart';

class BurnerBalanceWidget extends ConsumerWidget {
  const BurnerBalanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncThemeState = ref.watch(themeNotifierProvider);
    final currentThemeState = asyncThemeState.maybeWhen(data: (data) => data, orElse: () => defaultThemeState);
    final ThemeData theme = currentThemeState.currentTheme;
    final asyncBurnerBalance = ref.watch(bchBurnerBalanceProvider);
    return GestureDetector(
      onTap: () =>
          ref.read(navigationStateProvider.notifier).navigateToUrl("${MemoBitcoinBase.explorerUrl}${MemoBitcoinBase.bchBurnerAddress}"),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.currency_bitcoin_outlined, size: 22, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 2.1),
          asyncBurnerBalance.when(
            data: (burnerBalance) {
              return Row(
                children: [
                  PopularityScoreWidget(
                    initialScore: burnerBalance.bch,
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onPrimary),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.local_fire_department_outlined, size: 22, color: theme.colorScheme.onPrimary),
                  const SizedBox(width: 2.1),
                  PopularityScoreWidget(
                    initialScore: burnerBalance.token,
                    textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w400, color: theme.colorScheme.onPrimary),
                  ),
                ],
              );
            },
            error: (error, stackTrace) {
              return Icon(Icons.error_outline, size: 20, color: theme.colorScheme.error);
            },
            loading: () {
              return SizedBox(
                width: 60,
                height: 20,
                child: LinearProgressIndicator(
                  backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                  minHeight: 2,
                ),
              );
            },
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
          ),
        ],
      ),
    );
  }
}

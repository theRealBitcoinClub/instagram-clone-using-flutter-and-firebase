// lib/widgets/limit_info_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/external_browser_launcher.dart';
import 'package:mahakka/memo/base/memo_bitcoin_base.dart';
import 'package:mahakka/provider/user_provider.dart';
import 'package:mahakka/providers/navigation_providers.dart';
import 'package:mahakka/providers/token_limits_provider.dart';
import 'package:mahakka/screens/icon_action_button.dart';
import 'package:mahakka/views_taggable/widgets/qr_code_dialog.dart';
import 'package:mahakka/widgets/animations/animated_grow_fade_in.dart';

import '../provider/translation_service.dart';

class LimitInfoWidget extends ConsumerWidget {
  final LimitType limitType;
  final bool compact;

  const LimitInfoWidget({Key? key, required this.limitType, this.compact = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokenEnum = ref.watch(currentTokenLimitEnumProvider);
    final headerColor = theme.colorScheme.secondary;
    final borderColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurfaceVariant;

    // Get the appropriate text based on limit type
    String limitText = limitType == LimitType.feed ? tokenEnum.feedLimitText : tokenEnum.profileLimitText;

    // Use the async translated text provider with the original text
    final translatedTextAsync = ref.watch(autoTranslationTextProvider(limitText));

    final String title = '${tokenEnum.name} Plan Limit Reached';

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(12),
        // margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.1),
          // border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium, color: headerColor, size: 24),
            const SizedBox(height: 8),
            Text(
              'Limit Reached',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: headerColor, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap for details',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall!.copyWith(color: textColor.withAlpha(222)),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.fromLTRB(6, 3, 6, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.1),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium, color: headerColor, size: 32),
          const SizedBox(height: 9),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: headerColor)),
          const SizedBox(height: 9),
          // Text(
          //   limitText,
          //   textAlign: TextAlign.justify,
          //   style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
          // ),
          // Handle loading and error states for translation
          translatedTextAsync.when(
            data: (translatedText) => AnimGrowFade(
              show: true,
              growDuration: Duration(milliseconds: 0),
              child: Text(
                translatedText,
                textAlign: TextAlign.justify,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
            loading: () => _buildLoadingText(theme, textColor),
            error: (error, stack) => AnimGrowFade(
              show: true,
              growDuration: Duration(milliseconds: 0),
              child: Text(
                limitText, // Fallback to original text
                textAlign: TextAlign.justify,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildLoadingText(ThemeData theme, Color textColor) {
    return Column(
      children: [
        Text('Loading translation...', style: theme.textTheme.bodySmall?.copyWith(color: textColor.withOpacity(0.7))),
        const SizedBox(height: 8),
        SizedBox(height: 100, child: LinearProgressIndicator()),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(9)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconAction(
              text: 'Support',
              onTap: () {
                ExternalBrowserLauncher().launchUrlWithConfirmation(context, "https://t.me/mahakka_com");
              },
              type: IAB.cancel,
              icon: Icons.support_agent_outlined,
            ),
            SizedBox(width: 1),
            IconAction(
              text: 'Swap',
              onTap: () {
                ref.read(navigationStateProvider.notifier).navigateToUrl(MemoBitcoinBase.cauldronSwapTokenUrl);
              },
              type: IAB.alternative,
              icon: Icons.swap_horizontal_circle_outlined,
            ),
            SizedBox(width: 1),
            IconAction(
              text: 'Deposit',
              onTap: () {
                showQrCodeDialog(ctx: context, user: ref.read(userProvider), tokenOnly: true);
              },
              type: IAB.success,
              icon: Icons.qr_code_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

enum LimitType { feed, profile }

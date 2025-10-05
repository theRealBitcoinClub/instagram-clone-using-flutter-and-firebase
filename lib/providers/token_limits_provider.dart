// token_limits_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/repositories/creator_repository.dart';

import '../provider/user_provider.dart';

class TokenLimitConstants {
  // Token amounts for each tier
  static const int freeTokens = 0;
  static const int starterTokens = 222;
  static const int advancedTokens = 1800;
  static const int proTokens = 6000;

  // Feed limits
  static const int freeFeedLimit = 20;
  static const int starterFeedLimit = 30;
  static const int advancedFeedLimit = 42;
  static const int proFeedLimit = 60;

  // Profile limits
  static const int freeProfileLimit = 9;
  static const int starterProfileLimit = 12;
  static const int advancedProfileLimit = 15;
  static const int proProfileLimit = 18;

  // Mute limits
  static const int freeMuteLimit = 3;
  static const int starterMuteLimit = 6;
  static const int advancedMuteLimit = 9;
  static const int proMuteLimit = 12;
}

class TokenLimitTexts {
  // Common phrases
  static const String tokenDepositInfo = 'Tokens stay in your possession and can be moved with your secret key at any time.';
  static const String findMnemonic = 'You find your secret key in the profile settings.';
  static const String muteSuggestion =
      'You can also mute users to fill the list with different content. You can mute a user on their profile page by tapping the badge on their avatar.';
  static const String contactSupport = 'For higher limits, contact @mahakka_com on Telegram.';
  static const String withdrawalInfo = 'Move your tokens with "Cashonize" or "Cauldron" using your secret key.';

  // Reusable templates
  static const String feedLimitReached = 'Maximum visible publications reached for';
  static const String profileLimitReached = 'Profile posts limited to';
  static const String muteLimitReached = 'Maximum mutes reached for';
  static const String depositToUnlock = 'You can deposit';
  static const String tokensFor = 'tokens for:';
  static const String feedSpots = 'feed spots,';
  static const String profilePosts = 'profile posts, mute';
  static const String creators = 'creators';
  static const String depositForTier = 'tokens to unlock';
  static const String tier = 'tier.';
  static const String free = 'FREE';
  static const String starter = 'STARTER';
  static const String premium = 'PREMIUM';
  static const String pro = 'PRO';
  static const String creators2 = 'creators';

  // Benefits descriptions using constants
  static const String starterBenefits =
      '(${TokenLimitConstants.starterFeedLimit} $feedSpots ${TokenLimitConstants.starterProfileLimit} $profilePosts ${TokenLimitConstants.starterMuteLimit} $creators)';
  static const String advancedBenefits =
      '(${TokenLimitConstants.advancedFeedLimit} $feedSpots ${TokenLimitConstants.advancedProfileLimit} $profilePosts ${TokenLimitConstants.advancedMuteLimit} $creators)';
  static const String proBenefits =
      '(${TokenLimitConstants.proFeedLimit} $feedSpots ${TokenLimitConstants.proProfileLimit} $profilePosts ${TokenLimitConstants.proMuteLimit} $creators)';

  // Deposit messages using constants
  static const String depositStarter = '$depositToUnlock ${TokenLimitConstants.starterTokens} $depositForTier ${TokenLimitTexts.starter} $tier';
  static const String depositAdvanced =
      '$depositToUnlock ${TokenLimitConstants.advancedTokens} $depositForTier ${TokenLimitTexts.premium} $tier';
  static const String depositPro = '$depositToUnlock ${TokenLimitConstants.proTokens} $depositForTier ${TokenLimitTexts.pro} $tier';

  // Mute upgrade hints using constants
  static const String muteUpgradeStarter =
      '$depositToUnlock ${TokenLimitConstants.starterTokens} $depositForTier ${TokenLimitTexts.starter} $tier (${TokenLimitConstants.starterMuteLimit} $creators2)';
  static const String muteUpgradeAdvanced =
      '$depositToUnlock ${TokenLimitConstants.advancedTokens} $depositForTier ${TokenLimitTexts.premium} $tier (${TokenLimitConstants.advancedMuteLimit} $creators2)';
  static const String muteUpgradePro =
      '$depositToUnlock ${TokenLimitConstants.proTokens} $depositForTier ${TokenLimitTexts.pro} $tier (${TokenLimitConstants.proMuteLimit} $creators2)';
}

enum TokenLimitEnum {
  free(
    "${TokenLimitTexts.free}",
    tokenAmount: TokenLimitConstants.freeTokens,
    feedLimit: TokenLimitConstants.freeFeedLimit,
    feedLimitText:
        '${TokenLimitTexts.feedLimitReached} ${TokenLimitTexts.free} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.depositStarter} '
        '${TokenLimitTexts.starterBenefits} '
        '${TokenLimitTexts.muteSuggestion} ${TokenLimitTexts.tokenDepositInfo}',
    profileLimit: TokenLimitConstants.freeProfileLimit,
    profileLimitText:
        '${TokenLimitTexts.profileLimitReached} ${TokenLimitTexts.free} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.depositStarter} '
        '${TokenLimitTexts.tokenDepositInfo} ${TokenLimitTexts.findMnemonic}',
    muteLimit: TokenLimitConstants.freeMuteLimit,
    muteLimitText:
        '${TokenLimitTexts.muteLimitReached} ${TokenLimitTexts.free} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.muteUpgradeStarter}',
  ),

  starter(
    "${TokenLimitTexts.starter}",
    tokenAmount: TokenLimitConstants.starterTokens,
    feedLimit: TokenLimitConstants.starterFeedLimit,
    feedLimitText:
        '${TokenLimitTexts.feedLimitReached} ${TokenLimitTexts.starter} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.depositAdvanced} '
        '${TokenLimitTexts.advancedBenefits} '
        '${TokenLimitTexts.muteSuggestion} ${TokenLimitTexts.withdrawalInfo}',
    profileLimit: TokenLimitConstants.starterProfileLimit,
    profileLimitText:
        '${TokenLimitTexts.profileLimitReached} ${TokenLimitTexts.starter} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.depositAdvanced} '
        '${TokenLimitTexts.tokenDepositInfo} ${TokenLimitTexts.findMnemonic}',
    muteLimit: TokenLimitConstants.starterMuteLimit,
    muteLimitText:
        '${TokenLimitTexts.muteLimitReached} ${TokenLimitTexts.starter} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.muteUpgradeAdvanced}',
  ),

  advanced(
    "${TokenLimitTexts.premium}",
    tokenAmount: TokenLimitConstants.advancedTokens,
    feedLimit: TokenLimitConstants.advancedFeedLimit,
    feedLimitText:
        '${TokenLimitTexts.feedLimitReached} ${TokenLimitTexts.premium} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.depositPro} '
        '${TokenLimitTexts.proBenefits} '
        '${TokenLimitTexts.muteSuggestion} ${TokenLimitTexts.withdrawalInfo}',
    profileLimit: TokenLimitConstants.advancedProfileLimit,
    profileLimitText:
        '${TokenLimitTexts.profileLimitReached} ${TokenLimitTexts.premium} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.depositPro} '
        '${TokenLimitTexts.tokenDepositInfo} ${TokenLimitTexts.findMnemonic}',
    muteLimit: TokenLimitConstants.advancedMuteLimit,
    muteLimitText:
        '${TokenLimitTexts.muteLimitReached} ${TokenLimitTexts.premium} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.muteUpgradePro}',
  ),

  pro(
    "${TokenLimitTexts.pro}",
    tokenAmount: TokenLimitConstants.proTokens,
    feedLimit: TokenLimitConstants.proFeedLimit,
    feedLimitText:
        '${TokenLimitTexts.feedLimitReached} ${TokenLimitTexts.pro} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.contactSupport} '
        '${TokenLimitTexts.withdrawalInfo}',
    profileLimit: TokenLimitConstants.proProfileLimit,
    profileLimitText:
        '${TokenLimitTexts.profileLimitReached} ${TokenLimitTexts.pro} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.contactSupport} '
        '${TokenLimitTexts.tokenDepositInfo} ${TokenLimitTexts.findMnemonic}',
    muteLimit: TokenLimitConstants.proMuteLimit,
    muteLimitText:
        '${TokenLimitTexts.muteLimitReached} ${TokenLimitTexts.pro} ${TokenLimitTexts.tier} '
        '${TokenLimitTexts.contactSupport}',
  );

  final String name;
  final int tokenAmount;
  final int feedLimit;
  final String feedLimitText;
  final int profileLimit;
  final String profileLimitText;
  final int muteLimit;
  final String muteLimitText;

  const TokenLimitEnum(
    this.name, {
    required this.tokenAmount,
    required this.feedLimit,
    required this.feedLimitText,
    required this.profileLimit,
    required this.profileLimitText,
    required this.muteLimit,
    required this.muteLimitText,
  });

  // Helper method to get the appropriate enum based on token balance
  static TokenLimitEnum fromTokenBalance(int tokenBalance) {
    if (tokenBalance >= TokenLimitEnum.pro.tokenAmount) {
      return TokenLimitEnum.pro;
    } else if (tokenBalance >= TokenLimitEnum.advanced.tokenAmount) {
      return TokenLimitEnum.advanced;
    } else if (tokenBalance >= TokenLimitEnum.starter.tokenAmount) {
      return TokenLimitEnum.starter;
    } else {
      return TokenLimitEnum.free;
    }
  }

  String toString() {
    return name;
  }
}

// State class to hold the current limits and balance info
class TokenLimitsState {
  final TokenLimitEnum currentLimit;
  final int tokenBalance;
  final MemoModelCreator? creator;

  const TokenLimitsState({required this.currentLimit, required this.tokenBalance, this.creator});

  TokenLimitsState copyWith({TokenLimitEnum? currentLimit, int? tokenBalance, MemoModelCreator? creator}) {
    return TokenLimitsState(
      currentLimit: currentLimit ?? this.currentLimit,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      creator: creator ?? this.creator,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TokenLimitsState && other.currentLimit == currentLimit && other.tokenBalance == tokenBalance && other.creator == creator;
  }

  @override
  int get hashCode {
    return Object.hash(currentLimit, tokenBalance, creator);
  }
}

final tokenLimitsProvider = AsyncNotifierProvider<TokenLimitsNotifier, TokenLimitsState>(() => TokenLimitsNotifier());

class TokenLimitsNotifier extends AsyncNotifier<TokenLimitsState> {
  StreamSubscription<MemoModelCreator?>? _creatorSubscription;

  TokenLimitsNotifier();

  @override
  Future<TokenLimitsState> build() async {
    ref.onDispose(() {
      _creatorSubscription?.cancel();
    });
    final initialState = const TokenLimitsState(currentLimit: TokenLimitEnum.free, tokenBalance: 0);

    _setupCreatorSubscription();

    return initialState;
  }

  void _setupCreatorSubscription() {
    // Cancel existing subscription
    _creatorSubscription?.cancel();

    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    final creatorRepo = ref.read(creatorRepositoryProvider);

    _creatorSubscription = creatorRepo
        .watchCreator(userId)
        .listen(
          (updatedCreator) {
            handleCreatorUpdate(updatedCreator);
          },
          onError: (error) {
            print('❌ TokenLimits: Error in creator stream: $error');
          },
        );
  }

  void handleCreatorUpdate(MemoModelCreator? c) {
    MemoModelCreator? creator = c ?? ref.read(getCreatorProvider(ref.read(userProvider)!.id)).value;
    if (creator != null) {
      int tokenBalance = creator.balanceToken;
      TokenLimitEnum currentLimit = TokenLimitEnum.fromTokenBalance(tokenBalance);
      // Update state with new data
      state = AsyncData(TokenLimitsState(currentLimit: currentLimit, tokenBalance: tokenBalance, creator: creator));
      print('❌ TokenLimits: _handleCreatorUpdate: $currentLimit, $tokenBalance');
    }
  }

  // Helper methods to access limits conveniently
  int get feedLimit => state.value?.currentLimit.feedLimit ?? TokenLimitEnum.free.feedLimit;
  int get profileLimit => state.value?.currentLimit.profileLimit ?? TokenLimitEnum.free.profileLimit;
  int get muteLimit => state.value?.currentLimit.muteLimit ?? TokenLimitEnum.free.muteLimit;
  TokenLimitEnum get currentLimit => state.value?.currentLimit ?? TokenLimitEnum.free;
  int get tokenBalance => state.value?.tokenBalance ?? 0;

  bool get hasSufficientTokensForPro => tokenBalance >= TokenLimitEnum.pro.tokenAmount;
  bool get hasSufficientTokensForAdvanced => tokenBalance >= TokenLimitEnum.advanced.tokenAmount;
  bool get hasSufficientTokensForStarter => tokenBalance >= TokenLimitEnum.starter.tokenAmount;
}

// Convenience providers for individual limits
final feedLimitProvider = Provider<int>((ref) {
  final state = ref.watch(tokenLimitsProvider);
  return state.value?.currentLimit.feedLimit ?? TokenLimitEnum.free.feedLimit;
});

final profileLimitProvider = Provider<int>((ref) {
  final state = ref.watch(tokenLimitsProvider);
  return state.value?.currentLimit.profileLimit ?? TokenLimitEnum.free.profileLimit;
});

final muteLimitProvider = Provider<int>((ref) {
  final state = ref.watch(tokenLimitsProvider);
  return state.value?.currentLimit.muteLimit ?? TokenLimitEnum.free.muteLimit;
});

final currentTokenLimitEnumProvider = Provider<TokenLimitEnum>((ref) {
  final state = ref.watch(tokenLimitsProvider);
  return state.value?.currentLimit ?? TokenLimitEnum.free;
});

final tokenBalanceProvider = Provider<int>((ref) {
  final state = ref.watch(tokenLimitsProvider);
  return state.value?.tokenBalance ?? 0;
});

// Provider to check if user has any tokens at all
final hasAnyTokensProvider = Provider<bool>((ref) {
  final tokenBalance = ref.watch(tokenBalanceProvider);
  return tokenBalance > 0;
});

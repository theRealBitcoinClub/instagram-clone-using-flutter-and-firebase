// token_limits_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_creator.dart';
import 'package:mahakka/repositories/creator_repository.dart';

import '../provider/user_provider.dart';

// Token Limit Enums
enum TokenLimitEnum {
  free(
    "FREE",
    'You\'ve loaded the maximum posts available for non token users. Deposit 222 tokens to unlock STARTER limits! '
        'These tokens stay in your wallet, depositing them simply proofs that you are ready to level up! '
        'You can also mute some users to appreciate the 20 free limit post spots, '
        'navigate to any profile and hit the mute badge on their avatar! If you deposit 222 tokens '
        'you will have a limit of 30 spots, 1800 tokens give you 42 spots and 6000 for 60 spots',
    tokenAmount: 0,
    feedLimit: 20,
    profileLimit: 9,
    muteLimit: 3,
  ),
  starter(
    "STARTER",
    'You\'ve loaded the maximum posts available for STARTER tier. Deposit 1800 tokens to unlock ADVANCED limits! '
        'These tokens stay in your wallet, depositing them simply proofs that you are ready to level up! '
        'You can also mute some users to appreciate the 30 STARTER limit post spots, '
        'navigate to any profile and hit the mute badge on their avatar!'
        'If you want to withdraw your tokens simply use the mnemonic with Cashonize or Cauldron swap! '
        'You can find the mnemonic/seed phrase on your profile settings!',
    tokenAmount: 222,
    feedLimit: 30,
    profileLimit: 12,
    muteLimit: 6,
  ),
  advanced(
    "ADVANCED",
    'You\'ve loaded the maximum posts available for ADVANCED tier. Deposit 6000 tokens to unlock PRO limits! '
        'These tokens stay in your wallet, depositing them simply proofs that you are ready to level up! '
        'You can also mute some users to appreciate the 42 ADVANCED tier post spots, '
        'navigate to any profile and hit the mute badge on their avatar!'
        'If you want to withdraw your tokens simply use the mnemonic with Cashonize or Cauldron swap! '
        'You can find the mnemonic/seed phrase on your profile settings!',
    tokenAmount: 1800,
    feedLimit: 42,
    profileLimit: 15,
    muteLimit: 9,
  ),
  pro(
    "PRO",
    'You\'ve loaded the maximum posts available for PRO users. If you want higher limits talk to @mahakka_com TG support! '
        'If you want to withdraw your tokens simply use the mnemonic with Cashonize or Cauldron swap! '
        'You can find the mnemonic/seed phrase on your profile settings!',
    tokenAmount: 6000,
    feedLimit: 60,
    profileLimit: 18,
    muteLimit: 12,
  );

  String toString() {
    return tokenName;
  }

  const TokenLimitEnum(
    this.tokenName,
    this.description, {
    required this.tokenAmount,
    required this.feedLimit,
    required this.profileLimit,
    required this.muteLimit,
  });

  final String tokenName;
  final String description;
  final int tokenAmount;
  final int feedLimit;
  final int profileLimit;
  final int muteLimit;

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
            _handleCreatorUpdate(updatedCreator);
          },
          onError: (error) {
            print('❌ TokenLimits: Error in creator stream: $error');
          },
        );
  }

  void _handleCreatorUpdate(MemoModelCreator? updatedCreator) {
    if (updatedCreator != null) {
      int tokenBalance = updatedCreator.balanceToken;
      TokenLimitEnum currentLimit = TokenLimitEnum.fromTokenBalance(tokenBalance);
      // Update state with new data
      state = AsyncData(TokenLimitsState(currentLimit: currentLimit, tokenBalance: tokenBalance, creator: updatedCreator));
      print('❌ TokenLimits: _handleCreatorUpdate: $currentLimit, $tokenBalance');
    }
  }

  // Method to manually refresh the balance
  Future<void> refreshBalance() async {
    final userId = ref.read(userProvider)?.id;
    if (userId == null) return;

    try {
      final creatorRepo = ref.read(creatorRepositoryProvider);
      final creator = await creatorRepo.getCreator(userId);

      if (creator != null) {
        await creator.refreshBalanceMahakka(ref);
      }
    } catch (e) {
      print('❌ TokenLimits: Failed to refresh balance: $e');
      state = AsyncError(e, StackTrace.current);
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

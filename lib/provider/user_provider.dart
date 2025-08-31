// lib/provider/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/resources/auth_method.dart'; // Ensure AuthChecker is correctly defined

// State class for user
class UserState {
  final MemoModelUser? user;
  final bool isLoading;
  final String? error; // Optional: for displaying errors

  UserState({this.user, this.isLoading = false, this.error});

  UserState copyWith({
    MemoModelUser? user,
    bool? isLoading,
    String? error,
    bool clearError = false, // To explicitly clear previous error
  }) {
    return UserState(user: user ?? this.user, isLoading: isLoading ?? this.isLoading, error: clearError ? null : (error ?? this.error));
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(this.ref, this._authChecker) : super(UserState(isLoading: true)) {
    // Initial load when the provider is first created
    refreshUser();
  }

  final AuthChecker _authChecker;
  final Ref ref;

  Future<void> refreshUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (state.user == null || !state.user!.hasInit) {
        final fetchedUser = await _authChecker.getUserFromDB();
        state = state.copyWith(user: fetchedUser, isLoading: false);
      }
      // Call the new method to refresh all balances after the user is fetched
      refreshAllBalances();

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      print("Error refreshing user from DB: $e \n$stackTrace");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> refreshAllBalances() async {
    MemoModelUser? user = state.user;
    if (user == null) {
      print("WARNING: Cannot refresh balances, user is null.");
      return;
    }

    try {
      // 1. Refresh BCH (Memo) balance
      final request = await user.refreshBalanceDevPath0(ref);
      // if (request == "success") {
      user = user.copyWith(balanceBchDevPath0Memo: request);
      state = state.copyWith(user: user);
      // }

      // 2. Refresh BCH (Cashtoken) balance
      final bchBalanceRequest = await user.refreshBalanceDevPath145(ref);
      // if (bchBalanceRequest == "success") {
      user = user.copyWith(balanceBchDevPath145: bchBalanceRequest);
      state = state.copyWith(user: user);
      // }
      // 3. Refresh Tokens balance
      final tokenBalanceReq = await user.refreshBalanceTokens(ref);
      // if (tokenBalanceReq == "success") {
      user = user.copyWith(balanceCashtokensDevPath145: tokenBalanceReq);
      state = state.copyWith(user: user);
      // }
    } catch (e, stackTrace) {
      print("Error refreshing balances: $e \n$stackTrace");
      // Set an error state without clearing the user data
      state = state.copyWith(error: "Failed to refresh balances.", isLoading: false);
    }
  }

  void clearUser() {
    state = UserState(user: null, isLoading: false, error: null);
  }
}

// The global provider for UserNotifier
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref, AuthChecker(ref));
});

// Optional: A simpler provider just for the user model, derived from UserState
final userProvider = Provider<MemoModelUser?>((ref) {
  return ref.watch(userNotifierProvider).user;
});

// Optional: Provider for loading state
final userIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userNotifierProvider).isLoading;
});

// Optional: Provider for error state
final userErrorProvider = Provider<String?>((ref) {
  return ref.watch(userNotifierProvider).error;
});

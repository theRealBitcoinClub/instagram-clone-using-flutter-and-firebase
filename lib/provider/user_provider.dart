// lib/provider/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/resources/auth_method.dart';

import '../memo/firebase/user_service.dart'; // Ensure AuthChecker is correctly defined

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

  Future<String> updateTipReceiver(TipReceiver newReceiver) async {
    if (state.user == null) return "user state is null";

    try {
      final updatedUser = state.user!.copyWith(tipReceiver: newReceiver);

      // Save to Firebase
      final userService = UserService();
      await userService.saveUser(updatedUser);

      // Update local state
      state = state.copyWith(user: updatedUser);
      return "success";
    } catch (e) {
      print("Error updating tip receiver: $e");
      state = state.copyWith(error: "Failed to update tip receiver: $e");
    }
    return "fail updateTipReceiver";
  }

  Future<String> updateTipAmount(TipAmount newAmount) async {
    if (state.user == null) return "user is null";

    try {
      final updatedUser = state.user!.copyWith(tipAmount: newAmount);

      // Save to Firebase
      final userService = UserService();
      await userService.saveUser(updatedUser);

      // Update local state
      state = state.copyWith(user: updatedUser);
      return "success";
    } catch (e) {
      print("Error updating tip amount: $e");
      state = state.copyWith(error: "Failed to update tip amount: $e");
    }
    return "fail updateTipAmount";
  }

  Future<void> refreshUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (state.user == null || !state.user!.hasInit) {
        final fetchedUser = await _authChecker.createUserFromMnemonic();
        state = state.copyWith(user: fetchedUser);
      }

      MemoModelUser user = (await UserService().getUserOnce(state.user!.id))!;
      MemoModelUser newUser = user.copyWith(tipAmount: user.tipAmountEnum, tipReceiver: user.tipReceiver);
      state = state.copyWith(user: newUser);
      // Call the new method to refresh all balances after the user is fetched
      //the refresh balance is now done per creator
      // refreshAllBalances();

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      print("Error refreshing user from DB: $e \n$stackTrace");
      state = state.copyWith(error: e.toString(), isLoading: false);
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

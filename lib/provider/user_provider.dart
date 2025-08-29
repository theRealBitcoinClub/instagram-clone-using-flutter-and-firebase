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
  // Pass AuthChecker if it's stateless or provide it via ref.read if it's another provider
  UserNotifier(this._authChecker) : super(UserState(isLoading: true)) {
    // Initial load when the provider is first created
    refreshUser();
  }

  final AuthChecker _authChecker; // Or ref.read(authCheckerProvider) if AuthChecker is a provider

  Future<void> refreshUser() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (state.user == null || !state.user!.hasInit) {
        final fetchedUser = await _authChecker.getUserFromDB();
        state = state.copyWith(user: fetchedUser, isLoading: false);
      }
      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      print("Error refreshing user from DB: $e \n$stackTrace");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // If you need a method to explicitly clear the user (e.g., on logout)
  void clearUser() {
    state = UserState(isLoading: false); // Reset to initial empty state, not loading
  }
}

// The global provider for UserNotifier
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  // If AuthChecker itself should be a provider (e.g., if it has its own dependencies or state)
  // final authChecker = ref.watch(authCheckerProvider);
  // return UserNotifier(authChecker);

  // If AuthChecker is simple and stateless:
  return UserNotifier(AuthChecker(ref));
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

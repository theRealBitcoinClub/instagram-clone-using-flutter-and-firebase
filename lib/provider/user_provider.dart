// lib/provider/user_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/memo/model/memo_model_user.dart';
import 'package:mahakka/repositories/creator_repository.dart';
import 'package:mahakka/resources/auth_method.dart';

import '../memo/firebase/user_service.dart';

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
    refreshUser(false);
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

  Future<void> refreshUser(bool freshScrapeCreatorData) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      if (state.user == null || !state.user!.hasInit) {
        MemoModelUser? createdUser = await _authChecker.createUserFromMnemonic();
        // state = state.copyWith(fetchedUser: createdUser);
        UserService service = UserService();

        if (createdUser == null) {
          state = state.copyWith(user: createdUser, isLoading: false);
          return; //first run after instalation there is no mnemonic
        }

        if (freshScrapeCreatorData) {
          createdUser = createdUser.copyWith(creator: await ref.read(creatorRepositoryProvider).getCreator(createdUser.id));
          state = state.copyWith(user: createdUser);
        }

        MemoModelUser? fetchedUser = await service.getUserOnce(createdUser.id);

        if (fetchedUser != null) {
          state = state.copyWith(
            user: createdUser.copyWith(
              tipAmount: fetchedUser.tipAmountEnum,
              tipReceiver: fetchedUser.tipReceiver,
              ipfsCids: fetchedUser.ipfsCids,
            ),
            isLoading: false,
          );
        } else {
          //save user  if didnt exist in firebase before
          await service.saveUser(createdUser);
          state = state.copyWith(user: createdUser, isLoading: false);
        }
      }
      // Call the new method to refresh all balances after the fetchedUser is fetched
      //the refresh balance is now done per creator
      // refreshAllBalances();

      state = state.copyWith(isLoading: false);
    } catch (e, stackTrace) {
      print("Error refreshing fetchedUser from DB: $e \n$stackTrace");
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void clearUser() {
    state = UserState(user: null, isLoading: false, error: null);
  }

  // Add this method to your UserNotifier class
  Future<String> addIpfsUrlAndUpdate(String cid) async {
    if (state.user == null) return "user is null";

    try {
      int oldLength = state.user!.ipfsCids.length;
      state.user!.addIpfsCid(cid);
      int newLength = state.user!.ipfsCids.length;
      if (oldLength != newLength) {
        await UserService().saveUser(state.user!);
        state = state.copyWith(user: state.user!);
      }
      return "success";
    } catch (e) {
      print("Error adding IPFS URL: $e");
      state = state.copyWith(error: "Failed to add IPFS URL: $e");
      return "fail addIpfsUrl";
    }
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

final userIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userNotifierProvider).isLoading;
});

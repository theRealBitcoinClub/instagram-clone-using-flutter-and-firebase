import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppUtils {
  // Enhanced safe versions with optional refreshUI parameter
  static void safeAfterBuild(BuildContext context, VoidCallback callback, {required bool refreshUI}) {
    Future.microtask(() {
      if (context.mounted) {
        _executeCallback(context, callback, refreshUI);
      }
    });
  }

  static void safeAfterLayout(BuildContext context, VoidCallback callback, {required bool refreshUI}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        _executeCallback(context, callback, refreshUI);
      }
    });
  }

  // New async-safe versions that handle Future-returning callbacks
  static Future<void> safeAfterBuildAsync(BuildContext context, AsyncCallback callback, {required bool refreshUI}) async {
    await Future.microtask(() async {
      if (context.mounted) {
        await _executeAsyncCallback(context, callback, refreshUI);
      }
    });
  }

  static Future<void> safeAfterLayoutAsync(BuildContext context, AsyncCallback callback, {required bool refreshUI}) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.mounted) {
        await _executeAsyncCallback(context, callback, refreshUI);
      }
    });
  }

  // Helper method to handle setState wrapping with clear intent
  static void _executeCallback(BuildContext context, VoidCallback callback, bool refreshUI) {
    if (refreshUI) {
      // Attempt to find the nearest StatefulWidget's State for UI updates
      final state = context.findAncestorStateOfType<State>();
      if (state != null && state.mounted) {
        // Execute the callback first, then update state
        callback();
        state.setState(() {});
      } else {
        // Fallback: execute without setState if no state context available
        callback();
      }
    } else {
      // Execute callback without triggering UI rebuild (more performant)
      callback();
    }
  }

  // Helper method to handle async callbacks properly
  static Future<void> _executeAsyncCallback(BuildContext context, AsyncCallback callback, bool refreshUI) async {
    if (refreshUI) {
      // Attempt to find the nearest StatefulWidget's State for UI updates
      final state = context.findAncestorStateOfType<State>();
      if (state != null && state.mounted) {
        // Execute async work first, then update state
        await callback();
        if (state.mounted) {
          state.setState(() {});
        }
      } else {
        // Fallback: execute without setState if no state context available
        await callback();
      }
    } else {
      // Execute callback without triggering UI rebuild (more performant)
      await callback();
    }
  }
}

// Enhanced extension methods with expressive, self-documenting parameters
extension SafeAsyncExtensions on BuildContext {
  /// Executes callback after build phase with optional UI refresh
  /// Future.microtask(callback);
  ///
  /// Use [refreshUI: true] when your callback modifies local state that requires
  /// immediate widget rebuild. Use [refreshUI: false] (default) for operations
  /// that don't need UI updates (more performant).
  void afterBuild(VoidCallback callback, {required bool refreshUI}) {
    AppUtils.safeAfterBuild(this, callback, refreshUI: refreshUI);
  }

  /// Executes callback after layout/paint phase with optional UI refresh
  /// WidgetsBinding.instance.addPostFrameCallback((_) => callback());
  ///
  /// Use for operations that require widget dimensions/positions.
  /// Use [refreshUI: true] when modifying local state that affects layout.
  void afterLayout(VoidCallback callback, {required bool refreshUI}) {
    AppUtils.safeAfterLayout(this, callback, refreshUI: refreshUI);
  }

  /// Executes async callback after build phase with optional UI refresh
  /// Use this version when your callback returns a Future or is marked async
  ///
  /// Use [refreshUI: true] when your async callback modifies local state that requires
  /// immediate widget rebuild after the async operation completes.
  Future<void> afterBuildAsync(AsyncCallback callback, {required bool refreshUI}) async {
    await AppUtils.safeAfterBuildAsync(this, callback, refreshUI: refreshUI);
  }

  /// Executes async callback after layout/paint phase with optional UI refresh
  /// Use this version when your callback returns a Future or is marked async
  ///
  /// Use for async operations that require widget dimensions/positions.
  /// Use [refreshUI: true] when your async operation modifies local state that affects layout.
  Future<void> afterLayoutAsync(AsyncCallback callback, {required bool refreshUI}) async {
    await AppUtils.safeAfterLayoutAsync(this, callback, refreshUI: refreshUI);
  }
}

// Example usage helper to demonstrate proper usage
class AsyncExampleHelper {
  static Future<void> performAsyncTask(BuildContext context, {required bool shouldUpdateUI}) async {
    // Example of proper async usage
    await context.afterLayoutAsync(() async {
      // Perform async work first
      await Future.delayed(const Duration(seconds: 1));
      // Do some state modification here

      // The UI will be updated automatically if refreshUI: true
    }, refreshUI: shouldUpdateUI);
  }

  static void performSyncTask(BuildContext context, {required bool shouldUpdateUI}) {
    // Example of proper sync usage
    context.afterLayout(() {
      // Perform sync work
      // Do some state modification here

      // The UI will be updated automatically if refreshUI: true
    }, refreshUI: shouldUpdateUI);
  }
}

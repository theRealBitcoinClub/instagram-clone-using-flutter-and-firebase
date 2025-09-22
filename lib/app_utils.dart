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

  // Helper method to handle setState wrapping with clear intent
  static void _executeCallback(BuildContext context, VoidCallback callback, bool refreshUI) {
    if (refreshUI) {
      // Attempt to find the nearest StatefulWidget's State for UI updates
      final state = context.findAncestorStateOfType<State>();
      if (state != null && state.mounted) {
        state.setState(callback);
      } else {
        // Fallback: execute without setState if no state context available
        callback();
      }
    } else {
      // Execute callback without triggering UI rebuild (more performant)
      callback();
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
}

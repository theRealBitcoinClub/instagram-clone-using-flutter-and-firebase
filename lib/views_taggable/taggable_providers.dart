// providers/taggable_providers.dart - SIMPLIFIED
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../custom_flutter_tagger_controller.dart';

// Provider for the FlutterTaggerController
final taggableControllerProvider = Provider<CustomFlutterTaggerController>((ref) {
  final controller = CustomFlutterTaggerController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

// // Provider for the AnimationController (now without vsync dependency)
// final animationControllerProvider = Provider<AnimationController>((ref) {
//   throw UnimplementedError('AnimationController must be overridden in widget tree');
// });

// providers/taggable_providers.dart - FIXED
// final animationControllerProvider = Provider.autoDispose<AnimationController>((ref) {
//   // Create a simple controller without vsync as fallback
//   final controller = AnimationController(duration: const Duration(milliseconds: 200));
//   ref.onDispose(() => controller.dispose());
//   return controller;
// });

class AnimationControllerNotifier extends StateNotifier<AnimationController?> {
  AnimationControllerNotifier() : super(null);

  void initialize(TickerProvider vsync) {
    state?.dispose();
    state = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 200));
  }

  // @override
  // void dispose() {
  //   state?.dispose();
  //   super.dispose();
  // }
}

final animationControllerNotifierProvider = StateNotifierProvider<AnimationControllerNotifier, AnimationController?>((ref) {
  return AnimationControllerNotifier();
});

// Provider for the overlay animation
final overlayAnimationProvider = Provider<Animation<Offset>>((ref) {
  final animationController = ref.watch(animationControllerNotifierProvider);

  if (animationController == null) {
    return AlwaysStoppedAnimation(Offset.zero);
  }
  return Tween<Offset>(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOutSine));
});

// Provider for focus node
final focusNodeProvider = Provider<FocusNode>((ref) {
  final focusNode = FocusNode();
  ref.onDispose(() => focusNode.dispose());
  return focusNode;
});

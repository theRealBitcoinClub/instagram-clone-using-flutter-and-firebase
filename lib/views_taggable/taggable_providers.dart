// providers/taggable_providers.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertagger/fluttertagger.dart';

final taggableControllerProvider = Provider.autoDispose<FlutterTaggerController>((ref) {
  final controller = FlutterTaggerController();
  ref.onDispose(() => controller.dispose());
  return controller;
});

final animationControllerProvider = Provider.autoDispose<AnimationController>((ref) {
  final vsync = ref.watch(tickerProvider);
  final controller = AnimationController(vsync: vsync, duration: const Duration(milliseconds: 200));
  ref.onDispose(() => controller.dispose());
  return controller;
});

final tickerProvider = StateProvider<TickerProvider>((ref) {
  throw UnimplementedError('TickerProvider must be set in widget tree');
});

final overlayAnimationProvider = Provider.autoDispose<Animation<Offset>>((ref) {
  final animationController = ref.watch(animationControllerProvider);
  return Tween<Offset>(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOutSine));
});

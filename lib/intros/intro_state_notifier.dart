// intro_state_notifier.dart
import 'dart:convert'; // ADD THIS IMPORT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/utils/snackbar.dart';

import '../main.dart';
import 'intro_enums.dart';

final introStateNotifierProvider = StateNotifierProvider<IntroStateNotifier, Map<IntroType, IntroState>>((ref) {
  return IntroStateNotifier(ref);
});

class IntroState {
  final IntroType introType;
  final IntroStep currentStep;
  final Set<IntroStep> triggeredSteps;
  final bool isCompleted;

  const IntroState({required this.introType, required this.currentStep, required this.triggeredSteps, required this.isCompleted});

  bool isStepTriggered(IntroStep step) {
    return triggeredSteps.any((triggeredStep) => triggeredStep.id == step.id);
  }

  IntroState copyWith({IntroStep? currentStep, Set<IntroStep>? triggeredSteps, bool? isCompleted}) {
    return IntroState(
      introType: introType,
      currentStep: currentStep ?? this.currentStep,
      triggeredSteps: triggeredSteps ?? this.triggeredSteps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // Serialization
  Map<String, dynamic> toJson() {
    return {
      'introType': introType.name,
      'currentStep': currentStep.id,
      'triggeredSteps': triggeredSteps.map((step) => step.id).toList(),
      'isCompleted': isCompleted,
    };
  }

  // Update fromJson factory to use id comparison
  factory IntroState.fromJson(Map<String, dynamic> json, IntroType introType) {
    final steps = introType.steps;
    final currentStep = steps.firstWhere((step) => step.id == json['currentStep'], orElse: () => steps.first);

    final triggeredSteps = (json['triggeredSteps'] as List<dynamic>).map((id) => steps.firstWhere((step) => step.id == id)).toSet();

    return IntroState(
      introType: introType,
      currentStep: currentStep,
      triggeredSteps: triggeredSteps,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class IntroStateNotifier extends StateNotifier<Map<IntroType, IntroState>> {
  Ref ref;

  IntroStateNotifier(this.ref) : super({}) {
    _loadAllIntroStates();
  }

  static const String key = "iiiintroo2";

  Future<void> _loadAllIntroStates() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final newState = <IntroType, IntroState>{};

    for (final introType in IntroType.values) {
      final jsonString = prefs.getString('$key${introType.name}');

      if (jsonString != null) {
        try {
          final jsonMap = Map<String, dynamic>.from(json.decode(jsonString));
          newState[introType] = IntroState.fromJson(jsonMap, introType);
        } catch (e) {
          print('Error loading intro state for ${introType.name}: $e');
          newState[introType] = _createInitialState(introType);
        }
      } else {
        newState[introType] = _createInitialState(introType);
      }
    }

    state = newState;
  }

  IntroState _createInitialState(IntroType introType) {
    final steps = introType.steps.toList();
    return IntroState(
      introType: introType,
      currentStep: steps.isNotEmpty ? steps.first : IntroStep.mainTheme,
      triggeredSteps: {},
      isCompleted: steps.isEmpty, // Mark as completed if no steps
    );
  }

  Future<void> _saveIntroState(IntroType introType) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final introState = state[introType];

    if (introState != null) {
      await prefs.setString('$key${introType.name}', json.encode(introState.toJson()));
    }
  }

  void triggerIntroAction(IntroType introType, IntroStep step, BuildContext context) {
    final currentState = state[introType];
    if (currentState == null || currentState.isCompleted) return;

    // Only trigger if this is the current step and not already triggered
    if (currentState.currentStep.id == step.id && !currentState.isStepTriggered(step)) {
      final updatedSteps = {...currentState.triggeredSteps}..add(step);
      final triggeredState = currentState.copyWith(triggeredSteps: updatedSteps);
      state = {...state, introType: triggeredState};
      _saveIntroState(introType);

      _showStepCompletionSnackbar(context, step.content);

      Future.delayed(const Duration(seconds: 9), () {
        if (context.mounted) _advanceToNextStep(introType, context);
      });
    }
  }

  void skipIntro(IntroType introType) {
    final currentState = state[introType];
    if (currentState == null || currentState.isCompleted) return;

    // Mark the intro as completed
    final completedState = currentState.copyWith(isCompleted: true);
    state = {...state, introType: completedState};
    _saveIntroState(introType);

    print('Intro ${introType.name} skipped by user');
  }

  void _advanceToNextStep(IntroType introType, BuildContext context) {
    final currentState = state[introType];
    if (currentState == null || currentState.isCompleted) return;

    final steps = introType.steps.toList();
    final currentIndex = steps.indexWhere((step) => step.id == currentState.currentStep.id);

    if (currentIndex < steps.length - 1) {
      // Move to next step
      final newState = currentState.copyWith(currentStep: steps[currentIndex + 1]);
      state = {...state, introType: newState};
      _saveIntroState(introType);
    } else {
      // Intro completed
      final completedState = currentState.copyWith(isCompleted: true);
      state = {...state, introType: completedState};
      _saveIntroState(introType);

      // _showCompletionConfetti(context);
    }
  }

  void manuallyAdvanceStep(IntroType introType, BuildContext context) {
    _advanceToNextStep(introType, context);
  }

  void _showStepCompletionSnackbar(BuildContext context, IntroContent content) {
    // Show initial snackbar
    ref.read(snackbarServiceProvider).showTranslatedSnackBar(content.snackbarText, type: SnackbarType.success);

    // Show triggered text after 4 seconds
    // Future.delayed(const Duration(seconds: 3), () {
    //   // if (context.mounted) {
    //   ref.read(snackbarServiceProvider).showTranslatedSnackBar(content.triggeredText, type: SnackbarType.info, wait: true);
    //   // showSnackBar(content.triggeredText, type: SnackbarType.info);
    //   // }
    // });
  }

  // void _showCompletionConfetti(BuildContext context) {
  //   // Confetti implementation
  //   context.showSnackBar("🎉 Tutorial completed! You're ready to explore!", type: SnackbarType.success);
  // }

  void resetIntro(IntroType introType) {
    final initialState = _createInitialState(introType);
    state = {...state, introType: initialState};
    _saveIntroState(introType);
  }

  void resetAllIntros() {
    final newState = <IntroType, IntroState>{};
    for (final introType in IntroType.values) {
      newState[introType] = _createInitialState(introType);
    }
    state = newState;

    // Save all states
    for (final introType in IntroType.values) {
      _saveIntroState(introType);
    }
  }

  bool shouldShow(IntroType introType) {
    final introState = state[introType];
    return introState != null && !introState.isCompleted;
  }
}

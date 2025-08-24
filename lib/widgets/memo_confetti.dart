import 'package:flutter/cupertino.dart';
import 'package:flutter_confetti/flutter_confetti.dart';

class MemoConfetti {
  void launch(BuildContext ctx) {
    if (ctx.mounted) Confetti.launch(ctx, options: const ConfettiOptions(particleCount: 100, spread: 70, y: 0.6));
  }
}

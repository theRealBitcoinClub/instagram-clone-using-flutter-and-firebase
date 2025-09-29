import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CircularLoadingOverlay extends ConsumerWidget {
  const CircularLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Colors.black.withOpacity(0.5),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(color: colorScheme.surface, shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CircularProgressIndicator(
                  // This will make it fill the available space
                  strokeWidth: 6,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

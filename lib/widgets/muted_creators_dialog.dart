// muted_creators_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../provider/mute_creator_provider.dart';

class MutedCreatorsDialog extends ConsumerWidget {
  const MutedCreatorsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mutedCreatorsAsync = ref.watch(mutedCreatorsWithDetailsProvider);
    final mutedCreatorIds = ref.watch(muteCreatorProvider);

    return AlertDialog(
      title: const Text('Muted Creators'),
      content: mutedCreatorIds.isEmpty
          ? const Text('No creators are currently muted.')
          : mutedCreatorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading creators: $error'),
              data: (creators) {
                return SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: creators.length,
                    itemBuilder: (context, index) {
                      final creator = creators[index];
                      return ListTile(
                        title: Text(
                          creator.name ?? 'Unknown Creator',
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('ID: ${creator.id}', style: Theme.of(context).textTheme.bodySmall),
                        trailing: IconButton(
                          icon: const Icon(Icons.volume_up, color: Colors.blue),
                          onPressed: () {
                            _unmuteCreator(ref, creator.id!, context);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
    );
  }

  void _unmuteCreator(WidgetRef ref, String creatorId, BuildContext context) {
    ref
        .read(muteCreatorProvider.notifier)
        .unmuteCreator(creatorId)
        .then((_) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Unmuted creator: $creatorId'), duration: const Duration(seconds: 2)));
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to unmute creator: $error'), backgroundColor: Colors.red));
        });
  }
}

void showMutedCreatorsDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const MutedCreatorsDialog());
}

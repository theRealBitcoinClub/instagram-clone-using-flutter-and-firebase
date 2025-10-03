// muted_creators_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahakka/widgets/cached_avatar.dart';

import '../provider/mute_creator_provider.dart';

class MutedCreatorsDialog extends ConsumerWidget {
  const MutedCreatorsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final mutedCreatorsAsync = ref.watch(mutedCreatorsWithDetailsProvider);
    final mutedCreatorIds = ref.watch(muteCreatorProvider);

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 8.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Muted Creators',
                    style: textTheme.headlineSmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withOpacity(0.6), size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Content area
              Expanded(
                child: mutedCreatorIds.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.volume_up_rounded, size: 48, color: colorScheme.onSurface.withOpacity(0.4)),
                            const SizedBox(height: 16),
                            Text('No muted creators', style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                            const SizedBox(height: 8),
                            Text(
                              'Creators you mute will appear here',
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.4)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : mutedCreatorsAsync.when(
                        loading: () => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: colorScheme.primary),
                              const SizedBox(height: 16),
                              Text('Loading creators...', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                            ],
                          ),
                        ),
                        error: (error, stack) => Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline_rounded, size: 48, color: colorScheme.error),
                              const SizedBox(height: 16),
                              Text('Failed to load creators', style: textTheme.bodyLarge?.copyWith(color: colorScheme.error)),
                              const SizedBox(height: 8),
                              Text(
                                error.toString(),
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        data: (creators) {
                          if (creators.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.people_alt_rounded, size: 48, color: colorScheme.onSurface.withOpacity(0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No creator details found',
                                    style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                                  ),
                                ],
                              ),
                            );
                          }

                          return Material(
                            color: Colors.transparent,
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: creators.length,
                              separatorBuilder: (context, index) =>
                                  Divider(height: 1, thickness: 1, color: colorScheme.outline.withOpacity(0.2)),
                              itemBuilder: (context, index) {
                                final creator = creators[index];
                                final shortenedId = creator.id != null && creator.id!.length > 12
                                    ? '${creator.id!.substring(0, 8)}...'
                                    : creator.id;

                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: index.isEven ? colorScheme.surfaceVariant.withOpacity(0.3) : Colors.transparent,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    leading: CachedAvatar(
                                      key: ValueKey('muted_creator_avatar_${creator.id}'),
                                      creatorId: creator.id,
                                      radius: 24,
                                    ),
                                    title: Text(
                                      creator.name ?? 'Unknown Creator',
                                      style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      'ID: $shortenedId',
                                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.volume_up_rounded, color: colorScheme.primary, size: 22),
                                      onPressed: () {
                                        _unmuteCreator(ref, creator.id!, context);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                    onTap: () {
                                      _unmuteCreator(ref, creator.id!, context);
                                    },
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _unmuteCreator(WidgetRef ref, String creatorId, BuildContext context) {
    ref
        .read(muteCreatorProvider.notifier)
        .unmuteCreator(creatorId)
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Creator unmuted', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
              backgroundColor: Theme.of(context).colorScheme.inverseSurface,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to unmute creator', style: TextStyle(color: Theme.of(context).colorScheme.onError)),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        });
  }
}

void showMutedCreatorsDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const MutedCreatorsDialog());
}

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
      // shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      // elevation: 8.0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(21, 6, 0, 0),
                    child: Text('Muted Creators', style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface)),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(0, 6, 9, 0),
                    child: IconButton(
                      icon: Icon(Icons.close_rounded, color: colorScheme.onSurface.withAlpha(222), size: 27),
                      onPressed: () => Navigator.of(context).pop(),
                      constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

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
                          creators = creators.reversed.toList();
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
                              separatorBuilder: (context, index) => SizedBox.shrink(),
                              // Divider(height: 0.1, thickness: 0.1, color: colorScheme.outline.withOpacity(0.2)),
                              itemBuilder: (context, index) {
                                final creator = creators[index];
                                final shortenedId = creator.id.length > 12 ? '${creator.id.substring(0, 12)}...' : creator.id;

                                return Container(
                                  decoration: BoxDecoration(
                                    // borderRadius: BorderRadius.circular(12),
                                    color: index.isEven ? colorScheme.surfaceVariant.withOpacity(0.3) : Colors.transparent,
                                  ),
                                  child: ListTile(
                                    minTileHeight: 24,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    leading: CachedAvatar(
                                      showMuteBadge: false,
                                      key: ValueKey('muted_creator_avatar_${creator.id}'),
                                      creatorId: creator.id,
                                      radius: 21,
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
                                        _unmuteCreator(ref, creator.id, context);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                                        padding: const EdgeInsets.all(8),
                                      ),
                                    ),
                                    onTap: () {
                                      _unmuteCreator(ref, creator.id, context);
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
    ref.read(muteCreatorProvider.notifier).unmuteCreator(creatorId);
  }
}

void showMutedCreatorsDialog(BuildContext context) {
  showDialog(context: context, builder: (context) => const MutedCreatorsDialog());
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../../app/widgets/state_views.dart';
import '../../journal/presentation/providers/personal_providers.dart';
import '../../shlokas/presentation/providers/scripture_providers.dart';
import '../../shlokas/presentation/widgets/verse_tile.dart';
import '../../../app/motion/motion.dart';

/// Bookmarks tab (code.html bottom navigation). Newest first; stored only
/// on this device.
class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    return Scaffold(
      body: SafeArea(
        child: ReadingWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabHeader(
                title: 'BOOKMARKS',
                subtitle: 'Cherished verses, saved on this device',
              ),
              Expanded(
                child: switch (bookmarks) {
                  AsyncData(value: final list) when list.isEmpty => EmptyState(
                    icon: Icons.bookmark_border,
                    title: 'No bookmarks yet',
                    message:
                        'Save your favourite Shlokas with the bookmark icon while reading, '
                        'and revisit moments of contemplation here.',
                    action: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.chapters),
                      child: const Text('Browse chapters'),
                    ),
                  ),
                  AsyncData(value: final list) => ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => FadeSlideIn(
                      index: i,
                      child: _BookmarkTile(shlokaId: list[i].shlokaId),
                    ),
                  ),
                  AsyncError() => const ErrorState(),
                  _ => const LoadingState(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookmarkTile extends ConsumerWidget {
  const _BookmarkTile({required this.shlokaId});

  final String shlokaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(shlokaByIdProvider(shlokaId)).value;
    if (verse == null) return const SizedBox(height: 72, child: LoadingState());
    final retired = verse.deletedAt != null;
    return VerseTile(
      verse: verse,
      showReference: true,
      onTap: retired
          ? null
          : () =>
                context.go(AppRoutes.verse(verse.chapterId, verse.verseNumber)),
      trailing: IconButton(
        tooltip: 'Remove bookmark',
        icon: Icon(Icons.bookmark, color: context.colors.accent),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final actions = ref.read(personalActionsProvider);
          await actions.toggleBookmark(shlokaId, bookmarked: true);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Removed ${verse.reference} from Bookmarks'),
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () =>
                      actions.toggleBookmark(shlokaId, bookmarked: false),
                ),
              ),
            );
        },
      ),
    );
  }
}

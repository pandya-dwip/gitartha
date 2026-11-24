import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../../app/widgets/state_views.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/local_database_providers.dart';
import '../../shlokas/presentation/providers/scripture_providers.dart';
import '../../shlokas/presentation/widgets/verse_tile.dart';

/// code.html "Chapter Verse Index": every cached verse with its title and
/// summary, filterable by range (1–10, 11–20 … , Show All).
class VerseIndexScreen extends ConsumerStatefulWidget {
  const VerseIndexScreen({super.key, required this.chapterId});

  final int? chapterId;

  @override
  ConsumerState<VerseIndexScreen> createState() => _VerseIndexScreenState();
}

class _VerseIndexScreenState extends ConsumerState<VerseIndexScreen> {
  /// Index into the ranges; null = show all.
  int? _range = 0;

  static const _rangeSize = 10;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final id = widget.chapterId;
    if (id == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Chapter not found',
          message: 'This address does not match a chapter.',
        ),
      );
    }
    final chapter = ref.watch(chapterProvider(id)).value;
    final verses = ref.watch(localShlokasForChapterProvider(id));
    final count = verses.value?.length ?? 0;

    return Scaffold(
      appBar: InnerTopBar(
        backLabel: 'Chapter Overview',
        onBack: () => context.go(AppRoutes.chapter(id)),
        center: Text(
          '$count Shlokas',
          style: t.ui.copyWith(fontSize: 12, color: c.textSecondary),
        ),
      ),
      body: switch (verses) {
        AsyncData(value: final list) when list.isEmpty => EmptyState(
          icon: Icons.format_list_numbered,
          title: 'No verses saved yet',
          message:
              'The verses of this chapter appear here once they have been downloaded.',
          action: OutlinedButton(
            onPressed: () => context.go(AppRoutes.chapter(id)),
            child: const Text('Chapter overview'),
          ),
        ),
        AsyncData(value: final list) => _buildList(context, id, chapter, list),
        AsyncError() => const ErrorState(),
        _ => const LoadingState(),
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    int id,
    LocalChapter? chapter,
    List<LocalShloka> all,
  ) {
    final c = context.colors;
    final t = context.text;
    final last = all.last.verseNumber;
    final ranges = [
      for (var start = 1; start <= last; start += _rangeSize)
        (start, (start + _rangeSize - 1).clamp(1, last)),
    ];
    final selected = _range != null && _range! < ranges.length
        ? ranges[_range!]
        : null;
    final shown = selected == null
        ? all
        : all
              .where(
                (v) =>
                    v.verseNumber >= selected.$1 &&
                    v.verseNumber <= selected.$2,
              )
              .toList();

    return ReadingWidth(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel('Chapter $id Index'),
                  if (chapter != null)
                    Text(
                      '${chapter.englishName} Verses',
                      style: t.headline.copyWith(fontSize: 18),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Every verse with its heading and summary. Select any verse to read.',
                    style: t.commentary.copyWith(
                      fontSize: 13,
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.gutter),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.page,
                ),
                children: [
                  for (final (i, r) in ranges.indexed) ...[
                    PillChip(
                      label: '$id.${r.$1} – $id.${r.$2}',
                      selected: _range == i,
                      onTap: () => setState(() => _range = i),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  PillChip(
                    label: 'Show All (${all.length})',
                    selected: _range == null,
                    onTap: () => setState(() => _range = null),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.page),
            sliver: shown.isEmpty
                ? SliverToBoxAdapter(
                    child: Text(
                      'No verses of this range are saved yet.',
                      textAlign: TextAlign.center,
                      style: t.commentary.copyWith(color: c.textSecondary),
                    ),
                  )
                : SliverList.separated(
                    itemCount: shown.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => VerseTile(
                      verse: shown[i],
                      onTap: () =>
                          context.go(AppRoutes.verse(id, shown[i].verseNumber)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

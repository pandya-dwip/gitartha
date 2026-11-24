import 'dart:async';

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
import 'widgets/chapter_cards.dart';

/// code.html "Chapter Library": all chapters, plus local search over the
/// cached scripture (DESIGN.md search input).
class ChapterLibraryScreen extends ConsumerStatefulWidget {
  const ChapterLibraryScreen({super.key});

  @override
  ConsumerState<ChapterLibraryScreen> createState() =>
      _ChapterLibraryScreenState();
}

class _ChapterLibraryScreenState extends ConsumerState<ChapterLibraryScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  void _clear() {
    _debounce?.cancel();
    _search.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final chapters = ref.watch(localChaptersProvider);
    final summaries = ref.watch(chapterSummariesProvider);
    final verses = ref.watch(cachedVerseCountProvider);

    return Scaffold(
      body: SafeArea(
        child: ReadingWidth(
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.gutter,
                    AppSpacing.page,
                    AppSpacing.gutter,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: c.border.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHAPTER LIBRARY',
                              style: t.headline.copyWith(
                                fontSize: 18,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              'श्रीमद्भगवद्गीता — अष्टादश अध्यायाः',
                              style: t.sanskrit.copyWith(
                                fontSize: 12,
                                color: c.accent,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.well,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                          border: Border.all(color: c.border),
                        ),
                        child: Text(
                          '$verses Verses',
                          style: t.ui.copyWith(fontSize: 12, color: c.accent),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _search,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search a verse, e.g. 2.47 or “duty”',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: _clear,
                            ),
                    ),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                _SearchResults(
                  query: _query,
                  chapters: chapters.value ?? const [],
                )
              else
                switch (chapters) {
                  AsyncData(value: final list) when list.isEmpty =>
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        icon: Icons.auto_stories_outlined,
                        title: 'No chapters yet',
                        message:
                            'The chapters appear here once scripture has been downloaded. '
                            'Use Settings → Scripture Updates to download it.',
                      ),
                    ),
                  AsyncData(value: final list) => SliverPadding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    sliver: SliverList.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.gutter),
                      itemBuilder: (context, i) => ChapterCard(
                        chapter: list[i],
                        summary: summaries[list[i].id],
                        onTap: () => context.go(AppRoutes.chapter(list[i].id)),
                      ),
                    ),
                  ),
                  AsyncError() => const SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(),
                  ),
                  _ => const SliverFillRemaining(child: LoadingState()),
                },
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({required this.query, required this.chapters});

  final String query;
  final List<LocalChapter> chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = query.toLowerCase();
    final chapterHits = [
      for (final ch in chapters)
        if ('${ch.id}' == q ||
            ch.englishName.toLowerCase().contains(q) ||
            ch.sanskritName.contains(query) ||
            ch.hindiName.contains(query))
          ch,
    ];
    final verses = ref.watch(verseSearchProvider(query));

    return switch (verses) {
      AsyncData(value: final hits) when hits.isEmpty && chapterHits.isEmpty =>
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Icons.search_off,
            title: 'No matches',
            message: 'Nothing saved on this device matches “$query”.',
          ),
        ),
      AsyncData(value: final hits) => SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.page),
        sliver: SliverList.list(
          children: [
            if (chapterHits.isNotEmpty) ...[
              const SectionLabel('Chapters', icon: Icons.menu_book_outlined),
              const SizedBox(height: AppSpacing.sm),
              for (final ch in chapterHits) ...[
                ChapterPreviewTile(
                  chapter: ch,
                  verses:
                      ref
                          .watch(chapterSummariesProvider)[ch.id]
                          ?.totalShlokas ??
                      0,
                  onTap: () => context.go(AppRoutes.chapter(ch.id)),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
            if (hits.isNotEmpty) ...[
              SectionLabel(
                hits.length == 50
                    ? 'First 50 verses'
                    : '${hits.length} verse${hits.length == 1 ? '' : 's'}',
                icon: Icons.format_list_numbered,
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final v in hits) ...[
                VerseTile(
                  verse: v,
                  showReference: true,
                  onTap: () =>
                      context.go(AppRoutes.verse(v.chapterId, v.verseNumber)),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
      AsyncError() => const SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorState(),
      ),
      _ => const SliverFillRemaining(child: LoadingState()),
    };
  }
}

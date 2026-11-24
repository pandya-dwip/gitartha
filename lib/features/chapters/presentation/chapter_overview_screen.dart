import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../../app/widgets/state_views.dart';
import '../../../data/local/database/app_database.dart';
import '../../shlokas/presentation/providers/scripture_providers.dart';

/// code.html "Chapter Overview": titles, central theme, introduction, main
/// topics; plus the other cached descriptive fields (overview, summary,
/// conclusion) in the same style. Missing fields are simply not shown.
class ChapterOverviewScreen extends ConsumerWidget {
  const ChapterOverviewScreen({super.key, required this.chapterId});

  final int? chapterId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = chapterId;
    final chapter = id == null
        ? const AsyncData<LocalChapter?>(null)
        : ref.watch(chapterProvider(id));
    final verses = id == null
        ? 0
        : ref.watch(chapterSummariesProvider)[id]?.totalShlokas ?? 0;

    return Scaffold(
      appBar: InnerTopBar(
        backLabel: 'Chapters',
        onBack: () => context.go(AppRoutes.chapters),
        center: Text(
          id == null ? '' : 'Chapter $id of 18',
          style: context.text.ui.copyWith(
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      body: switch (chapter) {
        AsyncData(value: final ch?) => _Overview(chapter: ch, verses: verses),
        AsyncData() => EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Chapter not available',
          message: 'This chapter is not saved on this device.',
          action: OutlinedButton(
            onPressed: () => context.go(AppRoutes.chapters),
            child: const Text('All chapters'),
          ),
        ),
        AsyncError() => const ErrorState(),
        _ => const LoadingState(),
      },
    );
  }
}

class _Overview extends StatelessWidget {
  const _Overview({required this.chapter, required this.verses});

  final LocalChapter chapter;
  final int verses;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    void openIndex() => context.go(AppRoutes.verses(chapter.id));
    final topics = chapter.keyTopics ?? const [];

    Widget section(String title, String? body) => body == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionLabel(title, accent: false),
                const SizedBox(height: AppSpacing.sm),
                SacredCard(child: Text(body, style: t.commentary)),
              ],
            ),
          );

    return ReadingWidth(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          SacredCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  'Chapter ${chapter.id}'.toUpperCase(),
                  style: t.meta.copyWith(color: c.accent, letterSpacing: 2.4),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  chapter.sanskritName,
                  textAlign: TextAlign.center,
                  style: t.sanskrit.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                Text(
                  chapter.englishName,
                  textAlign: TextAlign.center,
                  style: t.headline.copyWith(color: c.accent, fontSize: 16),
                ),
                Text(
                  '(${chapter.hindiName})',
                  textAlign: TextAlign.center,
                  style: t.sanskrit.copyWith(
                    fontSize: 13,
                    color: c.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.gutter),
                const SacredDivider(width: 128),
                const SizedBox(height: AppSpacing.gutter),
                Text(
                  '$verses Shlokas',
                  style: t.ui.copyWith(fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: verses == 0 ? null : openIndex,
                    icon: const Icon(Icons.format_list_numbered, size: 18),
                    label: Text(
                      verses == 0
                          ? 'No verses saved yet'
                          : 'Explore All $verses Verses',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (chapter.centralTheme != null) ...[
            SacredCard(
              tone: SacredTone.well,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    'Central Theme',
                    icon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(chapter.centralTheme!, style: t.commentary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          section('Introduction', chapter.introduction),
          section('Overview', chapter.overview),
          if (topics.isNotEmpty) ...[
            const SectionLabel('Main Topics Covered', accent: false),
            const SizedBox(height: AppSpacing.sm),
            for (final (i, topic) in topics.indexed) ...[
              SacredCard(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: c.accent.withValues(alpha: 0.2),
                      child: Text(
                        '${i + 1}',
                        style: t.ui.copyWith(
                          fontSize: 11,
                          color: c.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic,
                        style: t.commentary.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.md),
          ],
          section('Summary', chapter.summary),
          section('Conclusion', chapter.conclusion),
          if (chapter.centralTheme == null &&
              chapter.introduction == null &&
              chapter.overview == null &&
              topics.isEmpty &&
              chapter.summary == null &&
              chapter.conclusion == null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'The chapter introduction has not been written yet.',
                textAlign: TextAlign.center,
                style: t.commentary.copyWith(
                  color: c.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (verses > 0)
            FilledButton.icon(
              onPressed: openIndex,
              icon: const Icon(Icons.format_list_bulleted, size: 18),
              label: Text(
                'Open Chapter ${chapter.id} Verse Index ($verses Shlokas)',
              ),
            ),
        ],
      ),
    );
  }
}

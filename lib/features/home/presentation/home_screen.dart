import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../../app/widgets/state_views.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/local_database_providers.dart';
import '../../chapters/presentation/widgets/chapter_cards.dart';
import '../../settings/presentation/settings_sheet.dart';
import '../../shlokas/presentation/providers/scripture_providers.dart';
import '../../synchronization/domain/sync_result.dart';
import '../../synchronization/presentation/providers/content_sync_provider.dart';
import '../../../app/motion/motion.dart';

/// code.html "Home": continue reading, daily contemplation, calm progress
/// and a preview of the chapters. Everything comes from SQLite.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapters = ref.watch(localChaptersProvider);
    return Scaffold(
      body: SafeArea(
        child: ReadingWidth(
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: _HomeHeader()),
              ...switch (chapters) {
                AsyncData(value: final list) when list.isEmpty => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _NothingCached(),
                  ),
                ],
                AsyncData(value: final list) => [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.page,
                      AppSpacing.page,
                      AppSpacing.lg,
                    ),
                    sliver: SliverList.list(
                      children: [
                        FadeSlideIn(
                          child: _ContinueReading(firstChapter: list.first),
                        ),
                        const SizedBox(height: AppSpacing.page),
                        const FadeSlideIn(
                          index: 1,
                          child: _DailyContemplation(),
                        ),
                        const FadeSlideIn(
                          index: 2,
                          child: _ContemplationProgress(),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FadeSlideIn(
                          index: 3,
                          child: _ChapterPreview(chapters: list),
                        ),
                      ],
                    ),
                  ),
                ],
                AsyncError() => [
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(),
                  ),
                ],
                _ => [const SliverFillRemaining(child: LoadingState())],
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.gutter,
        AppSpacing.page,
        AppSpacing.gutter,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  children: [
                    Text(
                      'गीतार्थ',
                      style: t.sanskrit.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: c.accent,
                        height: 1.4,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        border: Border.all(
                          color: c.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'GITARTHA',
                        style: t.meta.copyWith(color: c.accent, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Peace to the mind, stillness to the heart',
                  style: t.commentary.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 6),
          HeaderIconButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings & About',
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
    );
  }
}

/// First launch (or nothing downloaded yet): explain, offer a sync.
class _NothingCached extends ConsumerWidget {
  const _NothingCached();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(contentSyncProvider);
    final offline = sync.status == SyncStatus.offline;
    return EmptyState(
      icon: offline ? Icons.cloud_off_outlined : Icons.auto_stories_outlined,
      title: sync.isRunning
          ? 'Downloading scripture…'
          : 'No scripture on this device yet',
      message: sync.isRunning
          ? 'The chapters will appear here as soon as they are saved.'
          : offline
          ? 'You are offline. Connect to the internet once to download the '
                'Bhagavad Gita; afterwards it is available offline.'
          : sync.message ??
                'Download the Bhagavad Gita once to read it, offline or online.',
      action: sync.isRunning
          ? const CircularProgressIndicator()
          : FilledButton.icon(
              onPressed: () =>
                  ref.read(contentSyncProvider.notifier).syncContentManually(),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Download scripture'),
            ),
    );
  }
}

class _ContinueReading extends ConsumerWidget {
  const _ContinueReading({required this.firstChapter});

  final LocalChapter firstChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final last = ref.watch(lastOpenedShlokaProvider).value;
    final chapter = last == null
        ? firstChapter
        : ref.watch(chapterProvider(last.chapterId)).value ?? firstChapter;
    final firstLine = last?.sanskritText?.split('\n').first;
    final gloss = last?.indexSummary ?? last?.englishMeaning;

    void open() => context.go(
      last == null
          ? AppRoutes.chapter(chapter.id)
          : AppRoutes.verse(last.chapterId, last.verseNumber),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionLabel(
                'Continue Reading',
                icon: Icons.menu_book_outlined,
              ),
            ),
            if (last != null)
              Flexible(
                child: Text(
                  'Chapter ${last.chapterId} • Verse ${last.verseNumber}',
                  textAlign: TextAlign.end,
                  style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SacredCard(
          onTap: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapter ${chapter.id} — ${chapter.englishName}'
                              .toUpperCase(),
                          style: t.meta.copyWith(color: c.accent, fontSize: 11),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          firstLine == null
                              ? chapter.sanskritName
                              : '$firstLine…',
                          style: t.sanskrit.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.6,
                          ),
                        ),
                        if (gloss != null || last == null)
                          Text(
                            gloss ??
                                'Begin your reading with the first chapter.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: t.commentary.copyWith(
                              fontSize: 13,
                              height: 1.5,
                              color: c.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: c.well,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(Icons.play_arrow, color: c.accent),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.gutter),
              Divider(color: c.border.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.gutter),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      last == null
                          ? 'Not started yet'
                          : 'Last read: Shloka ${last.reference}',
                      style: t.ui.copyWith(
                        fontSize: 12,
                        color: c.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    last == null ? 'Open Chapter' : 'Open Shloka',
                    style: t.ui.copyWith(
                      fontSize: 12,
                      color: c.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 14, color: c.accent),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyContemplation extends ConsumerWidget {
  const _DailyContemplation();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verse = ref.watch(dailyShlokaProvider).value;
    if (verse == null) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionLabel(
                  'Daily Contemplation',
                  icon: Icons.wb_twilight_outlined,
                ),
              ),
              Flexible(
                child: Text(
                  'Gita ${verse.reference}',
                  style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SacredCard(
            emphasized: true,
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -24,
                  child: ExcludeSemantics(
                    child: Text(
                      'ॐ',
                      style: t.sanskrit.copyWith(
                        fontSize: 72,
                        color: c.accent.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      verse.sanskritText!,
                      textAlign: TextAlign.center,
                      style: t.sanskrit.copyWith(fontSize: 16, height: 1.75),
                    ),
                    if (verse.englishMeaning != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '“${verse.englishMeaning}”',
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: t.commentary.copyWith(
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.gutter),
                    Divider(color: c.border.withValues(alpha: 0.6)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            verse.indexTitle == null
                                ? ''
                                : 'Key Insight: ${verse.indexTitle}',
                            style: t.ui.copyWith(
                              fontSize: 11,
                              color: c.textSecondary,
                            ),
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                          ),
                          onPressed: () => context.go(
                            AppRoutes.verse(verse.chapterId, verse.verseNumber),
                          ),
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(Icons.menu_book_outlined, size: 16),
                          label: const Text('Reflect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// code.html "Scripture Contemplation": calm, non-gamified progress.
class _ContemplationProgress extends ConsumerWidget {
  const _ContemplationProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final explored = ref
        .watch(chapterSummariesProvider)
        .values
        .where((s) => s.opened > 0)
        .length;
    return SacredCard(
      tone: SacredTone.well,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionLabel(
                  'Scripture Contemplation',
                  icon: Icons.hourglass_top_outlined,
                  accent: false,
                ),
              ),
              Flexible(
                child: Text(
                  '$explored of 18 Chapters explored',
                  textAlign: TextAlign.end,
                  style: t.ui.copyWith(fontSize: 12, color: c.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xl),
            child: LinearProgressIndicator(value: explored / 18, minHeight: 8),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '“One step at a time into timeless wisdom, without rush or expectation.”',
            textAlign: TextAlign.center,
            style: t.commentary.copyWith(
              fontSize: 12,
              height: 1.4,
              fontStyle: FontStyle.italic,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterPreview extends ConsumerWidget {
  const _ChapterPreview({required this.chapters});

  final List<LocalChapter> chapters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final summaries = ref.watch(chapterSummariesProvider);
    final verses = ref.watch(cachedVerseCountProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'THE CHAPTERS (अध्यायाः)',
                    style: t.ui.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    '$verses sacred verses saved on this device',
                    style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.chapters),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final chapter in chapters.take(3)) ...[
          ChapterPreviewTile(
            chapter: chapter,
            verses: summaries[chapter.id]?.totalShlokas ?? 0,
            onTap: () => context.go(AppRoutes.chapter(chapter.id)),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

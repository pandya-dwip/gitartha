import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../../app/widgets/state_views.dart';
import '../../../data/local/database/app_database.dart';
import '../../../data/local/database/tables/reading_progress.dart';
import '../../../data/local/local_database_providers.dart';
import '../../journal/presentation/journal_editors.dart';
import '../../journal/presentation/providers/personal_providers.dart';
import '../../settings/presentation/providers/app_settings_provider.dart';
import '../../settings/presentation/settings_sheet.dart';
import 'providers/scripture_providers.dart';

/// code.html "Individual Shloka Reader", in its strict reading order:
/// Sanskrit → Pronunciation → Hindi (+ note) → English → Context →
/// Life Lesson → Spiritual Meaning → Reflection Question, then the personal
/// journal for this verse, sources and previous / next.
class ShlokaReaderScreen extends ConsumerStatefulWidget {
  const ShlokaReaderScreen({
    super.key,
    required this.chapterId,
    required this.verseNumber,
  });

  final int? chapterId;
  final int? verseNumber;

  @override
  ConsumerState<ShlokaReaderScreen> createState() => _ShlokaReaderScreenState();
}

class _ShlokaReaderScreenState extends ConsumerState<ShlokaReaderScreen> {
  /// The verse whose "opened" event was recorded (once per verse shown, not
  /// per rebuild).
  String? _recordedId;

  void _recordOpened(String shlokaId) {
    if (_recordedId == shlokaId) return;
    _recordedId = shlokaId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(personalActionsProvider).openShloka(shlokaId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chapterId = widget.chapterId;
    final verseNumber = widget.verseNumber;
    if (chapterId == null || verseNumber == null) {
      return const _NotFound(chapterId: null);
    }
    final verses = ref.watch(localShlokasForChapterProvider(chapterId));

    return switch (verses) {
      AsyncData(value: final list) => () {
        final i = list.indexWhere((v) => v.verseNumber == verseNumber);
        if (i < 0) return _NotFound(chapterId: chapterId);
        final verse = list[i];
        _recordOpened(verse.id);
        return _Reader(
          verse: verse,
          position: i,
          total: list.length,
          previous: i > 0 ? list[i - 1] : null,
          next: i < list.length - 1 ? list[i + 1] : null,
        );
      }(),
      AsyncError() => const Scaffold(body: ErrorState()),
      _ => const Scaffold(body: LoadingState()),
    };
  }
}

class _NotFound extends StatelessWidget {
  const _NotFound({required this.chapterId});

  final int? chapterId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: EmptyState(
      icon: Icons.menu_book_outlined,
      title: 'Verse not available',
      message: 'This verse is not saved on this device.',
      action: OutlinedButton(
        onPressed: () => context.go(
          chapterId == null ? AppRoutes.chapters : AppRoutes.verses(chapterId!),
        ),
        child: Text(chapterId == null ? 'All chapters' : 'Verse index'),
      ),
    ),
  );
}

class _Reader extends ConsumerWidget {
  const _Reader({
    required this.verse,
    required this.position,
    required this.total,
    required this.previous,
    required this.next,
  });

  final LocalShloka verse;
  final int position;
  final int total;
  final LocalShloka? previous;
  final LocalShloka? next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final fontSize =
        ref.watch(readerFontSizeProvider).value ?? ReaderFontSize.medium;
    final bookmarked = ref.watch(isBookmarkedProvider(verse.id)).value ?? false;
    final chapterId = verse.chapterId;

    Future<void> toggleBookmark() async {
      final messenger = ScaffoldMessenger.of(context);
      await ref
          .read(personalActionsProvider)
          .toggleBookmark(verse.id, bookmarked: bookmarked);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              bookmarked ? 'Bookmark removed' : 'Saved to Bookmarks',
            ),
          ),
        );
    }

    final hasContent = [
      verse.sanskritText,
      verse.transliteration,
      verse.hindiMeaning,
      verse.englishMeaning,
      verse.context,
      verse.lifeLesson,
      verse.spiritualMeaning,
      verse.reflectionQuestion,
    ].any((f) => f != null);

    final media = MediaQuery.of(context);
    return Scaffold(
      appBar: InnerTopBar(
        backLabel: 'Index',
        backIcon: Icons.format_list_bulleted,
        onBack: () => context.go(AppRoutes.verses(chapterId)),
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BG ${verse.reference}',
              style: t.ui.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Verse ${position + 1} of $total',
              style: t.ui.copyWith(fontSize: 10, color: c.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeaderIconButton(
              icon: Icons.format_size,
              label: fontSize.label,
              tooltip: 'Text size: ${fontSize.title}',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final next = await ref
                    .read(appSettingsActionsProvider)
                    .cycleFontSize();
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        'Typography: ${next.title} (${next.label})',
                      ),
                    ),
                  );
              },
            ),
            const SizedBox(width: 6),
            HeaderIconButton(
              icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
              active: bookmarked,
              tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark this verse',
              onPressed: toggleBookmark,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (position + 1) / total, minHeight: 3),
          Expanded(
            child: MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  media.textScaler.scale(1) * fontSize.scale,
                ),
              ),
              child: ReadingWidth(
                child: ListView(
                  key: PageStorageKey(verse.id),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.lg,
                    AppSpacing.page,
                    AppSpacing.xl,
                  ),
                  children: [
                    Text(
                      'Bhagavad Gita — Chapter $chapterId, Verse ${verse.verseNumber}'
                          .toUpperCase(),
                      textAlign: TextAlign.center,
                      style: t.meta.copyWith(
                        color: c.accent,
                        fontSize: 11,
                        letterSpacing: 2,
                      ),
                    ),
                    if (verse.indexTitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          verse.indexTitle!,
                          textAlign: TextAlign.center,
                          style: t.headline.copyWith(fontSize: 17),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    if (!hasContent)
                      const EmptyState(
                        icon: Icons.hourglass_empty,
                        title: 'Not written yet',
                        message:
                            'The text and explanation of this verse have not been added yet.',
                      ),
                    if (verse.sanskritText != null)
                      SacredCard(
                        emphasized: true,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Text(
                              '— संस्कृतम् (Sanskrit) —',
                              style: t.meta.copyWith(
                                color: c.accent,
                                fontSize: 10,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.gutter),
                            SelectableText(
                              verse.sanskritText!,
                              textAlign: TextAlign.center,
                              style: t.sanskrit.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const SacredDivider(width: 112),
                          ],
                        ),
                      ),
                    _Section(
                      label: 'Pronunciation & Transliteration',
                      icon: Icons.record_voice_over_outlined,
                      text: verse.transliteration,
                      style: t.transliteration,
                      tone: SacredTone.well,
                      accentLabel: false,
                    ),
                    _Section(
                      label: 'हिन्दी अनुवाद (Hindi Meaning)',
                      icon: Icons.translate,
                      text: verse.hindiMeaning,
                      style: t.sanskrit.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.75,
                      ),
                      footer: verse.hindiMeaningNote == null
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.sm,
                              ),
                              child: Text(
                                'टिप्पणी (Note): ${verse.hindiMeaningNote}',
                                style: t.sanskrit.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.6,
                                  color: c.textSecondary,
                                ),
                              ),
                            ),
                    ),
                    _Section(
                      label: 'English Meaning',
                      icon: Icons.menu_book_outlined,
                      text: verse.englishMeaning,
                      style: t.translation,
                    ),
                    _Section(
                      label: 'Context — What is happening here?',
                      icon: Icons.explore_outlined,
                      text: verse.context,
                      style: t.commentary,
                      tone: SacredTone.well,
                      accentLabel: false,
                    ),
                    _Section(
                      label: 'Life Lesson',
                      icon: Icons.psychology_outlined,
                      text: verse.lifeLesson,
                      style: t.commentary,
                    ),
                    _Section(
                      label: 'Spiritual Meaning',
                      icon: Icons.self_improvement,
                      text: verse.spiritualMeaning,
                      style: t.commentary,
                    ),
                    _Section(
                      label: 'Reflection Question',
                      icon: Icons.help_outline,
                      text: verse.reflectionQuestion,
                      style: t.commentary.copyWith(fontStyle: FontStyle.italic),
                      tone: SacredTone.well,
                      emphasized: true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _ProgressRow(verse: verse),
                    const SizedBox(height: AppSpacing.lg),
                    _VerseJournal(verse: verse),
                    _Sources(shlokaId: verse.id),
                    const SizedBox(height: AppSpacing.lg),
                    _PrevNext(
                      chapterId: chapterId,
                      previous: previous,
                      next: next,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One labelled reading section (label + icon above the text).
class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.icon,
    required this.text,
    required this.style,
    this.tone = SacredTone.card,
    this.emphasized = false,
    this.accentLabel = true,
    this.footer,
  });

  final String label;
  final IconData icon;
  final String? text;
  final TextStyle style;
  final SacredTone tone;
  final bool emphasized;
  final bool accentLabel;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: SacredCard(
        tone: tone,
        emphasized: emphasized,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label, icon: icon, accent: accentLabel),
            const SizedBox(height: AppSpacing.sm),
            SelectableText(text!, style: style),
            ?footer,
          ],
        ),
      ),
    );
  }
}

/// Explicit progress: opening a verse never marks it read or studied.
class _ProgressRow extends ConsumerWidget {
  const _ProgressRow({required this.verse});

  final LocalShloka verse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final status = ref.watch(progressProvider(verse.id)).value?.status;
    final rank = status?.rank ?? -1;

    Widget mark(ReadingStatus target, String label, IconData icon) =>
        OutlinedButton.icon(
          onPressed: rank >= target.rank
              ? null
              : () => ref.read(personalActionsProvider).mark(verse.id, target),
          icon: Icon(rank >= target.rank ? Icons.check : icon, size: 18),
          label: Text(label),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          switch (status) {
            ReadingStatus.reflected => 'You have reflected on this verse.',
            ReadingStatus.studied => 'You have studied this verse.',
            ReadingStatus.read => 'You have read this verse.',
            _ => 'Mark your progress when you are ready.',
          },
          textAlign: TextAlign.center,
          style: t.ui.copyWith(fontSize: 12, color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(child: mark(ReadingStatus.read, 'Read', Icons.done)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: mark(
                ReadingStatus.studied,
                'Studied',
                Icons.school_outlined,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The verse's personal journal: dated reflection answers and notes. Local
/// to this device.
class _VerseJournal extends ConsumerStatefulWidget {
  const _VerseJournal({required this.verse});

  final LocalShloka verse;

  @override
  ConsumerState<_VerseJournal> createState() => _VerseJournalState();
}

class _VerseJournalState extends ConsumerState<_VerseJournal> {
  final _answer = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _answer.text;
    if (text.trim().isEmpty) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(personalActionsProvider)
          .addReflection(widget.verse.id, text);
      _answer.clear();
      if (mounted) FocusScope.of(context).unfocus();
      messenger.showSnackBar(
        const SnackBar(content: Text('Reflection saved on this device.')),
      );
    } on Object {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('The reflection could not be saved. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final verse = widget.verse;
    final reflections =
        ref.watch(reflectionsForShlokaProvider(verse.id)).value ?? const [];
    final notes = ref.watch(notesForShlokaProvider(verse.id)).value ?? const [];

    return SacredCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel(
            'My Personal Journal & Reflections',
            icon: Icons.edit_note,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Private: kept only on this device.',
            style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
          ),
          if (verse.reflectionQuestion != null) ...[
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _answer,
              enabled: !_saving,
              minLines: 3,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Write your answer to the reflection question…',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _saving || _answer.text.trim().isEmpty
                    ? null
                    : _save,
                child: Text(
                  reflections.isEmpty
                      ? 'Save reflection'
                      : 'Save new reflection',
                ),
              ),
            ),
          ],
          for (final r in reflections.reversed) ...[
            const SizedBox(height: AppSpacing.gutter),
            SacredCard(
              tone: SacredTone.well,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.sm,
                AppSpacing.xs,
                AppSpacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatDateTime(context, r.createdAt) +
                              (r.updatedAt != r.createdAt ? ' · edited' : ''),
                          style: t.meta.copyWith(fontSize: 11),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit reflection',
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => showReflectionEditor(context, ref, r),
                      ),
                      IconButton(
                        tooltip: 'Delete reflection',
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          if (await confirmDelete(
                            context,
                            'Delete this reflection?',
                          )) {
                            await ref
                                .read(personalActionsProvider)
                                .deleteReflection(r.id);
                          }
                        },
                      ),
                    ],
                  ),
                  Text(r.answer, style: t.commentary),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Divider(color: c.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: SectionLabel(
                  'Notes (${notes.length})',
                  icon: Icons.sticky_note_2_outlined,
                  accent: false,
                ),
              ),
              TextButton.icon(
                onPressed: () => showNoteEditor(
                  context,
                  shlokaId: verse.id,
                  reference: verse.reference,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add note'),
              ),
            ],
          ),
          for (final note in notes)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                note.title ?? note.content,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.ui,
              ),
              subtitle: note.title == null
                  ? null
                  : Text(
                      note.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.ui.copyWith(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                    ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showNoteEditor(
                context,
                note: note,
                reference: verse.reference,
              ),
            ),
        ],
      ),
    );
  }
}

/// Sources credited for this verse (licence / required attribution text).
class _Sources extends ConsumerWidget {
  const _Sources({required this.shlokaId});

  final String shlokaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credits =
        ref.watch(sourceCreditsProvider(shlokaId)).value ?? const [];
    if (credits.isEmpty) return const SizedBox.shrink();
    final c = context.colors;
    final t = context.text;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            'Sources',
            icon: Icons.library_books_outlined,
            accent: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final credit in credits)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: credit.source.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (credit.source.author != null)
                      TextSpan(text: ', ${credit.source.author}'),
                    TextSpan(
                      text:
                          ' — ${credit.sections.map((s) => s.replaceAll('_', ' ')).join(', ')}',
                    ),
                    if (credit.source.attribution != null)
                      TextSpan(text: '\n${credit.source.attribution}'),
                    if (credit.source.license != null)
                      TextSpan(text: ' (${credit.source.license})'),
                  ],
                ),
                style: t.ui.copyWith(fontSize: 12, color: c.textSecondary),
              ),
            ),
        ],
      ),
    );
  }
}

class _PrevNext extends StatelessWidget {
  const _PrevNext({
    required this.chapterId,
    required this.previous,
    required this.next,
  });

  final int chapterId;
  final LocalShloka? previous;
  final LocalShloka? next;

  @override
  Widget build(BuildContext context) {
    final p = previous;
    final n = next;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: context.colors.border),
            ),
            onPressed: p == null
                ? null
                : () => context.go(AppRoutes.verse(chapterId, p.verseNumber)),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: Text(
              p == null ? 'Beginning' : 'Verse ${p.reference}',
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.outlined(
          tooltip: 'Back to verse index',
          style: IconButton.styleFrom(
            foregroundColor: context.colors.accent,
            side: BorderSide(color: context.colors.border),
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => context.go(AppRoutes.verses(chapterId)),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: FilledButton.icon(
            onPressed: n == null
                ? null
                : () => context.go(AppRoutes.verse(chapterId, n.verseNumber)),
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(
              n == null ? 'End of Ch $chapterId' : 'Verse ${n.reference}',
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }
}

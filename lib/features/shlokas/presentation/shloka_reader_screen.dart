import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/motion/motion.dart';
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

  /// The chapter's verses as pages: the neighbours are built ahead of time
  /// and slide with the finger, like turning pages in a book.
  PageController? _pages;

  /// The verse in the URL changed from outside the pager (Previous / Next
  /// buttons, a link): the pager follows it after this frame.
  bool _follow = false;

  @override
  void didUpdateWidget(ShlokaReaderScreen old) {
    super.didUpdateWidget(old);
    if (old.verseNumber != widget.verseNumber) _follow = true;
  }

  @override
  void dispose() {
    _pages?.dispose();
    super.dispose();
  }

  void _recordOpened(String shlokaId) {
    if (_recordedId == shlokaId) return;
    _recordedId = shlokaId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(personalActionsProvider).openShloka(shlokaId),
    );
  }

  void _followTo(int index) {
    _follow = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pages = _pages;
      if (!mounted || pages == null || !pages.hasClients) return;
      final current = pages.page?.round() ?? index;
      if (current == index) return;
      if ((current - index).abs() == 1 && !Motion.reduced(context)) {
        pages.animateToPage(
          index,
          duration: Motion.gentle,
          curve: Motion.enter,
        );
      } else {
        pages.jumpToPage(index);
      }
    });
  }

  /// When a swipe settles on another verse, that verse becomes the URL, so
  /// back navigation, bookmarks and "Continue Reading" all see it. Done on
  /// settle (not mid-swipe) so nothing rebuilds while the page moves.
  bool _settled(ScrollEndNotification n, List<LocalShloka> list) {
    if (n.depth != 0) return false; // a verse's own vertical scrolling
    final p = _pages?.page?.round();
    if (p == null || p < 0 || p >= list.length) return false;
    final verse = list[p];
    if (verse.verseNumber != widget.verseNumber) {
      context.go(AppRoutes.verse(verse.chapterId, verse.verseNumber));
    }
    return false;
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
        _recordOpened(list[i].id);
        _pages ??= PageController(initialPage: i);
        if (_follow) _followTo(i);
        return _readerFrame(list, i);
      }(),
      AsyncError() => const Scaffold(body: ErrorState()),
      _ => const Scaffold(body: LoadingState()),
    };
  }

  /// Fixed top bar and progress line; only the verse pages move.
  Widget _readerFrame(List<LocalShloka> list, int position) {
    final c = context.colors;
    final t = context.text;
    final verse = list[position];
    final total = list.length;
    final fontSize =
        ref.watch(readerFontSizeProvider).value ?? ReaderFontSize.medium;
    final media = MediaQuery.of(context);

    return Scaffold(
      appBar: InnerTopBar(
        backLabel: 'Index',
        backIcon: Icons.format_list_bulleted,
        onBack: () => context.go(AppRoutes.verses(verse.chapterId)),
        center: AnimatedSwitcher(
          duration: Motion.of(context, Motion.quick),
          child: Column(
            key: ValueKey(verse.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'BG ${verse.reference}',
                textAlign: TextAlign.center,
                style: t.ui.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'Verse ${position + 1} of $total',
                textAlign: TextAlign.center,
                style: t.ui.copyWith(fontSize: 11, color: c.textSecondary),
              ),
            ],
          ),
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
            _BookmarkButton(shlokaId: verse.id),
          ],
        ),
      ),
      body: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(end: (position + 1) / total),
            duration: Motion.of(context, Motion.medium),
            curve: Motion.enter,
            builder: (_, value, _) =>
                LinearProgressIndicator(value: value, minHeight: 3),
          ),
          Expanded(
            child: MediaQuery(
              data: media.copyWith(
                textScaler: TextScaler.linear(
                  media.textScaler.scale(1) * fontSize.scale,
                ),
              ),
              // Outside the pager: inside it, text selection would win every
              // horizontal drag on Android and the pages would not swipe.
              // Selection starts with a long press, so the two never clash.
              child: SelectionArea(
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (n) => _settled(n, list),
                  child: PageView.builder(
                    controller: _pages,
                    allowImplicitScrolling: true,
                    itemCount: total,
                    itemBuilder: (context, p) => _Reader(
                      verse: list[p],
                      previous: p > 0 ? list[p - 1] : null,
                      next: p < total - 1 ? list[p + 1] : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

/// One verse page: the verse in its reading order, then the journal,
/// progress and previous / next.
class _Reader extends StatelessWidget {
  const _Reader({
    required this.verse,
    required this.previous,
    required this.next,
  });

  final LocalShloka verse;
  final LocalShloka? previous;
  final LocalShloka? next;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    final chapterId = verse.chapterId;

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

    return ReadingWidth(
      child: ListView(
        key: PageStorageKey(verse.id),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.lg,
          AppSpacing.page,
          AppSpacing.xl,
        ),
        children: [
          FadeSlideIn(
            child: _VerseHeading(
              chapterId: chapterId,
              verseNumber: verse.verseNumber,
              title: verse.indexTitle,
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
            FadeSlideIn(
              index: 1,
              child: SacredCard(
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
                    Text(
                      verse.sanskritText!,
                      textAlign: TextAlign.center,
                      style: t.sanskrit.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SacredDivider(width: 112),
                  ],
                ),
              ),
            ),
          _Section(
            index: 2,
            label: 'Pronunciation & Transliteration',
            icon: Icons.record_voice_over_outlined,
            text: verse.transliteration,
            style: t.transliteration,
            tone: SacredTone.well,
            accentLabel: false,
          ),
          _Section(
            index: 3,
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
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
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
            index: 4,
            label: 'English Meaning',
            icon: Icons.menu_book_outlined,
            text: verse.englishMeaning,
            style: t.translation,
          ),
          _Section(
            index: 5,
            label: 'Context — What is happening here?',
            icon: Icons.explore_outlined,
            text: verse.context,
            style: t.commentary,
            tone: SacredTone.well,
            accentLabel: false,
          ),
          _Section(
            index: 6,
            label: 'Life Lesson',
            icon: Icons.psychology_outlined,
            text: verse.lifeLesson,
            style: t.commentary,
          ),
          _Section(
            index: 7,
            label: 'Spiritual Meaning',
            icon: Icons.self_improvement,
            text: verse.spiritualMeaning,
            style: t.commentary,
          ),
          _Section(
            index: 8,
            label: 'Reflection Question',
            icon: Icons.help_outline,
            text: verse.reflectionQuestion,
            style: t.commentary.copyWith(fontStyle: FontStyle.italic),
            tone: SacredTone.well,
            emphasized: true,
          ),
          const SizedBox(height: _gap),
          SelectionContainer.disabled(child: _VerseJournal(verse: verse)),
          const SizedBox(height: _gap),
          SelectionContainer.disabled(child: _ProgressRow(verse: verse)),
          const SizedBox(height: AppSpacing.lg),
          SelectionContainer.disabled(
            child: _PrevNext(
              chapterId: chapterId,
              previous: previous,
              next: next,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bookmark toggle in the reader's top bar. It watches the bookmark state on
/// its own, so toggling rebuilds only this button, not the whole verse.
class _BookmarkButton extends ConsumerWidget {
  const _BookmarkButton({required this.shlokaId});

  final String shlokaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarked = ref.watch(isBookmarkedProvider(shlokaId)).value ?? false;

    Future<void> toggle() async {
      final messenger = ScaffoldMessenger.of(context);
      await ref
          .read(personalActionsProvider)
          .toggleBookmark(shlokaId, bookmarked: bookmarked);
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

    return HeaderIconButton(
      icon: bookmarked ? Icons.bookmark : Icons.bookmark_border,
      active: bookmarked,
      tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark this verse',
      onPressed: toggle,
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
    this.index = 0,
  });

  /// Position in the reading order, for the staggered entrance.
  final int index;
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
    return FadeSlideIn(
      index: index,
      child: Padding(
        padding: const EdgeInsets.only(top: _gap),
        child: SacredCard(
          tone: tone,
          emphasized: emphasized,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(label, icon: icon, accent: accentLabel),
              const SizedBox(height: AppSpacing.sm),
              Text(text!, style: style),
              ?footer,
            ],
          ),
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

    return SacredCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('My Progress', icon: Icons.flag_outlined),
          const SizedBox(height: AppSpacing.sm),
          Text(switch (status) {
            ReadingStatus.reflected => 'You have reflected on this verse.',
            ReadingStatus.studied => 'You have studied this verse.',
            ReadingStatus.read => 'You have read this verse.',
            _ => 'Mark your progress when you are ready.',
          }, style: t.ui.copyWith(fontSize: 13, color: c.textSecondary)),
          const SizedBox(height: AppSpacing.gutter),
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
      ),
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

/// Even spacing between the reading cards.
const _gap = AppSpacing.md;

/// "BHAGAVAD GITA — CHAPTER 1, VERSE 31", the verse title and a filigree
/// divider, centred as one block.
class _VerseHeading extends StatelessWidget {
  const _VerseHeading({
    required this.chapterId,
    required this.verseNumber,
    required this.title,
  });

  final int chapterId;
  final int verseNumber;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      children: [
        Text(
          'BHAGAVAD GITA',
          textAlign: TextAlign.center,
          style: t.meta.copyWith(
            color: c.accent,
            fontSize: 11,
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Chapter $chapterId · Verse $verseNumber',
          textAlign: TextAlign.center,
          style: t.ui.copyWith(color: c.textSecondary, fontSize: 12),
        ),
        if (title != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            title!,
            textAlign: TextAlign.center,
            style: t.headline.copyWith(fontSize: 19, height: 1.35),
          ),
        ],
        const SizedBox(height: AppSpacing.gutter),
        const SacredDivider(width: 120),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/widgets/sacred_widgets.dart';
import '../../../app/widgets/state_views.dart';
import '../../../data/local/database/app_database.dart';
import '../../settings/presentation/settings_sheet.dart';
import '../../shlokas/presentation/providers/scripture_providers.dart';
import 'journal_editors.dart';
import 'providers/personal_providers.dart';
import '../../../app/motion/motion.dart';

/// "My Journal" tab: reflection answers and personal notes, all stored only
/// on this device.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  bool _notes = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ReadingWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const TabHeader(
                title: 'MY JOURNAL',
                subtitle: 'Private contemplation, kept on this device',
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  AppSpacing.sm,
                ),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PillChip(
                      label: 'Reflections',
                      selected: !_notes,
                      onTap: () => setState(() => _notes = false),
                    ),
                    PillChip(
                      label: 'Notes',
                      selected: _notes,
                      onTap: () => setState(() => _notes = true),
                    ),
                    if (_notes)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                        onPressed: () => showNoteEditor(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New note'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: _notes ? const _NotesList() : const _ReflectionsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReflectionsList extends ConsumerWidget {
  const _ReflectionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(allReflectionsProvider)) {
      AsyncData(value: final list) when list.isEmpty => const EmptyState(
        icon: Icons.edit_note,
        title: 'No reflections yet',
        message:
            'Answer a verse’s reflection question while reading. Every answer is kept, dated, '
            'so you can see how your understanding grows.',
      ),
      AsyncData(value: final list) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.page),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) => FadeSlideIn(
          index: i,
          child: _ReflectionCard(reflection: list[i]),
        ),
      ),
      AsyncError() => const ErrorState(),
      _ => const LoadingState(),
    };
  }
}

class _ReflectionCard extends ConsumerWidget {
  const _ReflectionCard({required this.reflection});

  final Reflection reflection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    final verse = ref.watch(verseByIdProvider(reflection.shlokaId));
    final live = verse != null && verse.deletedAt == null;
    return SacredCard(
      onTap: live
          ? () =>
                context.go(AppRoutes.verse(verse.chapterId, verse.verseNumber))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${verse == null ? '' : 'BG ${verse.reference} · '}${formatDateTime(context, reflection.createdAt)}',
                  style: t.meta.copyWith(color: c.accent, fontSize: 11),
                ),
              ),
              IconButton(
                tooltip: 'Edit reflection',
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => showReflectionEditor(context, ref, reflection),
              ),
            ],
          ),
          if (verse?.reflectionQuestion != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                verse!.reflectionQuestion!,
                style: t.commentary.copyWith(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: c.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          Text(reflection.answer, style: t.commentary),
        ],
      ),
    );
  }
}

class _NotesList extends ConsumerWidget {
  const _NotesList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final t = context.text;
    return switch (ref.watch(allNotesProvider)) {
      AsyncData(value: final list) when list.isEmpty => EmptyState(
        icon: Icons.sticky_note_2_outlined,
        title: 'No notes yet',
        message:
            'Write notes about a verse while reading, or a free-standing note here.',
        action: FilledButton(
          onPressed: () => showNoteEditor(context),
          child: const Text('Write a note'),
        ),
      ),
      AsyncData(value: final list) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.page),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final note = list[i];
          final verse = note.shlokaId == null
              ? null
              : ref.watch(verseByIdProvider(note.shlokaId!));
          return FadeSlideIn(
            index: i,
            child: SacredCard(
              onTap: () => showNoteEditor(
                context,
                note: note,
                reference: verse?.reference,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${verse == null ? '' : 'BG ${verse.reference} · '}${formatDateTime(context, note.updatedAt)}',
                    style: t.meta.copyWith(color: c.accent, fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  if (note.title != null)
                    Text(
                      note.title!,
                      style: t.ui.copyWith(fontWeight: FontWeight.w600),
                    ),
                  Text(
                    note.content,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: t.commentary.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      AsyncError() => const ErrorState(),
      _ => const LoadingState(),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../data/local/database/app_database.dart';
import 'providers/personal_providers.dart';

/// Opens the note editor: a new note (optionally on [shlokaId]) or [note].
/// Saves to SQLite only.
Future<void> showNoteEditor(
  BuildContext context, {
  PersonalNote? note,
  String? shlokaId,
  String? reference,
}) {
  // A floating snackbar from an earlier save would cover the sheet's buttons.
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _NoteEditor(
      note: note,
      shlokaId: note?.shlokaId ?? shlokaId,
      reference: reference,
    ),
  );
}

class _NoteEditor extends ConsumerStatefulWidget {
  const _NoteEditor({this.note, this.shlokaId, this.reference});

  final PersonalNote? note;
  final String? shlokaId;
  final String? reference;

  @override
  ConsumerState<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends ConsumerState<_NoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title);
  late final _content = TextEditingController(text: widget.note?.content);
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_content.text.trim().isEmpty) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref
          .read(personalActionsProvider)
          .saveNote(
            noteId: widget.note?.id,
            shlokaId: widget.shlokaId,
            title: _title.text,
            content: _content.text,
          );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Note saved on this device.')),
      );
    } on Object {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('The note could not be saved. Please try again.'),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final note = widget.note!;
    if (!await confirmDelete(context, 'Delete this note?')) return;
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await ref.read(personalActionsProvider).deleteNote(note.id);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    final editing = widget.note != null;
    return Padding(
      // Keeps the fields above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Edit note' : 'New note',
              style: t.headline.copyWith(fontSize: 17),
            ),
            if (widget.reference != null)
              Text('On Bhagavad Gita ${widget.reference}', style: t.meta),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _title,
              enabled: !_busy,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Title (optional)'),
            ),
            const SizedBox(height: AppSpacing.gutter),
            TextField(
              controller: _content,
              enabled: !_busy,
              autofocus: !editing,
              minLines: 5,
              maxLines: 12,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Write your note…'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (editing)
                  IconButton(
                    tooltip: 'Delete note',
                    onPressed: _busy ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                const Spacer(),
                Flexible(
                  child: TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FilledButton(
                    onPressed: _busy || _content.text.trim().isEmpty
                        ? null
                        : _save,
                    child: const Text('Save note'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Edits an existing reflection in place (never creates a new one).
Future<void> showReflectionEditor(
  BuildContext context,
  WidgetRef ref,
  Reflection reflection,
) async {
  final text = await showDialog<String>(
    context: context,
    builder: (_) => _ReflectionEditDialog(initial: reflection.answer),
  );
  if (text != null && text.trim().isNotEmpty && text != reflection.answer) {
    await ref
        .read(personalActionsProvider)
        .updateReflection(reflection.id, text);
  }
}

/// Owns its controller, so it is disposed only after the dialog's exit
/// animation (disposing it right after `showDialog` returns would crash).
class _ReflectionEditDialog extends StatefulWidget {
  const _ReflectionEditDialog({required this.initial});

  final String initial;

  @override
  State<_ReflectionEditDialog> createState() => _ReflectionEditDialogState();
}

class _ReflectionEditDialogState extends State<_ReflectionEditDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Edit reflection'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      minLines: 4,
      maxLines: 10,
      textCapitalization: TextCapitalization.sentences,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Save'),
      ),
    ],
  );
}

Future<bool> confirmDelete(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'digits.dart';
import 'strings.dart';
import 'widgets.dart';

/// Private notebook for ONE student (observations, behaviour, progress...).
/// Saved with the Save button and automatically when you leave the page.
class StudentNoteScreen extends StatefulWidget {
  final Student student;
  const StudentNoteScreen({super.key, required this.student});

  @override
  State<StudentNoteScreen> createState() => _StudentNoteScreenState();
}

class _StudentNoteScreenState extends State<StudentNoteScreen> {
  final _db = DatabaseHelper.instance;
  late final TextEditingController _ctrl = TextEditingController(text: widget.student.note);
  late String _saved = widget.student.note;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool silent = false}) async {
    await _db.updateStudentNote(widget.student.id!, _ctrl.text);
    _saved = _ctrl.text;
    if (!silent && mounted) showSnack(context, context.t('saved'));
  }

  Future<void> _clear() async {
    if (_ctrl.text.trim().isEmpty) return;
    final ok = await confirmDialog(
      context,
      title: context.t('confirmDelete'),
      confirmLabel: context.t('delete'),
    );
    if (!ok) return;
    _ctrl.clear();
    await _save(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // Auto-save when leaving the page (only if something changed).
        if (didPop && _ctrl.text != _saved) {
          _db.updateStudentNote(s.id!, _ctrl.text);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(
              tooltip: context.t('delete'),
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: Text(context.t('save')),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Icon(
                    s.isFemale ? Icons.female_rounded : Icons.male_rounded,
                    color: s.isFemale ? const Color(0xFFDB2777) : AppColors.indigo,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.sticky_note_2_rounded, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.t('studentNotes'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  PointsBadge(points: s.points),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                child: TextField(
                  controller: _ctrl,
                  autofocus: s.note.isEmpty,
                  expands: true,
                  minLines: null,
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  inputFormatters: const [WesternDigitsFormatter()],
                  style: const TextStyle(fontSize: 18, height: 1.6),
                  decoration: fieldDecoration(null, hint: context.t('studentNoteHint')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'database_helper.dart';
import 'strings.dart';
import 'widgets.dart';

/// "Tirage au sort": names flash by faster, then slow down and stop on the winner.
/// Returns the chosen [Student] when the teacher taps OK (or null if dismissed).
class RandomPickerDialog extends StatefulWidget {
  final List<Student> students;
  const RandomPickerDialog({super.key, required this.students});

  @override
  State<RandomPickerDialog> createState() => _RandomPickerDialogState();
}

class _RandomPickerDialogState extends State<RandomPickerDialog> {
  final _rng = Random();
  String _display = '?';
  Student? _chosen;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _spin());
  }

  Future<void> _spin() async {
    final students = widget.students;
    if (students.isEmpty) return;
    setState(() => _done = false);

    final steps = 24 + _rng.nextInt(8);
    var lastIndex = -1;
    for (var i = 0; i < steps; i++) {
      int next;
      do {
        next = _rng.nextInt(students.length);
      } while (students.length > 1 && next == lastIndex);
      lastIndex = next;
      if (!mounted) return;
      setState(() {
        _display = students[next].name;
        _chosen = students[next];
      });
      HapticFeedback.selectionClick();
      // Delay grows each step => the "wheel" slows down.
      await Future.delayed(Duration(milliseconds: 45 + (i * i * 0.4).round()));
    }
    if (!mounted) return;
    setState(() => _done = true);
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.indigo, Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _done ? Icons.celebration_rounded : Icons.casino_rounded,
              color: AppColors.amber,
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              context.t(_done ? 'pickStudent' : 'picking'),
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
              decoration: BoxDecoration(
                color: _done ? AppColors.amber : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                child: Text(
                  _display,
                  key: ValueKey(_display),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _done ? 38 : 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white38,
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _done ? _spin : null,
                    child: Text(context.t('drawAgain')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _done ? () => Navigator.pop(context, _chosen) : null,
                    child: Text(context.t('ok')),
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

/// Fair random draw among [students]: nobody is drawn twice until everyone has had a turn.
/// The winner becomes the selected student.
Future<void> drawRandomStudent(BuildContext context, List<Student> students) async {
  if (students.isEmpty) {
    showSnack(context, context.t('noStudents'));
    return;
  }
  var pool = students.where((s) => !AppState.drawnIds.contains(s.id)).toList();
  if (pool.isEmpty) {
    // Everybody has already been drawn: start a new round.
    for (final s in students) {
      if (s.id != null) AppState.drawnIds.remove(s.id);
    }
    pool = List<Student>.of(students);
    showSnack(context, context.t('newDrawRound'));
  }
  final picked = await showDialog<Student>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RandomPickerDialog(students: pool),
  );
  if (picked == null) return;
  if (picked.id != null) AppState.drawnIds.add(picked.id!);
  await AppState.chooseStudent(picked);
  if (context.mounted) {
    final done = students.where((s) => AppState.drawnIds.contains(s.id)).length;
    showSnack(context, '${context.t('drawProgress')}: $done / ${students.length}');
  }
}

/// Bottom sheet to select the student manually (list with points), draw one at random,
/// or clear the selection. The choice is stored in [AppState.selectedStudent].
Future<void> showStudentChooser(BuildContext context, int classId) async {
  final students = await DatabaseHelper.instance.getStudents(classId);
  if (!context.mounted) return;
  if (students.isEmpty) {
    showSnack(context, context.t('noStudents'));
    return;
  }

  final choice = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheet) {
      final selectedId = AppState.selectedStudent.value?.id;
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  sheet.t('chooseStudent'),
                  style: Theme.of(sheet).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.casino_rounded, color: AppColors.amber),
                title: Text(sheet.t('randomStudent'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(sheet, 'random'),
              ),
              if (selectedId != null)
                ListTile(
                  leading: const Icon(Icons.person_off_outlined, color: AppColors.danger),
                  title: Text(sheet.t('clearSelection')),
                  onTap: () => Navigator.pop(sheet, 'clear'),
                ),
              const Divider(height: 1),
              for (var i = 0; i < students.length; i++)
                ListTile(
                  selected: students[i].id == selectedId,
                  selectedTileColor: AppColors.indigo.withValues(alpha: 0.08),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.indigo, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(students[i].name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  trailing: PointsBadge(points: students[i].points),
                  onTap: () => Navigator.pop(sheet, students[i]),
                ),
            ],
          ),
        ),
      );
    },
  );

  if (!context.mounted || choice == null) return;
  if (choice == 'clear') {
    await AppState.selectStudent(null);
  } else if (choice == 'random') {
    await drawRandomStudent(context, students);
  } else if (choice is Student) {
    await AppState.chooseStudent(choice);
  }
}

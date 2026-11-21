import 'package:flutter/material.dart';
import 'database_helper.dart';

/// Tiny global state: language, active class and currently selected student.
/// Everything is saved in the local database so it survives app restarts.
class AppState {
  static final ValueNotifier<Locale> locale = ValueNotifier(const Locale('ar'));
  static final ValueNotifier<int?> activeClassId = ValueNotifier(null);

  /// The student who answers the questions (picked manually or by the random draw).
  /// Always belongs to the active class. Its `points` field is kept up to date.
  static final ValueNotifier<Student?> selectedStudent = ValueNotifier(null);

  /// Incremented when ALL data changes at once (restore, erase after a forgotten PIN):
  /// the home shell then rebuilds every screen from the database.
  static final ValueNotifier<int> dataEpoch = ValueNotifier<int>(0);

  /// Seconds allowed per question (0 = no timer). Saved in the database.
  static final ValueNotifier<int> timerSeconds = ValueNotifier(0);

  /// Success chime + spoken praise on/off. Saved in the database.
  static final ValueNotifier<bool> soundOn = ValueNotifier(true);

  /// Students already drawn in the current round: nobody is drawn twice
  /// until every student of the class has had a turn (fair draw).
  static final Set<int> drawnIds = <int>{};

  static Future<void> load() async {
    final db = DatabaseHelper.instance;
    locale.value = Locale(await db.getSetting('lang') ?? 'ar');
    activeClassId.value = int.tryParse(await db.getSetting('activeClass') ?? '');

    timerSeconds.value = int.tryParse(await db.getSetting('timer') ?? '') ?? 0;
    soundOn.value = (await db.getSetting('sound')) != '0';

    final studentId = int.tryParse(await db.getSetting('selectedStudent') ?? '');
    if (studentId != null) {
      final s = await db.getStudent(studentId);
      if (s != null && s.classId == activeClassId.value) selectedStudent.value = s;
    }
  }

  static Future<void> setLocale(String code) async {
    locale.value = Locale(code);
    await DatabaseHelper.instance.setSetting('lang', code);
  }

  static Future<void> setTimer(int seconds) async {
    timerSeconds.value = seconds;
    await DatabaseHelper.instance.setSetting('timer', '$seconds');
  }

  static Future<void> setSound(bool on) async {
    soundOn.value = on;
    await DatabaseHelper.instance.setSetting('sound', on ? '1' : '0');
  }

  static Future<void> setActiveClass(int? id) async {
    // A selected student must belong to the active class.
    final current = selectedStudent.value;
    if (current != null && current.classId != id) await selectStudent(null);
    activeClassId.value = id;
    await DatabaseHelper.instance.setSetting('activeClass', id?.toString() ?? '');
  }

  static Future<void> selectStudent(Student? s) async {
    selectedStudent.value = s;
    await DatabaseHelper.instance.setSetting('selectedStudent', s?.id?.toString() ?? '');
  }

  /// Selects [s] and makes sure its class is the active one.
  static Future<void> chooseStudent(Student s) async {
    if (activeClassId.value != s.classId) await setActiveClass(s.classId);
    await selectStudent(s);
  }

  /// Reloads the selected student from the database (after a rename or a points reset).
  static Future<void> refreshSelected() async {
    final current = selectedStudent.value;
    if (current?.id == null) return;
    final fresh = await DatabaseHelper.instance.getStudent(current!.id!);
    if (fresh == null) {
      await selectStudent(null);
    } else {
      selectedStudent.value = fresh;
    }
  }
}

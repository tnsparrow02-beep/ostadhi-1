import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'digits.dart';

/// yyyy-MM-dd with Latin digits (safe to use as a database key in any locale).
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

// ───────────────────────── Models ─────────────────────────

class Question {
  final int? id;
  final String text;
  final String correct;
  final String wrong1;
  final String wrong2;

  const Question({
    this.id,
    required this.text,
    required this.correct,
    required this.wrong1,
    required this.wrong2,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'text': text,
        'correct': correct,
        'wrong1': wrong1,
        'wrong2': wrong2,
      };

  factory Question.fromMap(Map<String, Object?> m) => Question(
        id: m['id'] as int,
        text: westernDigits(m['text'] as String),
        correct: westernDigits(m['correct'] as String),
        wrong1: westernDigits(m['wrong1'] as String),
        wrong2: westernDigits(m['wrong2'] as String),
      );
}

class SchoolClass {
  final int? id;
  final String name;
  const SchoolClass({this.id, required this.name});

  factory SchoolClass.fromMap(Map<String, Object?> m) =>
      SchoolClass(id: m['id'] as int, name: westernDigits(m['name'] as String));
}

/// Gender codes stored in the database (students.gender).
const String kMale = 'm';
const String kFemale = 'f';

class Student {
  final int? id;
  final int classId;
  final String name;

  /// Persistent score: +1 for each correct answer given while selected.
  final int points;

  /// [kMale] or [kFemale]. Used for the Arabic praise: أَحْسَنْتَ / أَحْسَنْتِ.
  final String gender;

  /// Private observations about this student (written from the students list).
  final String note;

  /// Photo of the student: an http(s) URL or a path inside the app's private storage.
  /// Empty = no photo. It is hidden by default and shown only when the name is tapped.
  final String photo;

  const Student({
    this.id,
    required this.classId,
    required this.name,
    this.points = 0,
    this.gender = kMale,
    this.note = '',
    this.photo = '',
  });

  bool get isFemale => gender == kFemale;

  Student copyWith({String? name, int? points, String? gender, String? note, String? photo}) => Student(
        id: id,
        classId: classId,
        name: name ?? this.name,
        points: points ?? this.points,
        gender: gender ?? this.gender,
        note: note ?? this.note,
        photo: photo ?? this.photo,
      );

  factory Student.fromMap(Map<String, Object?> m) => Student(
        id: m['id'] as int,
        classId: m['class_id'] as int,
        name: westernDigits(m['name'] as String),
        points: (m['points'] as int?) ?? 0,
        gender: m['gender'] == kFemale ? kFemale : kMale,
        note: (m['note'] as String?) ?? '',
        photo: (m['photo'] as String?) ?? '',
      );
}

/// A file stored in "My library" (PDF, Word or image) for one academic year and one folder.
class LibraryFile {
  final int? id;
  final String year; // e.g. 2026/2027
  final String folder; // general, ctrl1..ctrl6, synth1..synth3
  final String name;
  final String path; // inside the app's private storage
  final String kind; // pdf, word or image
  final int size;
  final String added; // ISO date-time

  const LibraryFile({
    this.id,
    required this.year,
    required this.folder,
    required this.name,
    required this.path,
    required this.kind,
    required this.size,
    required this.added,
  });

  factory LibraryFile.fromMap(Map<String, Object?> m) => LibraryFile(
        id: m['id'] as int,
        year: m['year'] as String,
        folder: m['folder'] as String,
        name: m['name'] as String,
        path: m['path'] as String,
        kind: m['kind'] as String,
        size: (m['size'] as int?) ?? 0,
        added: (m['added'] as String?) ?? '',
      );
}

/// A folder or a file of the notebook ("دفتر الأستاذ": فروض المراقبة / الفروض التأليفية / الدروس).
class NbNode {
  final int id;
  final String section; // control, synthesis, lessons
  final int? parentId; // null = directly inside the section
  final bool isFolder;
  final String name;
  final String path; // file location inside the app's private storage ('' for folders)
  final String ext; // lowercase, without dot
  final int size;
  final String added; // ISO date-time

  const NbNode({
    required this.id,
    required this.section,
    required this.parentId,
    required this.isFolder,
    required this.name,
    required this.path,
    required this.ext,
    required this.size,
    required this.added,
  });

  factory NbNode.fromMap(Map<String, Object?> m) => NbNode(
        id: m['id'] as int,
        section: m['section'] as String,
        parentId: m['parent_id'] as int?,
        isFolder: (m['is_folder'] as int) == 1,
        name: m['name'] as String,
        path: (m['path'] as String?) ?? '',
        ext: (m['ext'] as String?) ?? '',
        size: (m['size'] as int?) ?? 0,
        added: (m['added'] as String?) ?? '',
      );
}

class SectionStats {
  final int folders;
  final int files;
  const SectionStats(this.folders, this.files);
}

class TimetableEntry {
  final int day; // 1 = Monday ... 6 = Saturday
  final int slot; // 0-based period index
  final int classId;
  final String className;
  final String room;

  /// School year of this entry, e.g. "2026/2027" (column annee_scolaire).
  final String anneeScolaire;

  /// Subject taught during this period, e.g. "Algèbre" or "Géométrie" (column matiere).
  final String matiere;

  const TimetableEntry({
    required this.day,
    required this.slot,
    required this.classId,
    required this.className,
    required this.room,
    this.anneeScolaire = '',
    this.matiere = '',
  });

  factory TimetableEntry.fromMap(Map<String, Object?> m) => TimetableEntry(
        day: m['day'] as int,
        slot: m['slot'] as int,
        classId: m['class_id'] as int,
        className: m['class_name'] as String,
        room: westernDigits((m['room'] as String?) ?? ''),
        anneeScolaire: (m['annee_scolaire'] as String?) ?? '',
        matiere: (m['matiere'] as String?) ?? '',
      );
}

/// School year that contains [now]: September–December => "2026/2027", January–August => "2025/2026".
String defaultSchoolYear([DateTime? now]) {
  final d = now ?? DateTime.now();
  final start = d.month >= 9 ? d.year : d.year - 1;
  return '$start/${start + 1}';
}

// ───────────────────────── Database ─────────────────────────

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Future<Database>? _dbFuture;

  /// The open call is cached as a Future so concurrent first calls never open the file twice.
  Future<Database> get database => _dbFuture ??= _open();

  Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), 'math_teacher.db');
    return openDatabase(
      path,
      version: 7,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            correct TEXT NOT NULL,
            wrong1 TEXT NOT NULL,
            wrong2 TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE classes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE students(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
            name TEXT NOT NULL,
            points INTEGER NOT NULL DEFAULT 0,
            gender TEXT NOT NULL DEFAULT 'm',
            note TEXT NOT NULL DEFAULT '',
            photo TEXT NOT NULL DEFAULT ''
          )''');
        await db.execute('''
          CREATE TABLE timetable(
            annee_scolaire TEXT NOT NULL,
            day INTEGER NOT NULL,
            slot INTEGER NOT NULL,
            class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
            room TEXT NOT NULL DEFAULT '',
            matiere TEXT NOT NULL DEFAULT '',
            PRIMARY KEY(annee_scolaire, day, slot)
          )''');
        await db.execute('''
          CREATE TABLE notes(
            date TEXT PRIMARY KEY,
            content TEXT NOT NULL
          )''');
        await db.execute('''
          CREATE TABLE settings(
            k TEXT PRIMARY KEY,
            v TEXT
          )''');
        await _createLibraryTables(db);
        await _createNotebookTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE students ADD COLUMN points INTEGER NOT NULL DEFAULT 0');
        }
        if (oldVersion < 3) {
          // Existing students default to male; edit a student to change it.
          await db.execute("ALTER TABLE students ADD COLUMN gender TEXT NOT NULL DEFAULT 'm'");
        }
        if (oldVersion < 4) {
          await db.execute("ALTER TABLE students ADD COLUMN note TEXT NOT NULL DEFAULT ''");
          await _createLibraryTables(db);
        }
        if (oldVersion < 5) {
          await _createNotebookTables(db);
        }
        if (oldVersion < 6) {
          await _migrateLibraryYears(db);
        }
        if (oldVersion < 7) {
          // Student photo + timetable linked to the school year, with a subject per period.
          await db.execute("ALTER TABLE students ADD COLUMN photo TEXT NOT NULL DEFAULT ''");
          await db.execute('''
            CREATE TABLE timetable_v7(
              annee_scolaire TEXT NOT NULL,
              day INTEGER NOT NULL,
              slot INTEGER NOT NULL,
              class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
              room TEXT NOT NULL DEFAULT '',
              matiere TEXT NOT NULL DEFAULT '',
              PRIMARY KEY(annee_scolaire, day, slot)
            )''');
          // Existing periods belong to the current school year.
          await db.rawInsert(
            'INSERT INTO timetable_v7(annee_scolaire, day, slot, class_id, room) '
            'SELECT ?, day, slot, class_id, room FROM timetable',
            [defaultSchoolYear()],
          );
          await db.execute('DROP TABLE timetable');
          await db.execute('ALTER TABLE timetable_v7 RENAME TO timetable');
        }
      },
    );
  }

  // ── Questions ──
  /// [newestFirst] = true for the question bank list, false (creation order) for the quiz.
  Future<List<Question>> getQuestions({bool newestFirst = true}) async {
    final db = await database;
    final rows = await db.query('questions', orderBy: newestFirst ? 'id DESC' : 'id ASC');
    return rows.map(Question.fromMap).toList();
  }

  Future<int> countQuestions() async {
    final db = await database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM questions')) ?? 0;
  }

  Future<void> insertQuestion(Question q) async {
    final db = await database;
    final map = q.toMap()..remove('id');
    await db.insert('questions', map);
  }

  Future<void> updateQuestion(Question q) async {
    final db = await database;
    await db.update('questions', q.toMap(), where: 'id = ?', whereArgs: [q.id]);
  }

  Future<void> deleteQuestion(int id) async {
    final db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Classes ──
  Future<List<SchoolClass>> getClasses() async {
    final db = await database;
    final rows = await db.query('classes', orderBy: 'id ASC');
    return rows.map(SchoolClass.fromMap).toList();
  }

  Future<int> insertClass(String name) async {
    final db = await database;
    return db.insert('classes', {'name': name});
  }

  Future<void> renameClass(int id, String name) async {
    final db = await database;
    await db.update('classes', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  /// Also removes the class students and its timetable slots (ON DELETE CASCADE).
  Future<void> deleteClass(int id) async {
    final db = await database;
    await db.delete('classes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<int, int>> getStudentCounts() async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT class_id, COUNT(*) AS c FROM students GROUP BY class_id');
    return {for (final r in rows) r['class_id'] as int: r['c'] as int};
  }

  // ── Students ──
  Future<List<Student>> getStudents(int classId) async {
    final db = await database;
    final rows = await db.query('students',
        where: 'class_id = ?', whereArgs: [classId], orderBy: 'id ASC');
    return rows.map(Student.fromMap).toList();
  }

  Future<Student?> getStudent(int id) async {
    final db = await database;
    final rows = await db.query('students', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Student.fromMap(rows.first);
  }

  /// Adds one point to the student and returns the new total.
  Future<int> addPoint(int studentId) async {
    final db = await database;
    await db.rawUpdate('UPDATE students SET points = points + 1 WHERE id = ?', [studentId]);
    final rows = await db.query('students',
        columns: ['points'], where: 'id = ?', whereArgs: [studentId], limit: 1);
    return rows.isEmpty ? 0 : (rows.first['points'] as int?) ?? 0;
  }

  Future<void> resetPoints(int classId) async {
    final db = await database;
    await db.update('students', {'points': 0}, where: 'class_id = ?', whereArgs: [classId]);
  }

  /// All [names] get the same [gender] (add boys and girls in two batches).
  Future<void> insertStudents(int classId, List<String> names, {String gender = kMale}) async {
    final db = await database;
    final batch = db.batch();
    for (final n in names) {
      batch.insert('students', {'class_id': classId, 'name': n, 'gender': gender});
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateStudentNote(int id, String note) async {
    final db = await database;
    await db.update('students', {'note': westernDigits(note)}, where: 'id = ?', whereArgs: [id]);
  }

  /// [photo]: null keeps the current photo, '' removes it, otherwise URL / private file path.
  Future<void> updateStudent(int id, String name, String gender, {String? photo}) async {
    final db = await database;
    await db.update(
      'students',
      {'name': name, 'gender': gender, if (photo != null) 'photo': photo.trim()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteStudent(int id) async {
    final db = await database;
    await db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // ── School year (annee_scolaire) ──
  /// The current school year, e.g. "2026/2027". Automatic (September–August) until you edit it.
  Future<String> getSchoolYear() async {
    final saved = (await getSetting('school_year'))?.trim() ?? '';
    return saved.isEmpty ? defaultSchoolYear() : saved;
  }

  Future<void> setSchoolYear(String year) => setSetting('school_year', westernDigits(year.trim()));

  // ── Timetable (one timetable per school year) ──
  /// Periods of the current school year only.
  Future<List<TimetableEntry>> getTimetable() async {
    final db = await database;
    final year = await getSchoolYear();
    final rows = await db.rawQuery('''
      SELECT t.annee_scolaire, t.day, t.slot, t.class_id, t.room, t.matiere, c.name AS class_name
      FROM timetable t JOIN classes c ON c.id = t.class_id
      WHERE t.annee_scolaire = ?
    ''', [year]);
    return rows.map(TimetableEntry.fromMap).toList();
  }

  Future<void> setTimetableSlot(int day, int slot, int classId, String room,
      {String matiere = ''}) async {
    final db = await database;
    await db.insert(
      'timetable',
      {
        'annee_scolaire': await getSchoolYear(),
        'day': day,
        'slot': slot,
        'class_id': classId,
        'room': room,
        'matiere': matiere,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearTimetableSlot(int day, int slot) async {
    final db = await database;
    await db.delete(
      'timetable',
      where: 'annee_scolaire = ? AND day = ? AND slot = ?',
      whereArgs: [await getSchoolYear(), day, slot],
    );
  }

  // ── Daily notes ──
  Future<String> getNote(String date) async {
    final db = await database;
    final rows = await db.query('notes', where: 'date = ?', whereArgs: [date]);
    return rows.isEmpty ? '' : westernDigits(rows.first['content'] as String);
  }

  Future<Map<String, String>> getAllNotes() async {
    final db = await database;
    final rows = await db.query('notes');
    return {for (final r in rows) r['date'] as String: westernDigits(r['content'] as String)};
  }

  /// An empty note removes the row, so the calendar marker disappears.
  Future<void> saveNote(String date, String content) async {
    final db = await database;
    if (content.trim().isEmpty) {
      await db.delete('notes', where: 'date = ?', whereArgs: [date]);
    } else {
      await db.insert('notes', {'date': date, 'content': content},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // ── Settings (language, active class) ──
  // ── Library (academic years, folders, files) ──
  Future<List<String>> getLibraryYears() async {
    final db = await database;
    final rows = await db.query('library_years', orderBy: 'year DESC');
    return rows.map((r) => r['year'] as String).toList();
  }

  Future<void> addLibraryYear(String year) async {
    final db = await database;
    await db.insert('library_years', {'year': year}, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Removes the year and its file records. Returns the file paths so the caller can delete them from the disk.
  Future<List<String>> deleteLibraryYear(String year) async {
    final db = await database;
    final rows = await db.query('library_files',
        columns: ['path'], where: 'year = ?', whereArgs: [year]);
    await db.delete('library_files', where: 'year = ?', whereArgs: [year]);
    await db.delete('library_years', where: 'year = ?', whereArgs: [year]);
    return rows.map((r) => r['path'] as String).toList();
  }

  Future<Map<String, int>> getLibraryYearCounts() async {
    final db = await database;
    final rows =
        await db.rawQuery('SELECT year, COUNT(*) AS c FROM library_files GROUP BY year');
    return {for (final r in rows) r['year'] as String: r['c'] as int};
  }

  Future<Map<String, int>> getLibraryFolderCounts(String year) async {
    final db = await database;
    final rows = await db.rawQuery(
        'SELECT folder, COUNT(*) AS c FROM library_files WHERE year = ? GROUP BY folder', [year]);
    return {for (final r in rows) r['folder'] as String: r['c'] as int};
  }

  Future<List<LibraryFile>> getLibraryFiles(String year, String folder) async {
    final db = await database;
    final rows = await db.query('library_files',
        where: 'year = ? AND folder = ?', whereArgs: [year, folder], orderBy: 'id DESC');
    return rows.map(LibraryFile.fromMap).toList();
  }

  Future<void> insertLibraryFile({
    required String year,
    required String folder,
    required String name,
    required String path,
    required String kind,
    required int size,
  }) async {
    final db = await database;
    await db.insert('library_files', {
      'year': year,
      'folder': folder,
      'name': name,
      'path': path,
      'kind': kind,
      'size': size,
      'added': DateTime.now().toIso8601String(),
    });
  }

  Future<void> deleteLibraryFile(int id) async {
    final db = await database;
    await db.delete('library_files', where: 'id = ?', whereArgs: [id]);
  }

  // ── Notebook: sections, folders, files ──
  /// Folders first, then files, both sorted by name.
  Future<List<NbNode>> nbChildren(String section, int? parentId) async {
    final db = await database;
    final rows = await db.query(
      'nodes',
      where: parentId == null ? 'section = ? AND parent_id IS NULL' : 'section = ? AND parent_id = ?',
      whereArgs: parentId == null ? <Object?>[section] : <Object?>[section, parentId],
      orderBy: 'is_folder DESC, name COLLATE NOCASE ASC',
    );
    return rows.map(NbNode.fromMap).toList();
  }

  /// Number of direct children of every folder of [section] (to show "5 items").
  Future<Map<int, int>> nbChildCounts(String section) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT parent_id, COUNT(*) AS c FROM nodes '
      'WHERE section = ? AND parent_id IS NOT NULL GROUP BY parent_id',
      [section],
    );
    return {for (final r in rows) r['parent_id'] as int: r['c'] as int};
  }

  Future<Map<String, SectionStats>> nbSectionStats() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT section,
             SUM(CASE WHEN is_folder = 1 THEN 1 ELSE 0 END) AS folders,
             SUM(CASE WHEN is_folder = 0 THEN 1 ELSE 0 END) AS files
      FROM nodes GROUP BY section''');
    return {
      for (final r in rows)
        r['section'] as String: SectionStats((r['folders'] as int?) ?? 0, (r['files'] as int?) ?? 0),
    };
  }

  Future<NbNode?> _nbNode(int id) async {
    final db = await database;
    final rows = await db.query('nodes', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : NbNode.fromMap(rows.first);
  }

  /// Folders from the top down to (and including) the folder [id].
  Future<List<NbNode>> nbPathTo(int id) async {
    final chain = <NbNode>[];
    int? current = id;
    var guard = 0;
    while (current != null && guard < 60) {
      final n = await _nbNode(current);
      if (n == null) break;
      chain.insert(0, n);
      current = n.parentId;
      guard++;
    }
    return chain;
  }

  Future<List<NbNode>> nbAllFolders() async {
    final db = await database;
    final rows = await db.query('nodes', where: 'is_folder = 1');
    return rows.map(NbNode.fromMap).toList();
  }

  /// Search by name in every section (folders and files).
  Future<List<NbNode>> nbSearch(String query) async {
    final q = westernDigits(query).trim();
    if (q.isEmpty) return <NbNode>[];
    final escaped = q.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    final db = await database;
    final rows = await db.query(
      'nodes',
      where: r"name LIKE ? ESCAPE '\'",
      whereArgs: ['%$escaped%'],
      orderBy: 'is_folder DESC, name COLLATE NOCASE ASC',
      limit: 150,
    );
    return rows.map(NbNode.fromMap).toList();
  }

  Future<int> nbInsertFolder(String section, int? parentId, String name) async {
    final db = await database;
    return db.insert('nodes', {
      'section': section,
      'parent_id': parentId,
      'is_folder': 1,
      'name': westernDigits(name),
      'added': DateTime.now().toIso8601String(),
    });
  }

  Future<int> nbInsertFile(
    String section,
    int? parentId, {
    required String name,
    required String path,
    required String ext,
    required int size,
  }) async {
    final db = await database;
    return db.insert('nodes', {
      'section': section,
      'parent_id': parentId,
      'is_folder': 0,
      'name': westernDigits(name),
      'path': path,
      'ext': ext,
      'size': size,
      'added': DateTime.now().toIso8601String(),
    });
  }

  Future<void> nbRename(int id, String name) async {
    final db = await database;
    await db.update('nodes', {'name': westernDigits(name)}, where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes the item (and everything inside a folder).
  /// Returns the paths of the deleted files so the caller can remove them from the phone.
  Future<List<String>> nbDelete(int id) async {
    final db = await database;
    final rows = await db.rawQuery('''
      WITH RECURSIVE sub(id) AS (
        SELECT id FROM nodes WHERE id = ?
        UNION ALL
        SELECT n.id FROM nodes n JOIN sub ON n.parent_id = sub.id
      )
      SELECT path FROM nodes
      WHERE id IN (SELECT id FROM sub) AND is_folder = 0 AND path != ''
    ''', [id]);
    await db.delete('nodes', where: 'id = ?', whereArgs: [id]); // children: ON DELETE CASCADE
    return rows.map((r) => r['path'] as String).toList();
  }

  /// Forgot-PIN reset: erases EVERYTHING (classes, students, questions, notes, timetable,
  /// library, notebook, PIN). Returns the file paths so the caller can delete them from the phone.
  Future<List<String>> wipeAllData() async {
    final db = await database;
    final paths = <String>[];
    for (final r in await db.query('nodes', columns: ['path'], where: "is_folder = 0 AND path != ''")) {
      paths.add(r['path'] as String);
    }
    for (final r in await db.query('library_files', columns: ['path'])) {
      paths.add(r['path'] as String);
    }
    await db.transaction((txn) async {
      for (final table in [
        'timetable',
        'students',
        'notes',
        'questions',
        'classes',
        'library_files',
        'library_years',
        'nodes',
      ]) {
        await txn.delete(table);
      }
      await txn.delete('settings', where: "k LIKE 'pin_%' OR k IN ('activeClass', 'selectedStudent')");
    });
    return paths;
  }

  // ── Backup / restore (copy-paste text, works offline) ──
  Future<String> exportJson() async {
    final db = await database;
    return jsonEncode(<String, Object?>{
      'app': 'math_teacher',
      'version': 1,
      'classes': await db.query('classes'),
      'questions': await db.query('questions'),
      'students': await db.query('students'),
      'timetable': await db.query('timetable'),
      'notes': await db.query('notes'),
      'school_year': await getSchoolYear(),
    });
  }

  /// True if [text] is a backup produced by [exportJson].
  static bool looksLikeBackup(String text) {
    try {
      final decoded = jsonDecode(text);
      return decoded is Map && decoded['app'] == 'math_teacher';
    } catch (_) {
      return false;
    }
  }

  /// Replaces ALL data (classes, students, points, questions, timetable, notes)
  /// with the backup. Everything happens in one transaction: it works completely or not at all.
  Future<void> importJson(String text) async {
    final decoded = jsonDecode(text);
    if (decoded is! Map || decoded['app'] != 'math_teacher') {
      throw const FormatException('Not a Math Teacher backup');
    }
    List<Map<String, Object?>> rows(String key) {
      final raw = decoded[key];
      if (raw is! List) return <Map<String, Object?>>[];
      return [for (final r in raw) Map<String, Object?>.from(r as Map)];
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('timetable');
      await txn.delete('students');
      await txn.delete('notes');
      await txn.delete('questions');
      await txn.delete('classes');
      final batch = txn.batch();
      for (final r in rows('classes')) {
        batch.insert('classes', r);
      }
      for (final r in rows('questions')) {
        batch.insert('questions', r);
      }
      for (final r in rows('students')) {
        batch.insert('students', r);
      }
      final backupYear = decoded['school_year'];
      final year = backupYear is String && backupYear.isNotEmpty ? backupYear : defaultSchoolYear();
      for (final r in rows('timetable')) {
        // Old backups have no school year: their periods go to the backup's / current year.
        final y = r['annee_scolaire'];
        if (y is! String || y.isEmpty) r['annee_scolaire'] = year;
        batch.insert('timetable', r);
      }
      for (final r in rows('notes')) {
        batch.insert('notes', r);
      }
      await batch.commit(noResult: true);
      await txn.insert('settings', {'k': 'school_year', 'v': year},
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'k = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.first['v'] as String?;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert('settings', {'k': key, 'v': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

/// Library tables (created on a fresh install and on upgrade to version 4).
Future<void> _createLibraryTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS library_years(
      year TEXT PRIMARY KEY
    )''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS library_files(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year TEXT NOT NULL,
      folder TEXT NOT NULL,
      name TEXT NOT NULL,
      path TEXT NOT NULL,
      kind TEXT NOT NULL,
      size INTEGER NOT NULL DEFAULT 0,
      added TEXT NOT NULL
    )''');
}

/// Notebook tables (created on a fresh install and on upgrade to version 5).
Future<void> _createNotebookTables(Database db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS nodes(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      section TEXT NOT NULL,
      parent_id INTEGER REFERENCES nodes(id) ON DELETE CASCADE,
      is_folder INTEGER NOT NULL DEFAULT 0,
      name TEXT NOT NULL,
      path TEXT NOT NULL DEFAULT '',
      ext TEXT NOT NULL DEFAULT '',
      size INTEGER NOT NULL DEFAULT 0,
      added TEXT NOT NULL
    )''');
  await db.execute('CREATE INDEX IF NOT EXISTS idx_nodes_parent ON nodes(section, parent_id)');
}

String _legacyFolderName(String key) {
  if (key.startsWith('ctrl')) return 'فرض مراقبة عدد ${key.substring(4)}';
  if (key.startsWith('synth')) return 'فرض تأليفي عدد ${key.substring(5)}';
  return key;
}

/// Version 6: the "academic year" library is replaced by ordinary folders ("مجلداتي").
/// Every year that already holds files becomes a normal folder, so no file is lost.
Future<void> _migrateLibraryYears(Database db) async {
  final years = await db.rawQuery('SELECT DISTINCT year FROM library_files');
  final now = DateTime.now().toIso8601String();
  for (final row in years) {
    final year = row['year'] as String;
    final yearId = await db.insert('nodes', {
      'section': 'library',
      'parent_id': null,
      'is_folder': 1,
      'name': year,
      'added': now,
    });
    final files = await db.query('library_files', where: 'year = ?', whereArgs: [year], orderBy: 'id ASC');
    final subFolders = <String, int>{};
    for (final f in files) {
      final key = f['folder'] as String;
      var parentId = yearId;
      if (key != 'general') {
        final existing = subFolders[key];
        if (existing != null) {
          parentId = existing;
        } else {
          parentId = await db.insert('nodes', {
            'section': 'library',
            'parent_id': yearId,
            'is_folder': 1,
            'name': _legacyFolderName(key),
            'added': now,
          });
          subFolders[key] = parentId;
        }
      }
      final name = f['name'] as String;
      final dot = name.lastIndexOf('.');
      await db.insert('nodes', {
        'section': 'library',
        'parent_id': parentId,
        'is_folder': 0,
        'name': name,
        'path': f['path'],
        'ext': dot >= 0 ? name.substring(dot + 1).toLowerCase() : '',
        'size': f['size'] ?? 0,
        'added': (f['added'] as String?) ?? now,
      });
    }
  }
}

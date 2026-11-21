import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'database_helper.dart';
import 'digits.dart';
import 'strings.dart';
import 'widgets.dart';

/// Monthly calendar. A green dot marks days that already have notes.
/// Tapping a day opens that day's notebook.
class CalendarNotesScreen extends StatefulWidget {
  const CalendarNotesScreen({super.key});

  @override
  State<CalendarNotesScreen> createState() => _CalendarNotesScreenState();
}

class _CalendarNotesScreenState extends State<CalendarNotesScreen> {
  final _db = DatabaseHelper.instance;
  DateTime _focused = DateTime.now();
  DateTime? _selected;
  Map<String, String> _notes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await _db.getAllNotes();
    if (!mounted) return;
    setState(() => _notes = notes);
  }

  Future<void> _open(DateTime day) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NoteEditorScreen(date: day)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final recentKeys = _notes.keys.toList()..sort((a, b) => b.compareTo(a));
    final lang = context.lang;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
          child: TableCalendar<int>(
            locale: lang,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (d) => _selected != null && isSameDay(d, _selected),
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            daysOfWeekHeight: 30,
            rowHeight: 50,
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextFormatter: (date, locale) => formatMonthYear(date, '$locale'),
              titleTextStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: AppColors.indigo),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: AppColors.indigo),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
              selectedDecoration: const BoxDecoration(
                color: AppColors.indigo,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppColors.emerald,
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerSize: 7,
              markersAnchor: 0.9,
            ),
            eventLoader: (d) => _notes.containsKey(dateKey(d)) ? const [1] : const [],
            onPageChanged: (d) => _focused = d,
            onDaySelected: (selected, focused) {
              setState(() {
                _selected = selected;
                _focused = focused;
              });
              _open(selected);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Text(
            context.t('notebookHint'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
        if (recentKeys.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.t('recentNotes'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final key in recentKeys.take(8))
            SoftCard(
              onTap: () => _open(DateTime.parse(key)),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.emerald.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.emerald),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatFullDate(DateTime.parse(key), lang),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _notes[key]!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

/// Daily Teacher Notebook: free-text notes for one date (lesson progress, reminders,
/// student remarks). Saved automatically when you leave the page.
class NoteEditorScreen extends StatefulWidget {
  final DateTime date;
  const NoteEditorScreen({super.key, required this.date});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _db = DatabaseHelper.instance;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<TimetableEntry> _dayClasses = [];
  String _initial = '';
  bool _loaded = false;

  String get _key => dateKey(widget.date);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final text = await _db.getNote(_key);
    final all = await _db.getTimetable();
    final today = all.where((e) => e.day == widget.date.weekday).toList()
      ..sort((a, b) => a.slot.compareTo(b.slot));
    if (!mounted) return;
    setState(() {
      _ctrl.text = text;
      _initial = text;
      _dayClasses = today;
      _loaded = true;
    });
  }

  Future<void> _save({bool silent = false}) async {
    await _db.saveNote(_key, _ctrl.text);
    _initial = _ctrl.text;
    if (!silent && mounted) showSnack(context, context.t('saved'));
  }

  Future<void> _delete() async {
    if (!await confirmDelete(context)) return;
    await _db.saveNote(_key, '');
    _initial = '';
    if (mounted) Navigator.pop(context);
  }

  /// Adds a heading such as "Lesson progress: " on a new line at the end of the note.
  void _addSection(String label) {
    final t = _ctrl.text;
    final prefix = t.isEmpty || t.endsWith('\n') ? '' : '\n';
    _ctrl.text = '$t$prefix$label: ';
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        // Auto-save when leaving the page (only if something changed).
        if (didPop && _loaded && _ctrl.text != _initial) {
          _db.saveNote(_key, _ctrl.text);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            formatFullDate(widget.date, lang),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: context.t('delete'),
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _save,
          icon: const Icon(Icons.save_rounded),
          label: Text(context.t('save')),
        ),
        body: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Classes scheduled that day (from the timetable)
                  if (_dayClasses.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('${context.t('classesThatDay')}:',
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            for (final g in _groupedClasses(_dayClasses))
                              Chip(
                                visualDensity: VisualDensity.compact,
                                label: Text(g.label),
                                backgroundColor:
                                    kClassColors[g.classId % kClassColors.length].withValues(alpha: 0.15),
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                      ),
                    ),
                  // Quick section buttons
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        for (final k in const ['lessonProgress', 'reminder', 'studentRemark'])
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ActionChip(
                              avatar: const Icon(Icons.add_rounded, size: 18),
                              label: Text(context.t(k)),
                              onPressed: () => _addSection(context.t(k)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        expands: true,
                        minLines: null,
                        maxLines: null,
                        textAlignVertical: TextAlignVertical.top,
                        inputFormatters: const [WesternDigitsFormatter()],
                        style: const TextStyle(fontSize: 18, height: 1.6),
                        decoration: fieldDecoration(null, hint: context.t('writeNotes')),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Consecutive periods of the same class become one chip: "1–2 · 7ème B1".
List<({String label, int classId})> _groupedClasses(List<TimetableEntry> sorted) {
  final groups = <({String label, int classId})>[];
  var i = 0;
  while (i < sorted.length) {
    var j = i;
    while (j + 1 < sorted.length &&
        sorted[j + 1].classId == sorted[i].classId &&
        sorted[j + 1].slot == sorted[j].slot + 1) {
      j++;
    }
    final from = sorted[i].slot + 1;
    final to = sorted[j].slot + 1;
    groups.add((
      label: '${from == to ? '$from' : '$from–$to'} · ${sorted[i].className}',
      classId: sorted[i].classId,
    ));
    i = j + 1;
  }
  return groups;
}

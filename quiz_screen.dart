import 'package:flutter/material.dart';

import 'ai_tool_screen.dart';

import 'app_state.dart';
import 'database_helper.dart';
import 'presentation_screen.dart';
import 'question_bank_screen.dart';
import 'random_picker.dart';
import 'ranking_screen.dart';
import 'quiz_library_screens.dart';
import 'strings.dart';
import 'widgets.dart';

/// Home of the classroom quiz: start the quiz, manage questions, pick the active class,
/// draw a random student.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _db = DatabaseHelper.instance;
  List<SchoolClass> _classes = [];
  List<Student> _students = [];
  List<Question> _questions = []; // creation order (stable numbering for the selector)
  SchoolClass? _active;
  int? _selectedQuestionId; // null = random order
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    AppState.activeClassId.addListener(_load);
  }

  @override
  void dispose() {
    AppState.activeClassId.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final classes = await _db.getClasses();
    final questions = await _db.getQuestions(newestFirst: false);
    final id = AppState.activeClassId.value;
    SchoolClass? active;
    for (final c in classes) {
      if (c.id == id) active = c;
    }
    final students = active == null ? <Student>[] : await _db.getStudents(active.id!);
    if (!mounted) return;
    setState(() {
      _classes = classes;
      _questions = questions;
      // Forget the chosen question if it was deleted from the bank.
      if (!questions.any((q) => q.id == _selectedQuestionId)) _selectedQuestionId = null;
      _active = active;
      _students = students;
      _loading = false;
    });
  }

  Future<void> _startQuiz() async {
    if (_questions.isEmpty) {
      showSnack(context, context.t('noQuestions'));
      return;
    }
    final questions = List<Question>.of(_questions);
    var startIndex = 0;
    final selected = _selectedQuestionId;
    if (selected == null) {
      questions.shuffle();
    } else {
      // The chosen question comes first, the next ones follow the bank order.
      startIndex = questions.indexWhere((q) => q.id == selected);
      if (startIndex < 0) startIndex = 0;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PresentationScreen(questions: questions, initialIndex: startIndex),
      ),
    );
    _load();
  }

  Future<void> _openRanking() async {
    final active = _active;
    if (active == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RankingScreen(schoolClass: active)),
    );
  }

  Future<void> _openAiTool() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const AiToolScreen()));
    _load();
  }

  Future<void> _openBank() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionBankScreen()));
    _load();
  }

  Future<void> _pickStudent() async {
    if (_active == null) {
      showSnack(context, context.t('noClassSelected'));
      return;
    }
    await drawRandomStudent(context, _students);
  }

  Future<void> _openQuizLibrary() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizLibraryScreen()));
    _load();
  }

  Future<void> _chooseStudent() async {
    final active = _active;
    if (active == null) {
      showSnack(context, context.t('noClassSelected'));
      return;
    }
    await showStudentChooser(context, active.id!);
    if (mounted) _load();
  }

  void _chooseClass() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (_classes.isEmpty) {
          return SizedBox(
            height: 220,
            child: EmptyState(icon: Icons.groups_outlined, message: sheetContext.t('noClasses')),
          );
        }
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  sheetContext.t('chooseClass'),
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final c in _classes)
                ListTile(
                  leading: Icon(
                    c.id == _active?.id ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: AppColors.indigo,
                  ),
                  title: Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  onTap: () {
                    AppState.setActiveClass(c.id);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.indigo, Color(0xFF5B21B6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.functions_rounded, color: AppColors.amber, size: 34),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('quizHeadline'),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${_questions.length} ${context.t('questionsCount')}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  onPressed: _startQuiz,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text(context.t('startQuiz')),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Manual question selector
        SoftCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_list_numbered_rounded, color: AppColors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    context.t('pickQuestion'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    isExpanded: true,
                    value: _selectedQuestionId,
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      DropdownMenuItem<int?>(
                        value: null,
                        child: Text(context.t('autoOrder')),
                      ),
                      for (var i = 0; i < _questions.length; i++)
                        DropdownMenuItem<int?>(
                          value: _questions[i].id,
                          child: Text(
                            '${i + 1}. ${_questions[i].text}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedQuestionId = v),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Active class
        SoftCard(
          onTap: _chooseClass,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.groups_rounded, color: AppColors.emerald),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.t('activeClass'), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    Text(
                      _active?.name ?? context.t('noClassSelected'),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                    ),
                    if (_active != null)
                      Text(
                        '${_students.length} ${context.t('studentsCount')}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                  ],
                ),
              ),
              if (_active != null)
                IconButton(
                  tooltip: context.t('rankingOfClass'),
                  onPressed: _openRanking,
                  icon: const Icon(Icons.emoji_events_rounded, color: AppColors.amber, size: 28),
                ),
              const Icon(Icons.unfold_more_rounded, color: AppColors.indigo),
            ],
          ),
        ),

        // Two big action tiles
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.casino_rounded,
                label: context.t('randomStudent'),
                color: AppColors.amber,
                onTap: _pickStudent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.library_books_rounded,
                label: context.t('questionBank'),
                color: AppColors.indigo,
                onTap: _openBank,
              ),
            ),
          ],
        ),

        // Selected student: big name right under the two buttons
        if (_active != null)
          ValueListenableBuilder<Student?>(
            valueListenable: AppState.selectedStudent,
            builder: (context, student, _) =>
                _SelectedStudentCard(student: student, onTap: _chooseStudent),
          ),

        // Ready-made questions + smart text tool
        Row(
          children: [
            Expanded(
              child: _ActionTile(
                icon: Icons.auto_stories_rounded,
                label: context.t('quizLibrary'),
                color: AppColors.emerald,
                onTap: _openQuizLibrary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionTile(
                icon: Icons.auto_awesome_rounded,
                label: context.t('aiTool'),
                color: const Color(0xFF7C3AED),
                onTap: _openAiTool,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Large display of the selected student (name + total points). Tap to choose another one.
class _SelectedStudentCard extends StatelessWidget {
  final Student? student;
  final VoidCallback onTap;
  const _SelectedStudentCard({required this.student, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = student;
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: s == null
            ? Text(
                context.t('noStudentSelected'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
              )
            : Column(
                children: [
                  Text(
                    context.t('selectedStudent'),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 38,
                      height: 1.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.indigo,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PointsBadge(points: s.points, fontSize: 22),
                ],
              ),
      ),
    );
  }
}

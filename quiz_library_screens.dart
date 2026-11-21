import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'digits.dart';
import 'quiz_library_data.dart';
import 'strings.dart';
import 'widgets.dart';

String _key(String text) => westernDigits(text).trim();

/// "Question library": ready-made questions (with answers) grouped by topic.
/// Tap + to copy a question into your own question bank, where you can still edit it.
class QuizLibraryScreen extends StatefulWidget {
  const QuizLibraryScreen({super.key});

  @override
  State<QuizLibraryScreen> createState() => _QuizLibraryScreenState();
}

class _QuizLibraryScreenState extends State<QuizLibraryScreen> {
  Set<String> _inBank = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bank = await DatabaseHelper.instance.getQuestions();
    if (!mounted) return;
    setState(() => _inBank = {for (final q in bank) _key(q.text)});
  }

  @override
  Widget build(BuildContext context) {
    var total = 0;
    for (final c in kQuizLibrary) {
      total += c.questions.length;
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.t('quizLibrary'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.emerald, Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$total ${context.t('questionsCount')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        context.t('quizLibrarySub'),
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final cat in kQuizLibrary)
            Builder(
              builder: (context) {
                final added =
                    cat.questions.where((q) => _inBank.contains(_key(q.text))).length;
                return SoftCard(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => QuizLibraryCategoryScreen(category: cat)),
                    );
                    _load();
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${cat.questions.length} ${context.t('questionsCount')}  ·  $added ${context.t('addedLabel')}',
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.indigo),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Questions of one topic with "add to my bank" buttons.
class QuizLibraryCategoryScreen extends StatefulWidget {
  final LibCategory category;
  const QuizLibraryCategoryScreen({super.key, required this.category});

  @override
  State<QuizLibraryCategoryScreen> createState() => _QuizLibraryCategoryScreenState();
}

class _QuizLibraryCategoryScreenState extends State<QuizLibraryCategoryScreen> {
  final _db = DatabaseHelper.instance;
  Set<String> _inBank = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bank = await _db.getQuestions();
    if (!mounted) return;
    setState(() => _inBank = {for (final q in bank) _key(q.text)});
  }

  Future<void> _add(LibQuestion q) async {
    if (_inBank.contains(_key(q.text))) return;
    await _db.insertQuestion(
      Question(text: q.text, correct: q.correct, wrong1: q.wrong1, wrong2: q.wrong2),
    );
    await _load();
  }

  Future<void> _addAll() async {
    var added = 0;
    for (final q in widget.category.questions) {
      if (_inBank.contains(_key(q.text))) continue;
      await _db.insertQuestion(
        Question(text: q.text, correct: q.correct, wrong1: q.wrong1, wrong2: q.wrong2),
      );
      _inBank.add(_key(q.text));
      added++;
    }
    await _load();
    if (mounted) showSnack(context, '${context.t('addedCount')}: $added');
  }

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    final missing = cat.questions.where((q) => !_inBank.contains(_key(q.text))).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(cat.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      ),
      floatingActionButton: missing == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _addAll,
              icon: const Icon(Icons.playlist_add_rounded),
              label: Text('${context.t('addAll')} ($missing)'),
            ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: cat.questions.length,
        itemBuilder: (_, i) {
          final q = cat.questions[i];
          final added = _inBank.contains(_key(q.text));
          return SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.text,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.emerald),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              q.correct,
                              style: const TextStyle(
                                color: AppColors.emerald,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade400),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${q.wrong1}   •   ${q.wrong2}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                added
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.task_alt_rounded, color: AppColors.emerald, size: 30),
                      )
                    : IconButton.filled(
                        tooltip: context.t('addToBank'),
                        style: IconButton.styleFrom(backgroundColor: AppColors.indigo),
                        onPressed: () => _add(q),
                        icon: const Icon(Icons.add_rounded),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

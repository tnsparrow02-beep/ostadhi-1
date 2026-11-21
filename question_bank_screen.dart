import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'digits.dart';
import 'strings.dart';
import 'widgets.dart';

/// Teacher's question bank: create, edit, delete questions.
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final _db = DatabaseHelper.instance;
  List<Question> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _db.getQuestions();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _openEditor([Question? q]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => QuestionEditorScreen(question: q)),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Question q) async {
    if (!await confirmDelete(context, what: q.text)) return;
    await _db.deleteQuestion(q.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('questionBank'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.t('addQuestion')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? EmptyState(icon: Icons.library_books_outlined, message: context.t('noQuestionsYet'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final q = _items[i];
                    return SoftCard(
                      onTap: () => _openEditor(q),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.text,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                                          fontWeight: FontWeight.w700,
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
                          IconButton(
                            tooltip: context.t('delete'),
                            onPressed: () => _delete(q),
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

/// Full-screen editor. The math-symbol bar sits just above the keyboard
/// and inserts into whichever field was focused last.
class QuestionEditorScreen extends StatefulWidget {
  final Question? question;
  const QuestionEditorScreen({super.key, this.question});

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _ctrls;
  late final List<FocusNode> _nodes;
  int _activeField = 0;

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _ctrls = [
      TextEditingController(text: q?.text ?? ''),
      TextEditingController(text: q?.correct ?? ''),
      TextEditingController(text: q?.wrong1 ?? ''),
      TextEditingController(text: q?.wrong2 ?? ''),
    ];
    _nodes = List.generate(4, (i) {
      final node = FocusNode();
      node.addListener(() {
        if (node.hasFocus) _activeField = i;
      });
      return node;
    });
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _insertSymbol(String s) {
    insertTextAtCursor(_ctrls[_activeField], s);
    _nodes[_activeField].requestFocus(); // keep the keyboard open
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final q = Question(
      id: widget.question?.id,
      text: _ctrls[0].text.trim(),
      correct: _ctrls[1].text.trim(),
      wrong1: _ctrls[2].text.trim(),
      wrong2: _ctrls[3].text.trim(),
    );
    final db = DatabaseHelper.instance;
    if (q.id == null) {
      await db.insertQuestion(q);
    } else {
      await db.updateQuestion(q);
    }
    if (mounted) Navigator.pop(context, true);
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? context.t('required') : null;

  @override
  Widget build(BuildContext context) {
    final editing = widget.question != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(editing ? 'editQuestion' : 'addQuestion')),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, color: AppColors.amber),
            label: Text(
              context.t('save'),
              style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _ctrls[0],
                    inputFormatters: const [WesternDigitsFormatter()],
                    focusNode: _nodes[0],
                    minLines: 3,
                    maxLines: 6,
                    style: const TextStyle(fontSize: 20),
                    validator: _required,
                    decoration: fieldDecoration(context.t('question')),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ctrls[1],
                    inputFormatters: const [WesternDigitsFormatter()],
                    focusNode: _nodes[1],
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    validator: _required,
                    decoration: fieldDecoration(
                      context.t('correctAnswer'),
                      prefix: const Icon(Icons.check_circle_rounded, color: AppColors.emerald),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ctrls[2],
                    inputFormatters: const [WesternDigitsFormatter()],
                    focusNode: _nodes[2],
                    style: const TextStyle(fontSize: 18),
                    validator: _required,
                    decoration: fieldDecoration(
                      context.t('wrongAnswer1'),
                      prefix: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ctrls[3],
                    inputFormatters: const [WesternDigitsFormatter()],
                    focusNode: _nodes[3],
                    style: const TextStyle(fontSize: 18),
                    validator: _required,
                    decoration: fieldDecoration(
                      context.t('wrongAnswer2'),
                      prefix: const Icon(Icons.cancel_rounded, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _SymbolBar(onSymbol: _insertSymbol),
        ],
      ),
    );
  }
}

class _SymbolBar extends StatelessWidget {
  final ValueChanged<String> onSymbol;
  const _SymbolBar({required this.onSymbol});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              for (final s in kMathSymbols)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: AppColors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      canRequestFocus: false,
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onSymbol(s),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

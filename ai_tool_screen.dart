import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'database_helper.dart';
import 'digits.dart';
import 'smart_parser.dart';
import 'strings.dart';
import 'widgets.dart';

/// One parsed question being reviewed (editable before it is added to the bank).
class _Draft {
  final TextEditingController question;
  final List<TextEditingController> answers;
  int? correct;
  bool include = true;
  final bool generated;
  final int dropped;

  _Draft(ParsedQuestion p)
      : question = TextEditingController(text: p.text),
        answers = [for (final c in p.choices) TextEditingController(text: c)],
        correct = p.correct,
        generated = p.generated,
        dropped = p.dropped;

  bool get complete =>
      question.text.trim().isNotEmpty &&
      answers.every((c) => c.text.trim().isNotEmpty) &&
      correct != null;

  void dispose() {
    question.dispose();
    for (final c in answers) {
      c.dispose();
    }
  }
}

/// "AI tool": paste raw text containing questions and answers; the app separates every question
/// from its choices, finds the correct answer, and lets you review before adding to the quiz.
/// Works completely offline.
class AiToolScreen extends StatefulWidget {
  const AiToolScreen({super.key});

  @override
  State<AiToolScreen> createState() => _AiToolScreenState();
}

class _AiToolScreenState extends State<AiToolScreen> {
  final _input = TextEditingController();
  List<_Draft> _drafts = [];
  bool _saving = false;

  @override
  void dispose() {
    _input.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) return;
    setState(() => _input.text = text);
  }

  void _analyze() {
    final parsed = SmartParser.parse(_input.text);
    if (parsed.isEmpty) {
      showSnack(context, context.t('aiNothingFound'));
      return;
    }
    for (final d in _drafts) {
      d.dispose();
    }
    setState(() => _drafts = [for (final p in parsed) _Draft(p)]);
  }

  void _backToText() {
    for (final d in _drafts) {
      d.dispose();
    }
    setState(() => _drafts = []);
  }

  int get _readyCount => _drafts.where((d) => d.include && d.complete).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    final db = DatabaseHelper.instance;
    final existing = {for (final q in await db.getQuestions()) westernDigits(q.text).trim()};
    var added = 0;
    var duplicates = 0;
    for (final d in _drafts) {
      if (!d.include || !d.complete) continue;
      final text = d.question.text.trim();
      final key = westernDigits(text);
      if (existing.contains(key)) {
        duplicates++;
        continue;
      }
      final ci = d.correct!;
      final answers = [for (final c in d.answers) c.text.trim()];
      final wrongs = [
        for (var i = 0; i < answers.length; i++)
          if (i != ci) answers[i],
      ];
      await db.insertQuestion(
        Question(text: text, correct: answers[ci], wrong1: wrongs[0], wrong2: wrongs[1]),
      );
      existing.add(key);
      added++;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    var message = '${context.t('addedCount')}: $added';
    if (duplicates > 0) message += '  ·  ${context.t('skippedDup')}: $duplicates';
    showSnack(context, message);
    if (added > 0) Navigator.pop(context, added);
  }

  // ───────── input step ─────────
  Widget _buildInput() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.lightbulb_rounded, color: AppColors.amber),
              title: Text(
                context.t('aiHelpTitle'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.t('aiHelpBody'), style: const TextStyle(height: 1.6)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _input.text = kSmartParserExample),
                  icon: const Icon(Icons.auto_fix_high_rounded),
                  label: Text(context.t('aiExample')),
                ),
              ],
            ),
          ),
        ),
        TextField(
          controller: _input,
          onChanged: (_) => setState(() {}),
          minLines: 10,
          maxLines: 18,
          style: const TextStyle(fontSize: 16, height: 1.5),
          decoration: fieldDecoration(null, hint: context.t('aiPasteHint')),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _paste,
                icon: const Icon(Icons.paste_rounded),
                label: Text(context.t('aiPaste')),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14)),
              onPressed: () => setState(_input.clear),
              child: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          onPressed: _input.text.trim().isEmpty ? null : _analyze,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: Text(context.t('aiAnalyze')),
        ),
      ],
    );
  }

  // ───────── review step ─────────
  Widget _buildReview() {
    final needReview = _drafts.where((d) => !d.complete).length;
    final dropped = _drafts.fold<int>(0, (sum, d) => sum + d.dropped);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${context.t('aiFound')} ${_drafts.length}  ·  $needReview ${context.t('aiNeedsReview')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: _backToText,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(context.t('aiBack')),
              ),
            ],
          ),
        ),
        if (dropped > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                context.t('aiDropped'),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: _drafts.length,
            itemBuilder: (_, i) => _buildDraft(i),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                onPressed: (_readyCount == 0 || _saving) ? null : _save,
                icon: const Icon(Icons.library_add_check_rounded),
                label: Text('${context.t('aiAddSelected')} ($_readyCount)'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDraft(int i) {
    final d = _drafts[i];
    final ok = d.complete;

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: d.include,
                onChanged: (v) => setState(() => d.include = v ?? false),
              ),
              Text('${i + 1}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: (ok ? AppColors.emerald : AppColors.danger).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  ok ? context.t('aiReady') : context.t('aiNeedsReview'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: ok ? AppColors.emerald : AppColors.danger,
                  ),
                ),
              ),
              if (d.generated) ...[
                const SizedBox(width: 6),
                Tooltip(
                  message: context.t('aiGenerated'),
                  child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF7C3AED)),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: d.question,
              minLines: 1,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              decoration: fieldDecoration(context.t('question')),
            ),
          ),
          const SizedBox(height: 8),
          for (var k = 0; k < d.answers.length; k++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  IconButton(
                    tooltip: context.t('aiSelectCorrect'),
                    onPressed: () => setState(() => d.correct = k),
                    icon: Icon(
                      d.correct == k
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: d.correct == k ? AppColors.emerald : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: d.answers[k],
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: d.correct == k ? FontWeight.w800 : FontWeight.w500,
                        color: d.correct == k ? AppColors.emerald : AppColors.ink,
                      ),
                      decoration: fieldDecoration(null, hint: '${context.t('aiChoice')} ${k + 1}'),
                    ),
                  ),
                ],
              ),
            ),
          if (d.correct == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.t('aiSelectCorrect'),
                style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('aiTool'))),
      body: _drafts.isEmpty ? _buildInput() : _buildReview(),
    );
  }
}

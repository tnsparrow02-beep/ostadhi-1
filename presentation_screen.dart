import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'app_state.dart';
import 'database_helper.dart';
import 'random_picker.dart';
import 'strings.dart';
import 'widgets.dart';

/// true  = a student only earns the point if the first answer tapped is the right one
///         (same rule as the quiz score);
/// false = the point is also given when the right answer comes after a wrong attempt.
const bool kPointOnlyFirstTry = true;

class _Choice {
  final String text;
  final bool correct;
  const _Choice(this.text, this.correct);
}

/// Classroom "Presentation Mode": big high-contrast question + 3 answers.
/// Correct answer => confetti + chime + spoken "أحسنت / Bravo ! / Well done!" + big banner.
class PresentationScreen extends StatefulWidget {
  final List<Question> questions;
  final int initialIndex;

  const PresentationScreen({super.key, required this.questions, this.initialIndex = 0});

  @override
  State<PresentationScreen> createState() => _PresentationScreenState();
}

class _PresentationScreenState extends State<PresentationScreen> {
  final _rng = Random();
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  final _player = AudioPlayer();
  final _tts = FlutterTts();

  late int _index;
  int _score = 0;
  late List<_Choice> _choices;
  final Set<int> _wrong = {};
  int? _correctIndex;
  bool _answered = false;
  bool _firstTry = true;
  bool _bannerVisible = false;
  String? _awardLabel; // "+1 · student name" shown in the banner
  String _bravoText = ''; // praise shown in the banner (same text is spoken)
  Timer? _timer; // optional countdown per question (see Settings)
  int _timerTotal = 0;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.questions.length - 1).toInt();
    _prepareQuestion();
    _initTts();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {/* TTS is optional: the app keeps working without it */}
  }

  /// Tries the most specific voice first (e.g. ar-SA), then falls back to the next one.
  Future<void> _setTtsLanguage(String lang) async {
    final candidates = switch (lang) {
      'ar' => const ['ar-SA', 'ar'],
      'fr' => const ['fr-FR', 'fr'],
      _ => const ['en-US', 'en'],
    };
    for (final code in candidates) {
      final available = await _tts.isLanguageAvailable(code);
      if (available == true) {
        await _tts.setLanguage(code);
        return;
      }
    }
    await _tts.setLanguage(candidates.first);
  }

  void _prepareQuestion() {
    final q = widget.questions[_index];
    _choices = [
      _Choice(q.correct, true),
      _Choice(q.wrong1, false),
      _Choice(q.wrong2, false),
    ]..shuffle(_rng);
    _wrong.clear();
    _correctIndex = null;
    _answered = false;
    _firstTry = true;
    _bannerVisible = false;
    _awardLabel = null;
    _startTimer();
  }

  Future<void> _celebrate(String lang, String phrase) async {
    _confetti.play();
    if (!AppState.soundOn.value) return; // sound and voice switched off in Settings
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.wav'));
    } catch (_) {}
    try {
      await Future.delayed(const Duration(milliseconds: 600)); // let the chime ring first
      await _tts.stop();
      await _setTtsLanguage(lang);
      await _tts.speak(phrase);
    } catch (_) {}
  }

  /// +1 point for the selected student, saved in the local database.
  Future<void> _awardPoint(Student student) async {
    try {
      final total = await DatabaseHelper.instance.addPoint(student.id!);
      final current = AppState.selectedStudent.value;
      if (current?.id == student.id) {
        AppState.selectedStudent.value = current!.copyWith(points: total);
      }
    } catch (_) {/* a database hiccup must never block the quiz */}
  }

  void _onChoice(int i) {
    if (_answered || _wrong.contains(i)) return;

    if (_choices[i].correct) {
      _timer?.cancel();
      final lang = context.lang;
      final student = AppState.selectedStudent.value;
      // Arabic: أَحْسَنْتَ (male) / أَحْسَنْتِ (female) - diacritics are kept for the voice.
      final phrase = context.bravoFor(female: student?.isFemale ?? false);
      final earnsPoint = student?.id != null && (!kPointOnlyFirstTry || _firstTry);
      setState(() {
        _answered = true;
        _correctIndex = i;
        _bannerVisible = true;
        _bravoText = phrase;
        _awardLabel = earnsPoint ? '+1  ·  ${student!.name}' : null;
        if (_firstTry) _score++;
      });
      if (earnsPoint) _awardPoint(student!);
      _celebrate(lang, phrase);
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (mounted) setState(() => _bannerVisible = false);
      });
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _wrong.add(i);
        _firstTry = false;
      });
    }
  }

  /// Jump to any question of the bank (list in creation order).
  Future<void> _pickQuestion() async {
    final bank = List<Question>.of(widget.questions)
      ..sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
    final currentId = widget.questions[_index].id;

    final chosenId = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(sheet).size.height * 0.75),
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  sheet.t('jumpToQuestion'),
                  style: Theme.of(sheet).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (var i = 0; i < bank.length; i++)
                ListTile(
                  selected: bank[i].id == currentId,
                  selectedTileColor: AppColors.indigo.withValues(alpha: 0.08),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.indigo.withValues(alpha: 0.12),
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.indigo, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(bank[i].text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(sheet, bank[i].id),
                ),
            ],
          ),
        ),
      ),
    );

    if (chosenId == null || !mounted) return;
    final target = widget.questions.indexWhere((q) => q.id == chosenId);
    if (target < 0 || target == _index) return;
    _tts.stop();
    setState(() {
      _index = target;
      _prepareQuestion();
    });
  }

  /// Starts the countdown for the current question (does nothing when the timer is off).
  void _startTimer() {
    _timer?.cancel();
    _timerTotal = AppState.timerSeconds.value;
    _remaining = _timerTotal;
    if (_timerTotal <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _answered) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 5 && _remaining > 0) HapticFeedback.selectionClick();
      if (_remaining <= 0) {
        t.cancel();
        _onTimeUp();
      }
    });
  }

  /// Time is over: show the right answer (no point, no celebration).
  void _onTimeUp() {
    HapticFeedback.heavyImpact();
    setState(() {
      _answered = true;
      _correctIndex = _choices.indexWhere((c) => c.correct);
      _bannerVisible = false;
    });
    showSnack(context, context.t('timeUp'));
  }

  Widget _buildTimerBar() {
    final danger = _remaining <= 5 && !_answered;
    final color = danger ? AppColors.danger : AppColors.amber;
    final value = (_timerTotal == 0 ? 0.0 : _remaining / _timerTotal).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Icon(Icons.timer_rounded, color: color, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                color: color,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(
              '${_remaining < 0 ? 0 : _remaining}',
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  void _next() {
    _tts.stop();
    if (_index >= widget.questions.length - 1) {
      _showResult();
    } else {
      setState(() {
        _index++;
        _prepareQuestion();
      });
    }
  }

  Future<void> _showResult() async {
    _confetti.play();
    final total = widget.questions.length;
    final action = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(c.t('quizFinished'), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_rounded, size: 72, color: AppColors.amber),
            const SizedBox(height: 8),
            Text(
              '${c.t('score')}: $_score / $total',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, 'close'), child: Text(c.t('close'))),
          FilledButton(onPressed: () => Navigator.pop(c, 'restart'), child: Text(c.t('restart'))),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'restart') {
      setState(() {
        widget.questions.shuffle();
        _index = 0;
        _score = 0;
        _prepareQuestion();
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _pickStudent() async {
    final classId = AppState.activeClassId.value;
    if (classId == null) {
      showSnack(context, context.t('noClassSelected'));
      return;
    }
    await showStudentChooser(context, classId);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questions[_index];
    final total = widget.questions.length;
    final size = MediaQuery.of(context).size;
    final wide = size.width > size.height;
    final letters = context.lang == 'ar' ? ['أ', 'ب', 'ج'] : ['A', 'B', 'C'];
    final isLast = _index == total - 1;

    final questionCard = _QuestionCard(text: q.text);
    final choices = Column(
      children: [
        for (var i = 0; i < _choices.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _ChoiceTile(
                letter: letters[i],
                text: _choices[i].text,
                isCorrect: _correctIndex == i,
                isWrong: _wrong.contains(i),
                dimmed: _answered && _correctIndex != i,
                onTap: () => _onChoice(i),
              ),
            ),
          ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.deepIndigo,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                      ),
                      Text(
                        '${_index + 1} / $total',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      IconButton(
                        tooltip: context.t('jumpToQuestion'),
                        onPressed: _pickQuestion,
                        icon: const Icon(Icons.format_list_numbered_rounded,
                            color: Colors.white, size: 28),
                      ),
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: ValueListenableBuilder<Student?>(
                          valueListenable: AppState.selectedStudent,
                          builder: (context, student, _) => ActionChip(
                            avatar: const Icon(Icons.casino_rounded, size: 20, color: AppColors.ink),
                            label: Text(
                              student == null
                                  ? context.t('pickStudent')
                                  : '${student.name}  ·  ${student.points}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
                            ),
                            backgroundColor: AppColors.amber,
                            side: BorderSide.none,
                            onPressed: _pickStudent,
                          ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        avatar: const Icon(Icons.star_rounded, color: AppColors.amber),
                        label: Text('$_score',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        backgroundColor: Colors.white12,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ),
                if (_timerTotal > 0) _buildTimerBar(),
                // Question + choices
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: wide
                        ? Row(
                            children: [
                              Expanded(flex: 5, child: questionCard),
                              const SizedBox(width: 16),
                              Expanded(flex: 6, child: choices),
                            ],
                          )
                        : Column(
                            children: [
                              Expanded(flex: 4, child: questionCard),
                              const SizedBox(height: 10),
                              Expanded(flex: 6, child: choices),
                            ],
                          ),
                  ),
                ),
                // Next / Finish
                SizedBox(
                  height: 78,
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: _answered ? 1 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: IgnorePointer(
                        ignoring: !_answered,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.amber,
                            foregroundColor: AppColors.ink,
                            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                            textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          onPressed: _next,
                          icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
                          label: Text(context.t(isLast ? 'finish' : 'next')),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Confetti (two emitters)
            Align(alignment: Alignment.topCenter, child: _confettiWidget()),
            Align(alignment: Alignment.center, child: _confettiWidget()),

            // Big "أحسنت / Bravo ! / Well done!" banner
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _bannerVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Center(
                    child: AnimatedScale(
                      scale: _bannerVisible ? 1 : 0.6,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.emerald,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.emoji_events_rounded, size: 56, color: AppColors.amber),
                                const SizedBox(width: 16),
                                Text(
                                  _bravoText.isEmpty ? context.t('bravo') : _bravoText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 56,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            if (_awardLabel != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  _awardLabel!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
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
    );
  }

  Widget _confettiWidget() => ConfettiWidget(
        confettiController: _confetti,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        emissionFrequency: 0.06,
        numberOfParticles: 30,
        maxBlastForce: 28,
        minBlastForce: 8,
        gravity: 0.25,
        colors: const [
          AppColors.emerald,
          AppColors.amber,
          Colors.white,
          Color(0xFF818CF8),
          Color(0xFFF472B6),
        ],
      );
}

class _QuestionCard extends StatelessWidget {
  final String text;
  const _QuestionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Center(
        child: SingleChildScrollView(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              height: 1.45,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  final bool isWrong;
  final bool dimmed;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.letter,
    required this.text,
    required this.isCorrect,
    required this.isWrong,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isCorrect
        ? AppColors.emerald
        : isWrong
            ? const Color(0xFFFECACA)
            : Colors.white;
    final Color fg = isCorrect ? Colors.white : AppColors.ink;

    return AnimatedOpacity(
      opacity: dimmed || isWrong ? 0.55 : 1,
      duration: const Duration(milliseconds: 250),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCorrect ? AppColors.amber : Colors.transparent,
            width: 4,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: isCorrect ? Colors.white : AppColors.indigo,
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isCorrect ? AppColors.emerald : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        text,
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: fg),
                      ),
                    ),
                  ),
                  if (isCorrect) const Icon(Icons.check_circle_rounded, color: Colors.white, size: 38),
                  if (isWrong) const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 38),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

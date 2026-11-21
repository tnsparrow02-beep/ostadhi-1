import 'dart:math';

import 'digits.dart';

/// One question found in pasted text. [choices] always has exactly 3 entries
/// (an entry can be empty when the text did not give enough answers: the teacher completes it).
class ParsedQuestion {
  final String text;
  final List<String> choices;

  /// Index (0-2) of the correct choice, or null when the text did not say which one is right.
  final int? correct;

  /// Number of extra choices that were ignored (the app uses 3 choices per question).
  final int dropped;

  /// True when wrong answers were invented for a numeric answer.
  final bool generated;

  const ParsedQuestion({
    required this.text,
    required this.choices,
    required this.correct,
    this.dropped = 0,
    this.generated = false,
  });
}

class _Block {
  String text;
  final List<String> choices = <String>[];
  int? marked;
  String? answer;

  _Block([this.text = '']);

  void addChoice(String body, {bool lead = false}) {
    final r = SmartParser._stripMark(body);
    if ((r.marked || lead) && marked == null) marked = choices.length;
    choices.add(r.text);
  }
}

class _Marked {
  final String text;
  final bool marked;
  const _Marked(this.text, this.marked);
}

class _Split {
  final String body;
  final String? answer;
  const _Split(this.body, this.answer);
}

class _State {
  _Block? cur;
  final List<_Block> blocks = <_Block>[];

  void close() {
    final c = cur;
    if (c != null) blocks.add(c);
    cur = null;
  }
}

/// Offline "smart" parser (no internet, no AI service): it recognises the usual ways of writing
/// quizzes (numbered questions, choices أ) ب) ج) or A) B) C), answer lines, ✓ marks, Q/A pairs...)
/// and turns them into structured questions.
class SmartParser {
  SmartParser._();

  static const String _letters = 'A-Ea-eأإاآبجدهـ';
  static const String _qWord = r'(?:السؤال|سؤال|س|Question|Qst|Q)';
  static const String _ansWords =
      r'(?:الإجابة|الاجابة|إجابة|اجابة|الجواب|جواب|Answer|Ans|Réponse|Reponse|Rép)';
  static const String _ansTail =
      r'\s*(?:الصحيحة هي|الصحيح هو|الصحيحة|الصحيح|النموذجية|هي|هو)?\s*[:：=\-–]?\s*(.+)$';

  static final RegExp _bullet = RegExp(r'^\s*[-*•●▪◦]\s+(?=\S)');
  static final RegExp _qNum = RegExp(
    r'^\s*(?:' + _qWord + r'\s*)?(\d{1,3})(?:\s*[\.\)\]:]|-(?=\s))\s*(.*)$',
    caseSensitive: false,
  );
  static final RegExp _qNumDash = RegExp(r'^\s*(?:' + _qWord + r'\s*)?\d{1,3}-', caseSensitive: false);
  static final RegExp _qNoNum = RegExp(
    r'^\s*' + _qWord + r'\s*[:：\.\)\-]\s*(.+)$',
    caseSensitive: false,
  );
  static final RegExp _ansStrong = RegExp(r'^\s*' + _ansWords + _ansTail, caseSensitive: false);
  static final RegExp _trailAns = RegExp(r'\s+' + _ansWords + _ansTail, caseSensitive: false);
  static final RegExp _ansWeak = RegExp(
    r'^\s*(?:الحل|Solution|Correct|ج|A)\s*[:：=]\s*(.+)$',
    caseSensitive: false,
  );
  static final RegExp _choice = RegExp(
    r'^\s*[\(\[]?\s*([' + _letters + r'])\s*(?:[\)\]]\s*|[\.\-:–]\s+)(.+)$',
  );
  static final RegExp _inline = RegExp(r'(?:^|\s)[\(\[]?([' + _letters + r'])[\)\]]\s*');
  static final RegExp _leadMark = RegExp(r'^[✓✔✅☑*]+\s*(.*)$');
  static final RegExp _trailMark = RegExp(
    r'(?:\s*[✓✔✅☑*]+|\s*[\(\[](?:صح|صحيح|صحيحة|الصحيحة|الإجابة الصحيحة|correct|vrai)[\)\]])\s*$',
    caseSensitive: false,
  );
  static final RegExp _number = RegExp(r'^\s*(-?\d+(?:[.,]\d+)?)(.*)$');

  static int? _letterIndex(String ch) {
    if ('Aaأإاآ'.contains(ch)) return 0;
    if ('Bbب'.contains(ch)) return 1;
    if ('Ccج'.contains(ch)) return 2;
    if ('Ddد'.contains(ch)) return 3;
    if ('Eeهـ'.contains(ch)) return 4;
    return null;
  }

  static String _norm(String s) => s.replaceAll(RegExp(r'\s+'), '').toLowerCase();

  static _Marked _stripMark(String input) {
    var s = input.replaceAll('**', '').replaceAll('__', '').trim();
    var marked = false;
    final t = _trailMark.firstMatch(s);
    if (t != null) {
      marked = true;
      s = s.substring(0, t.start).trim();
    }
    final l = _leadMark.firstMatch(s);
    if (l != null) {
      marked = true;
      s = (l.group(1) ?? '').trim();
    }
    return _Marked(s, marked);
  }

  static _Split _splitTrailingAnswer(String text) {
    final m = _trailAns.firstMatch(text);
    if (m == null) return _Split(text, null);
    return _Split(text.substring(0, m.start).trim(), (m.group(1) ?? '').trim());
  }

  /// Splits "ما ناتج 2+2؟ أ) 3 ب) 4 ج) 5" style text. Returns false when the text has no inline choices.
  static bool _readInline(_Block block, String rest, {required bool setText}) {
    final ms = _inline.allMatches(rest).toList();
    if (ms.length < 2) return false;
    if (setText) block.text = rest.substring(0, ms.first.start).trim();
    for (var k = 0; k < ms.length; k++) {
      final end = k + 1 < ms.length ? ms[k + 1].start : rest.length;
      var piece = rest.substring(ms[k].end, end);
      if (k + 1 == ms.length) {
        final split = _splitTrailingAnswer(piece);
        piece = split.body;
        if (split.answer != null) block.answer = split.answer;
      }
      block.addChoice(piece);
    }
    return true;
  }

  /// Parses [raw] and returns the questions found. Never throws.
  static List<ParsedQuestion> parse(String raw, {Random? random}) {
    final rng = random ?? Random();
    final blocks = _parseBlocks(raw);
    final out = <ParsedQuestion>[];
    for (final b in blocks) {
      if (b.text.trim().isEmpty && b.choices.isEmpty) continue;
      if (b.choices.isEmpty && b.answer == null) continue; // a title or a stray line
      out.add(_finish(b, rng));
    }
    return out;
  }

  static List<_Block> _parseBlocks(String raw) {
    var s = westernDigits(raw).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (final ch in ['\u200f', '\u200e', '\u202a', '\u202b', '\u202c']) {
      s = s.replaceAll(ch, '');
    }
    s = s.replaceAll('\u00a0', ' ').replaceAll('**', '').replaceAll('__', '');
    final lines = s.split('\n');
    final st = _State();

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      final bm = _bullet.firstMatch(line);
      if (bm != null) {
        final rest = line.substring(bm.end);
        if (_choice.hasMatch(rest) || _qNum.hasMatch(rest) || _qNoNum.hasMatch(rest)) {
          line = rest.trim();
        }
      }

      if (line.isEmpty) {
        final open = st.cur;
        if (open != null && (open.choices.length >= 2 || open.answer != null)) st.close();
        continue;
      }

      var lead = false;
      final lm = _leadMark.firstMatch(line);
      if (lm != null && (lm.group(1) ?? '').isNotEmpty) {
        lead = true;
        line = (lm.group(1) ?? '').trim();
      }

      // Answer line: "الإجابة: ب"
      final am = _ansStrong.firstMatch(line);
      if (am != null && st.cur != null) {
        st.cur!.answer = (am.group(1) ?? '').trim();
        continue;
      }

      // Numbered question: "1) ...", "سؤال 2: ...", "Q3. ..."
      final qm = _qNum.firstMatch(line);
      if (qm != null) {
        final rest = qm.group(2) ?? '';
        final dash = _qNumDash.hasMatch(line);
        final looksLikeMath = dash && RegExp(r'^[\d+\-*/=×÷]').hasMatch(rest);
        if (!looksLikeMath) {
          st.close();
          final b = _Block();
          st.cur = b;
          if (!_readInline(b, rest, setText: true)) b.text = rest.trim();
          continue;
        }
      }

      // Question without number: "س: ...", "Q: ..."
      final qn = _qNoNum.firstMatch(line);
      if (qn != null) {
        st.close();
        final b = _Block();
        st.cur = b;
        final rest = qn.group(1) ?? '';
        if (!_readInline(b, rest, setText: true)) b.text = rest.trim();
        continue;
      }

      // Q/A style answer: "ج: 8" (only before any choice, and not when "B:" follows)
      final wm = _ansWeak.firstMatch(line);
      final c0 = st.cur;
      if (wm != null && c0 != null && c0.choices.isEmpty) {
        var next = '';
        for (var j = i + 1; j < lines.length; j++) {
          final t = lines[j].trim();
          if (t.isNotEmpty) {
            next = t;
            break;
          }
        }
        final nm = _choice.firstMatch(next);
        final nextIsSecondChoice = nm != null && _letterIndex(nm.group(1)!) == 1;
        if (!nextIsSecondChoice) {
          c0.answer = (wm.group(1) ?? '').trim();
          continue;
        }
      }

      // Several choices on one line: "أ) 7 ب) 8 ج) 9"
      final inlineProbe = _inline.allMatches(line).toList();
      if (inlineProbe.length >= 2) {
        final prefix = line.substring(0, inlineProbe.first.start).trim();
        final existing = st.cur;
        _Block target;
        if (prefix.isNotEmpty &&
            (existing == null || existing.choices.isNotEmpty || existing.answer != null)) {
          st.close();
          target = _Block(prefix);
        } else if (prefix.isNotEmpty) {
          existing!.text = '${existing.text} $prefix'.trim();
          target = existing;
        } else {
          target = existing ?? _Block();
        }
        st.cur = target;
        _readInline(target, line.substring(inlineProbe.first.start), setText: false);
        continue;
      }

      // One choice per line: "أ) 7", "B. 8"
      final cm = _choice.firstMatch(line);
      if (cm != null && st.cur != null) {
        st.cur!.addChoice(cm.group(2) ?? '', lead: lead);
        continue;
      }

      // Plain line: new question, or continuation of the previous text
      final tail = st.cur;
      if (tail == null) {
        st.cur = _Block(line);
      } else if (tail.answer != null || tail.choices.length >= 2) {
        st.close();
        st.cur = _Block(line);
      } else if (tail.choices.isNotEmpty) {
        tail.choices[tail.choices.length - 1] = '${tail.choices.last} $line';
      } else {
        tail.text = '${tail.text} $line'.trim();
      }
    }
    st.close();
    return st.blocks;
  }

  static ParsedQuestion _finish(_Block b, Random rng) {
    var choices = List<String>.of(b.choices);
    var idx = b.marked;
    String? correctText;
    final answer = b.answer;

    if (idx == null && answer != null) {
      final a = answer.trim();
      final mm = _choice.firstMatch(a);
      final cleaned = a.replaceAll(RegExp(r'[\(\)\[\]\.\s\-:،,]'), '');
      final byPrefix = mm == null ? null : _letterIndex(mm.group(1)!);
      final byLetter = cleaned.length == 1 ? _letterIndex(cleaned) : null;
      if (byPrefix != null && byPrefix < choices.length) {
        idx = byPrefix;
      } else if (byLetter != null && choices.isNotEmpty && byLetter < choices.length) {
        idx = byLetter;
      } else {
        final n = _norm(a);
        for (var k = 0; k < choices.length; k++) {
          if (_norm(choices[k]) == n) {
            idx = k;
            break;
          }
        }
        if (idx == null) correctText = a;
      }
    }

    // Q/A pair (no choices) or an answer that is not one of the choices
    if (idx == null && correctText != null) {
      final n = _norm(correctText);
      choices = <String>[correctText, ...choices.where((c) => _norm(c) != n)];
      idx = 0;
    }

    var dropped = 0;
    if (idx != null && choices.length > 3) {
      final others = <int>[
        for (var k = 0; k < choices.length; k++)
          if (k != idx) k,
      ].take(2).toList();
      final keep = <int>[idx, ...others]..sort();
      dropped = choices.length - 3;
      final kept = [for (final k in keep) choices[k]];
      idx = keep.indexOf(idx);
      choices = kept;
    } else if (idx == null && choices.length > 3) {
      dropped = choices.length - 3;
      choices = choices.sublist(0, 3);
    }

    var generated = false;
    if (idx != null && choices.length < 3) {
      final extra = _distractors(choices[idx], 3 - choices.length, rng, choices);
      if (extra.isNotEmpty) generated = true;
      choices = <String>[...choices, ...extra];
    }
    while (choices.length < 3) {
      choices.add('');
    }

    return ParsedQuestion(
      text: b.text.trim(),
      choices: choices,
      correct: idx,
      dropped: dropped,
      generated: generated,
    );
  }

  /// Invents plausible wrong answers when the correct answer is a number (keeps the unit and decimals).
  static List<String> _distractors(String correct, int need, Random rng, List<String> exclude) {
    final m = _number.firstMatch(correct);
    if (m == null) return <String>[];
    final numText = m.group(1)!;
    final suffix = m.group(2) ?? '';
    final comma = numText.contains(',');
    final parts = numText.split(RegExp(r'[.,]'));
    final dec = parts.length > 1 ? parts[1].length : 0;
    final v = double.tryParse(numText.replaceAll(',', '.'));
    if (v == null) return <String>[];
    final step = dec > 0 ? pow(10, -dec).toDouble() : 1.0;

    final pool = <double>[
      v + step,
      v - step,
      v + 2 * step,
      v - 2 * step,
      v * 2,
      v + 10 * step,
      v != 0 ? v / 2 : v + 3 * step,
    ]..shuffle(rng);

    final taken = exclude.map(_norm).toSet();
    final out = <String>[];
    for (final c in pool) {
      if (v >= 0 && c < 0) continue;
      var t = c.toStringAsFixed(dec);
      if (comma) t = t.replaceAll('.', ',');
      t = '$t$suffix';
      final key = _norm(t);
      if (taken.contains(key)) continue;
      taken.add(key);
      out.add(t);
      if (out.length == need) break;
    }
    return out;
  }
}

/// Example shown by the "Insert example" button of the AI tool.
const String kSmartParserExample = '''1) ما ناتج 5 + 3؟
أ) 7
ب) 8
ج) 9
الإجابة: ب

2) ما هي عاصمة تونس؟
أ) صفاقس
ب) تونس ✓
ج) سوسة

3) ما قيمة √81؟ أ) 7 ب) 9 ج) 11 الجواب: ب

س: ما ناتج 12 × 5؟
ج: 60''';

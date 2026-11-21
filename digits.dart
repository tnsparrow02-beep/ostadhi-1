import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
const String _easternPersian = '۰۱۲۳۴۵۶۷۸۹';

/// Replaces Eastern Arabic (٠١٢...) and Persian (۰۱۲...) digits with Western digits (0123...).
/// Also normalizes the Arabic decimal / thousands separators.
String westernDigits(String input) {
  if (input.isEmpty) return input;
  final buf = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    var i = _arabicIndic.indexOf(ch);
    if (i < 0) i = _easternPersian.indexOf(ch);
    if (i >= 0) {
      buf.write(i);
    } else if (ch == '٫') {
      buf.write('.');
    } else if (ch == '٬') {
      buf.write(',');
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// Converts digits typed with an Arabic keyboard to Western digits while typing.
class WesternDigitsFormatter extends TextInputFormatter {
  const WesternDigitsFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final text = westernDigits(newValue.text);
    // 1 character => 1 character, so the cursor position stays valid.
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}

/// "Monday 17 November 2026" with Western digits, whatever the language.
String formatFullDate(DateTime d, String lang) =>
    westernDigits(DateFormat.yMMMMEEEEd(lang).format(d));

/// "November 2026" with Western digits (calendar header).
String formatMonthYear(DateTime d, String lang) =>
    westernDigits(DateFormat.yMMMM(lang).format(d));

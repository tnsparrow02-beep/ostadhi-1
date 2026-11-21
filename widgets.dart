import 'package:flutter/material.dart';

import 'digits.dart';
import 'strings.dart';

/// Lets the lock screen (which sits above the Navigator) open dialogs.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AppColors {
  static const indigo = Color(0xFF3730A3);
  static const deepIndigo = Color(0xFF1E1B4B);
  static const emerald = Color(0xFF059669);
  static const amber = Color(0xFFF59E0B);
  static const background = Color(0xFFF5F6FB);
  static const danger = Color(0xFFDC2626);
  static const ink = Color(0xFF111827);
}

/// Colors used to tell classes apart (classes list + timetable cells).
const List<Color> kClassColors = [
  Color(0xFF3730A3),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFF0E7490),
  Color(0xFF9333EA),
  Color(0xFFBE185D),
  Color(0xFF4D7C0F),
  Color(0xFFB45309),
];

const List<String> kMathSymbols = ['√', 'π', '²', '³', '÷', '×', '≠', '≤', '≥', '∞', 'Δ'];

/// Inserts [s] at the cursor (or replaces the selection) of [c].
void insertTextAtCursor(TextEditingController c, String s) {
  final text = c.text;
  final sel = c.selection;
  final start = sel.isValid ? sel.start : text.length;
  final end = sel.isValid ? sel.end : text.length;
  c.value = TextEditingValue(
    text: text.replaceRange(start, end, s),
    selection: TextSelection.collapsed(offset: start + s.length),
  );
}

InputDecoration fieldDecoration(String? label, {String? hint, Widget? prefix}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: prefix,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.indigo, width: 2),
    ),
  );
}

Future<bool> confirmDelete(BuildContext context, {String? what}) =>
    confirmDialog(
      context,
      title: context.t('confirmDelete'),
      body: what,
      confirmLabel: context.t('delete'),
    );

/// Cancel / confirm dialog. The confirm button is red (destructive actions).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.t('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Small dialog with one text field. Returns the trimmed text, or null if cancelled.
Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String? hint,
  bool multiline = false,
}) {
  final ctrl = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        inputFormatters: const [WesternDigitsFormatter()],
        minLines: multiline ? 4 : 1,
        maxLines: multiline ? 10 : 1,
        textInputAction: multiline ? TextInputAction.newline : TextInputAction.done,
        onSubmitted: multiline ? null : (v) => Navigator.pop(c, v.trim()),
        decoration: fieldDecoration(label, hint: hint),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(c, ctrl.text.trim()),
          child: Text(c.t('save')),
        ),
      ],
    ),
  );
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: AppColors.indigo.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Star + number: a student's total points.
class PointsBadge extends StatelessWidget {
  final int points;
  final double fontSize;
  const PointsBadge({super.key, required this.points, this.fontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.6, vertical: fontSize * 0.25),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(fontSize),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppColors.amber, size: fontSize * 1.3),
          const SizedBox(width: 4),
          Text(
            '$points',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

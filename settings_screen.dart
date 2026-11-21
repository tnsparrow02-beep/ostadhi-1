import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'account_service.dart';
import 'app_state.dart';
import 'database_helper.dart';
import 'strings.dart';
import 'widgets.dart';

/// Settings: question timer, sound, and a backup you can copy / paste (no internet needed).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const List<int> _timerChoices = [0, 10, 20, 30, 60];

  Future<void> _backup() async {
    final text = await DatabaseHelper.instance.exportJson();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showSnack(context, context.t('backupCopied'));
  }

  Future<void> _restore() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (!DatabaseHelper.looksLikeBackup(text)) {
      showSnack(context, context.t('restoreFail'));
      return;
    }
    final ok = await confirmDialog(
      context,
      title: context.t('restoreTitle'),
      body: context.t('restoreConfirm'),
      confirmLabel: context.t('restore'),
    );
    if (!ok || !mounted) return;
    try {
      await DatabaseHelper.instance.importJson(text);
      AppState.drawnIds.clear();
      await AppState.selectStudent(null);
      await AppState.setActiveClass(null);
      AppState.dataEpoch.value++;
      if (mounted) showSnack(context, context.t('restoreOk'));
    } catch (_) {
      if (mounted) showSnack(context, context.t('restoreFail'));
    }
  }

  Future<void> _editName() async {
    final acc = AccountService.account.value;
    final last = TextEditingController(text: acc?.last ?? '');
    final first = TextEditingController(text: acc?.first ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.t('accountEdit')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: last, decoration: fieldDecoration(c.t('lastName'))),
            const SizedBox(height: 10),
            TextField(controller: first, decoration: fieldDecoration(c.t('firstName'))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(c.t('save'))),
        ],
      ),
    );
    if (ok != true) return;
    if (first.text.trim().isEmpty || last.text.trim().isEmpty) {
      if (mounted) showSnack(context, context.t('nameRequired'));
      return;
    }
    await AccountService.saveName(first.text, last.text);
  }

  /// Asks for the current password (if any) before changing or removing it.
  Future<bool> _confirmCurrent() async {
    if (AccountService.account.value?.hasPassword != true) return true;
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.t('passwordCurrent')),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          autofocus: true,
          decoration: fieldDecoration(c.t('password')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('cancel'))),
          FilledButton(
            onPressed: () async => Navigator.pop(c, await AccountService.verify(ctrl.text)),
            child: Text(c.t('confirm')),
          ),
        ],
      ),
    );
    if (ok == false && mounted) showSnack(context, context.t('passwordWrong'));
    return ok == true;
  }

  Future<void> _changePassword() async {
    if (!await _confirmCurrent()) return;
    if (!mounted) return;
    final a = TextEditingController();
    final b = TextEditingController();
    String? error;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setLocal) => AlertDialog(
          title: Text(c.t('passwordSet')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: a,
                obscureText: true,
                autofocus: true,
                decoration: fieldDecoration(c.t('password')),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: b,
                obscureText: true,
                decoration: fieldDecoration(c.t('passwordConfirm')).copyWith(errorText: error),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('cancel'))),
            FilledButton(
              onPressed: () {
                if (a.text.length < 4) {
                  setLocal(() => error = c.t('passwordShort'));
                } else if (a.text != b.text) {
                  setLocal(() => error = c.t('passwordMismatch'));
                } else {
                  Navigator.pop(c, true);
                }
              },
              child: Text(c.t('save')),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    await AccountService.setPassword(a.text);
    if (mounted) showSnack(context, context.t('passwordSaved'));
  }

  Future<void> _removePassword() async {
    if (!await _confirmCurrent()) return;
    await AccountService.setPassword('');
    if (mounted) showSnack(context, context.t('passwordRemoved'));
  }

  Widget _title(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Teacher account (first name + last name, optional password)
          SoftCard(
            child: ValueListenableBuilder<Account?>(
              valueListenable: AccountService.account,
              builder: (context, acc, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(Icons.account_circle_rounded, context.t('accountTitle'), AppColors.indigo),
                  const SizedBox(height: 10),
                  Text(acc?.fullName ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _editName,
                        icon: const Icon(Icons.edit_rounded),
                        label: Text(context.t('accountEdit')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _changePassword,
                        icon: const Icon(Icons.lock_rounded),
                        label: Text(acc?.hasPassword == true
                            ? context.t('passwordChange')
                            : context.t('passwordSet')),
                      ),
                      if (acc?.hasPassword == true)
                        OutlinedButton.icon(
                          onPressed: _removePassword,
                          icon: const Icon(Icons.lock_open_rounded, color: AppColors.danger),
                          label: Text(context.t('passwordRemove'),
                              style: const TextStyle(color: AppColors.danger)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Question timer
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(Icons.timer_rounded, context.t('timerTitle'), AppColors.amber),
                const SizedBox(height: 12),
                ValueListenableBuilder<int>(
                  valueListenable: AppState.timerSeconds,
                  builder: (context, current, _) => Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final v in _timerChoices)
                        ChoiceChip(
                          label: Text(v == 0 ? context.t('timerOff') : '$v ${context.t('seconds')}'),
                          selected: current == v,
                          onSelected: (_) => AppState.setTimer(v),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sound
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ValueListenableBuilder<bool>(
              valueListenable: AppState.soundOn,
              builder: (context, on, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.volume_up_rounded, color: AppColors.indigo),
                title: Text(
                  context.t('soundTitle'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                subtitle: Text(context.t('soundSub')),
                value: on,
                onChanged: AppState.setSound,
              ),
            ),
          ),

          // Backup / restore
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _title(Icons.shield_rounded, context.t('backupTitle'), AppColors.emerald),
                const SizedBox(height: 8),
                Text(context.t('backupCopySub'), style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
                    onPressed: _backup,
                    icon: const Icon(Icons.copy_rounded),
                    label: Text(context.t('backupCopy')),
                  ),
                ),
                const SizedBox(height: 16),
                Text(context.t('restoreSub'), style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _restore,
                    icon: const Icon(Icons.paste_rounded),
                    label: Text(context.t('restoreTitle')),
                  ),
                ),
              ],
            ),
          ),

          // About
          SoftCard(
            child: Row(
              children: [
                const Icon(Icons.functions_rounded, color: AppColors.indigo, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('appTitle'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        context.t('aboutText'),
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

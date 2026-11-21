import 'package:flutter/material.dart';

import 'account_service.dart';
import 'strings.dart';
import 'widgets.dart';

enum _Step { loading, create, locked, open }

/// First launch: create the teacher account (first name + last name, optional password).
/// Next launches: ask for the password only if one was set.
class AccountGate extends StatefulWidget {
  final Widget child;
  const AccountGate({super.key, required this.child});

  @override
  State<AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<AccountGate> {
  _Step _step = _Step.loading;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final acc = await AccountService.load();
    if (!mounted) return;
    setState(() => _step = acc == null
        ? _Step.create
        : acc.hasPassword
            ? _Step.locked
            : _Step.open);
  }

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _Step.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Step.create:
        return CreateAccountScreen(onDone: () => setState(() => _step = _Step.open));
      case _Step.locked:
        return UnlockScreen(onDone: () => setState(() => _step = _Step.open));
      case _Step.open:
        return widget.child;
    }
  }
}

class _AuthScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const _AuthScaffold({required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3730A3), Color(0xFF6D28D9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SoftCard(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.school_rounded, size: 56, color: AppColors.indigo),
                    const SizedBox(height: 10),
                    Text(title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                    const SizedBox(height: 18),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreateAccountScreen extends StatefulWidget {
  final VoidCallback onDone;
  const CreateAccountScreen({super.key, required this.onDone});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _usePwd = false;
  bool _hide = true;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _pwd.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_first.text.trim().isEmpty || _last.text.trim().isEmpty) {
      setState(() => _error = context.t('nameRequired'));
      return;
    }
    if (_usePwd) {
      if (_pwd.text.length < 4) {
        setState(() => _error = context.t('passwordShort'));
        return;
      }
      if (_pwd.text != _pwd2.text) {
        setState(() => _error = context.t('passwordMismatch'));
        return;
      }
    }
    await AccountService.create(_first.text, _last.text, _usePwd ? _pwd.text : '');
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthScaffold(
      title: context.t('accountCreate'),
      subtitle: context.t('accountWelcome'),
      children: [
        TextField(
          controller: _last,
          textInputAction: TextInputAction.next,
          decoration: fieldDecoration(context.t('lastName')),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _first,
          textInputAction: TextInputAction.next,
          decoration: fieldDecoration(context.t('firstName')),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _usePwd,
          onChanged: (v) => setState(() => _usePwd = v),
          title: Text(context.t('passwordOptional')),
        ),
        if (_usePwd) ...[
          TextField(
            controller: _pwd,
            obscureText: _hide,
            decoration: fieldDecoration(context.t('password')).copyWith(
              suffixIcon: IconButton(
                icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _hide = !_hide),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pwd2,
            obscureText: _hide,
            onSubmitted: (_) => _submit(),
            decoration: fieldDecoration(context.t('passwordConfirm')),
          ),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(_error!,
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
          ),
        const SizedBox(height: 18),
        FilledButton(onPressed: _submit, child: Text(context.t('accountCreateBtn'))),
      ],
    );
  }
}

class UnlockScreen extends StatefulWidget {
  final VoidCallback onDone;
  const UnlockScreen({super.key, required this.onDone});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pwd = TextEditingController();
  bool _hide = true;
  bool _wrong = false;

  @override
  void dispose() {
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (await AccountService.verify(_pwd.text)) {
      widget.onDone();
    } else if (mounted) {
      setState(() => _wrong = true);
      _pwd.clear();
    }
  }

  /// Forgot password: type the account's first + last name to remove the password.
  Future<void> _forgot() async {
    final first = TextEditingController();
    final last = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.t('forgotPassword')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.t('forgotPasswordBody')),
              const SizedBox(height: 12),
              TextField(controller: last, decoration: fieldDecoration(c.t('lastName'))),
              const SizedBox(height: 10),
              TextField(controller: first, decoration: fieldDecoration(c.t('firstName'))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(c.t('cancel'))),
          FilledButton(
            onPressed: () async {
              final done = await AccountService.resetWithName(first.text, last.text);
              if (c.mounted) Navigator.pop(c, done);
            },
            child: Text(c.t('confirm')),
          ),
        ],
      ),
    );
    if (ok == true) {
      widget.onDone();
    } else if (ok == false && mounted) {
      showSnack(context, context.t('nameMismatch'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = AccountService.account.value?.fullName ?? '';
    return _AuthScaffold(
      title: name.isEmpty ? context.t('passwordTitle') : name,
      subtitle: context.t('passwordTitle'),
      children: [
        TextField(
          controller: _pwd,
          obscureText: _hide,
          autofocus: true,
          onSubmitted: (_) => _submit(),
          decoration: fieldDecoration(context.t('password')).copyWith(
            errorText: _wrong ? context.t('passwordWrong') : null,
            suffixIcon: IconButton(
              icon: Icon(_hide ? Icons.visibility_rounded : Icons.visibility_off_rounded),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _submit, child: Text(context.t('unlock'))),
        TextButton(onPressed: _forgot, child: Text(context.t('forgotPassword'))),
      ],
    );
  }
}

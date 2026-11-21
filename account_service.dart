import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'database_helper.dart';

class Account {
  final String first; // اسم
  final String last; // لقب
  final bool hasPassword;
  const Account(this.first, this.last, this.hasPassword);

  String get fullName => '$first $last'.trim();
}

/// Local teacher account (works offline): first name + last name, and an OPTIONAL password.
/// The password is stored only as a salted SHA-256 hash.
class AccountService {
  AccountService._();

  static const _kFirst = 'acc_first';
  static const _kLast = 'acc_last';
  static const _kHash = 'acc_hash';
  static const _kSalt = 'acc_salt';

  static final ValueNotifier<Account?> account = ValueNotifier<Account?>(null);
  static final _db = DatabaseHelper.instance;

  /// Reads the saved account; null = no account created yet.
  static Future<Account?> load() async {
    final first = (await _db.getSetting(_kFirst)) ?? '';
    final last = (await _db.getSetting(_kLast)) ?? '';
    final hash = (await _db.getSetting(_kHash)) ?? '';
    final acc = first.isEmpty && last.isEmpty ? null : Account(first, last, hash.isNotEmpty);
    account.value = acc;
    return acc;
  }

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  static Future<void> saveName(String first, String last) async {
    await _db.setSetting(_kFirst, first.trim());
    await _db.setSetting(_kLast, last.trim());
    await load();
  }

  /// Creates the account. An empty [password] means "no password".
  static Future<void> create(String first, String last, String password) async {
    await saveName(first, last);
    await setPassword(password);
  }

  /// Sets / changes the password; an empty value removes it.
  static Future<void> setPassword(String password) async {
    if (password.isEmpty) {
      await _db.setSetting(_kHash, '');
      await _db.setSetting(_kSalt, '');
    } else {
      final salt = _newSalt();
      await _db.setSetting(_kSalt, salt);
      await _db.setSetting(_kHash, _hash(salt, password));
    }
    await load();
  }

  static Future<bool> verify(String password) async {
    final salt = (await _db.getSetting(_kSalt)) ?? '';
    final hash = (await _db.getSetting(_kHash)) ?? '';
    if (hash.isEmpty) return true;
    return _hash(salt, password) == hash;
  }

  /// Forgot password: the exact first + last name of the account allow removing the password.
  static Future<bool> resetWithName(String first, String last) async {
    final a = account.value ?? await load();
    if (a == null) return false;
    String n(String x) => x.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (n(first) != n(a.first) || n(last) != n(a.last)) return false;
    await setPassword('');
    return true;
  }
}

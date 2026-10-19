import 'dart:math';

import 'package:flutter/foundation.dart';

/// Credentials presented to Orbot's SOCKS port (RFC 1929 username/password).
class TorCredentials {
  const TorCredentials({required this.username, required this.password});

  final String username;
  final String password;
}

/// Circuit rotation without the Orbot control port.
///
/// Tor's SOCKS port isolates streams by SOCKS username/password (IsolateSOCKSAuth,
/// on by default in Tor). Each distinct pair gets its own circuit, and Tor accepts
/// any value. So:
///   * every AI model uses its own credentials → its own circuit (and exit);
///   * "New circuit" generates a new identity → all new connections use new circuits.
///
/// Existing open connections keep their old circuit. WebViews are not covered:
/// Android's ProxyController does not take per-identity SOCKS credentials.
class TorCircuitManager extends ChangeNotifier {
  TorCircuitManager._();
  static final TorCircuitManager instance = TorCircuitManager._();

  static final Random _rng = Random.secure();

  String _identity = _randomHex();
  int _rotations = 0;

  /// Random per-identity token. Changes on [newIdentity].
  String get identity => _identity;

  /// How many times the user has asked for a new circuit this session.
  int get rotations => _rotations;

  /// Credentials for [slot] (e.g. a model id) under the current identity.
  TorCredentials credentialsFor(String slot) {
    return TorCredentials(
      username: _sanitize('mdk-$_identity-$slot'),
      password: _identity,
    );
  }

  /// Starts a new identity. Only connections created after this use it.
  void newIdentity() {
    _identity = _randomHex();
    _rotations++;
    notifyListeners();
  }

  static String _randomHex() {
    final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
    return bytes.map((int b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// SOCKS usernames must be 1–255 bytes. Keep letters, digits and dashes only.
  static String _sanitize(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^A-Za-z0-9-]'), '-');
    return cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned;
  }
}

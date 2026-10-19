import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

enum TorStatus { unknown, checking, ready, notAvailable }

/// Tor gate — FAIL-CLOSED. There is no "continue without Tor" path.
/// Ready = Orbot SOCKS port 127.0.0.1:9050 accepts a TCP connection.
/// Until ready, the app shows only the gate screen; no network call is made.
class TorService extends ChangeNotifier {
  TorService._();
  static final TorService instance = TorService._();

  TorStatus _status = TorStatus.unknown;
  String _lastError = '';

  TorStatus get status => _status;
  String get lastError => _lastError;
  bool get isReady => _status == TorStatus.ready;

  Future<bool> _probeSocks() async {
    try {
      final socket = await Socket.connect(
        AppConstants.torSocksHost,
        AppConstants.torSocksPort,
        timeout: const Duration(milliseconds: 1500),
      );
      await socket.close();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<TorStatus> check() async {
    _status = TorStatus.checking;
    _lastError = '';
    notifyListeners();

    final reachable = await _probeSocks();
    if (reachable) {
      _status = TorStatus.ready;
    } else {
      _status = TorStatus.notAvailable;
      _lastError =
          'Orbot SOCKS proxy not found at ${AppConstants.torSocksHost}:${AppConstants.torSocksPort}. '
          'Install Orbot, open it and tap Start (VPN mode off, proxy running).';
    }
    notifyListeners();
    return _status;
  }

  /// Throws unless Tor is currently reachable. Call before any network I/O.
  Future<void> requireReady() async {
    if (!await _probeSocks()) {
      _status = TorStatus.notAvailable;
      notifyListeners();
      throw const TorBlockedException();
    }
  }

  String get orbotPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=org.torproject.android';

  String get orbotIntentAction => 'org.torproject.android.intent.action.START';
}

class TorBlockedException implements Exception {
  const TorBlockedException();
  @override
  String toString() => 'Blocked: Tor is required and is not running.';
}

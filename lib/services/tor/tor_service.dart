import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import 'tor_http_client.dart';

enum TorStatus { unknown, checking, ready, notAvailable }

/// Tor gate — FAIL-CLOSED. There is no "continue without Tor" path.
///
/// Ready means BOTH:
///   1. Orbot SOCKS port 127.0.0.1:9050 accepts a TCP connection, and
///   2. check.torproject.org (fetched THROUGH that SOCKS port) reports IsTor=true.
/// Step 2 is what proves traffic actually exits via Tor, not just that a port is open.
/// A positive result is cached for [_verifyTtl]; any failure blocks.
class TorService extends ChangeNotifier {
  TorService._();
  static final TorService instance = TorService._();

  static const Duration _verifyTtl = Duration(minutes: 5);

  TorStatus _status = TorStatus.unknown;
  String _lastError = '';
  DateTime? _verifiedAt;

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

  /// Fetches the Tor Project check endpoint through the SOCKS proxy.
  Future<bool> _verifyExitIsTor() async {
    final client = TorHttpClient.create(timeout: const Duration(seconds: 15));
    try {
      final resp = await client
          .get(Uri.parse(AppConstants.torCheckUrl))
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['IsTor'] == true;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<bool> _fullCheck() async {
    if (!await _probeSocks()) {
      _lastError =
          'Orbot SOCKS proxy not found at ${AppConstants.torSocksHost}:${AppConstants.torSocksPort}. '
          'Install Orbot, open it and tap Start (VPN mode off, proxy running).';
      return false;
    }
    if (!await _verifyExitIsTor()) {
      _lastError =
          'Orbot is running but traffic is not confirmed to exit via Tor '
          '(check.torproject.org did not return IsTor=true). Wait for Orbot to '
          'finish connecting, then tap Retry.';
      return false;
    }
    _lastError = '';
    _verifiedAt = DateTime.now();
    return true;
  }

  Future<TorStatus> check() async {
    _status = TorStatus.checking;
    _verifiedAt = null;
    notifyListeners();

    _status = await _fullCheck() ? TorStatus.ready : TorStatus.notAvailable;
    notifyListeners();
    return _status;
  }

  /// Throws unless Tor is ready. Called before any network I/O.
  /// Uses the cached verification if it is fresh, otherwise re-verifies.
  Future<void> requireReady() async {
    final fresh = _verifiedAt != null &&
        DateTime.now().difference(_verifiedAt!) < _verifyTtl;
    if (fresh && _status == TorStatus.ready) return;

    final ok = await _fullCheck();
    _status = ok ? TorStatus.ready : TorStatus.notAvailable;
    notifyListeners();
    if (!ok) throw const TorBlockedException();
  }

  String get orbotPlayStoreUrl =>
      'https://play.google.com/store/apps/details?id=org.torproject.android';

  String get orbotIntentAction => 'org.torproject.android.intent.action.START';
}

class TorBlockedException implements Exception {
  const TorBlockedException();
  @override
  String toString() => 'Blocked: Tor is required and is not verified.';
}

import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:socks5_proxy/socks_client.dart';

import '../../core/constants/app_constants.dart';

/// Thrown when a request is attempted while Tor is not reachable.
/// Fail-closed: there is NO direct-connection fallback.
class TorUnavailableException implements Exception {
  const TorUnavailableException([this.message = 'Tor (Orbot SOCKS) not reachable']);
  final String message;
  @override
  String toString() => 'TorUnavailableException: $message';
}

/// Builds http.Clients whose every connection goes through Orbot's SOCKS5 port.
/// Dart's HttpClient ignores the system proxy, so routing is set explicitly.
class TorHttpClient {
  TorHttpClient._();

  static http.Client create({Duration timeout = const Duration(seconds: 30)}) {
    final io = HttpClient()
      ..connectionTimeout = timeout
      ..idleTimeout = const Duration(seconds: 10);
    SocksTCPClient.assignToHttpClient(io, <ProxySettings>[
      ProxySettings(
        InternetAddress(AppConstants.torSocksHost),
        AppConstants.torSocksPort,
      ),
    ]);
    return IOClient(io);
  }
}

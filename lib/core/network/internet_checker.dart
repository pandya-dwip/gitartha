import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Answers "can the app reach its server right now?".
abstract interface class InternetChecker {
  Future<bool> hasInternet();
}

/// Opens (and immediately closes) a TCP connection to the app's own server.
///
/// This tests what actually matters (reaching Supabase), not merely whether
/// Wi-Fi or mobile data is switched on, so a captive portal or a network
/// without internet counts as offline. No package or permission beyond
/// INTERNET is needed.
class SocketInternetChecker implements InternetChecker {
  const SocketInternetChecker({
    required this.host,
    this.port = 443,
    this.timeout = const Duration(seconds: 4),
  });

  final String host;
  final int port;
  final Duration timeout;

  @override
  Future<bool> hasInternet() async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on Object {
      return false; // SocketException, timeout, DNS failure…
    }
  }
}

/// Opens the system's network settings (Android only: iOS does not allow
/// apps to open Wi-Fi settings directly).
abstract final class NetworkSettings {
  static const MethodChannel _channel = MethodChannel('gitartha/network');

  static bool get canOpen =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Returns false if the settings screen could not be opened.
  static Future<bool> open() async {
    if (!canOpen) return false;
    try {
      return await _channel.invokeMethod<bool>('openNetworkSettings') ?? false;
    } on Object {
      return false;
    }
  }
}

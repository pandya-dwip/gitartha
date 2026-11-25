import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Answers "can the app reach its server right now?".
abstract interface class InternetChecker {
  Future<bool> hasInternet();
}

/// "Online" means the device is on a network: Wi-Fi, mobile data or
/// ethernet. The "no internet" prompt is only for a phone with no network
/// at all; when the network is there but the server is briefly slow or
/// unreachable, the screens that need it show their own errors instead of
/// blocking the whole app.
///
/// If the device's network interfaces cannot be read, it falls back to
/// opening (and immediately closing) a TCP connection to the app's server.
class DeviceInternetChecker implements InternetChecker {
  const DeviceInternetChecker({
    required this.host,
    this.port = 443,
    this.timeout = const Duration(seconds: 4),
    this.onNetwork = hasNetworkConnection,
  });

  final String host;
  final int port;
  final Duration timeout;

  /// Whether the device is on a network (replaceable in tests).
  final Future<bool> Function() onNetwork;

  @override
  Future<bool> hasInternet() async =>
      await onNetwork() || await _reachesServer();

  Future<bool> _reachesServer() async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } on Object {
      return false; // SocketException, timeout, DNS failure…
    }
  }

  /// True when Wi-Fi, mobile data or ethernet has an address. Loopback and
  /// link-local-only interfaces (present even in airplane mode) don't count.
  static Future<bool> hasNetworkConnection() async {
    try {
      final interfaces = await NetworkInterface.list();
      return interfaces.any((i) => i.addresses.isNotEmpty);
    } on Object {
      return false;
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

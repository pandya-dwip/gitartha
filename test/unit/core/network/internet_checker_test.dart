import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitartha/core/network/internet_checker.dart';

void main() {
  // A port nothing listens on: the server check alone would fail.
  Future<int> closedPort() async {
    final s = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = s.port;
    await s.close();
    return port;
  }

  test('on Wi-Fi / mobile data counts as online, even if the server is '
      'unreachable', () async {
    final checker = DeviceInternetChecker(
      host: '127.0.0.1',
      port: await closedPort(),
      onNetwork: () async => true,
    );
    expect(await checker.hasInternet(), isTrue);
  });

  test('no network and no server is offline', () async {
    final checker = DeviceInternetChecker(
      host: '127.0.0.1',
      port: await closedPort(),
      onNetwork: () async => false,
    );
    expect(await checker.hasInternet(), isFalse);
  });

  test('falls back to reaching the server', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final checker = DeviceInternetChecker(
      host: '127.0.0.1',
      port: server.port,
      onNetwork: () async => false,
    );
    expect(await checker.hasInternet(), isTrue);
  });
}

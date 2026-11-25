import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config_provider.dart';
import '../../../../core/network/internet_checker.dart';
import '../../../authentication/presentation/providers/member_access_provider.dart';
import '../../../synchronization/presentation/providers/content_sync_provider.dart';

/// How the app checks connectivity: is the device on a network (falling
/// back to reaching the configured Supabase host). Null when no backend is
/// configured (development), which turns the network prompt off. Tests override this with a fake.
final internetCheckerProvider = Provider<InternetChecker?>((ref) {
  final supabase = ref.watch(appConfigProvider).supabase;
  if (supabase == null) return null;
  final uri = Uri.parse(supabase.url);
  return DeviceInternetChecker(
    host: uri.host,
    port: uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443),
  );
});

enum NetworkStatus { unknown, online, offline }

@immutable
class NetworkState {
  const NetworkState({
    this.status = NetworkStatus.unknown,
    this.checking = false,
  });

  final NetworkStatus status;

  /// A check is in progress (shown on the retry button).
  final bool checking;

  bool get isOffline => status == NetworkStatus.offline;

  NetworkState copyWith({NetworkStatus? status, bool? checking}) =>
      NetworkState(
        status: status ?? this.status,
        checking: checking ?? this.checking,
      );

  @override
  bool operator ==(Object other) =>
      other is NetworkState &&
      other.status == status &&
      other.checking == checking;

  @override
  int get hashCode => Object.hash(status, checking);
}

/// Whether the app can reach its server.
///
/// Checks when the app opens and whenever it returns to the foreground.
/// While offline it re-checks every [pollInterval], so the prompt closes by
/// itself as soon as the network is back, and then retries what needed the
/// network: the membership check and content sync.
class NetworkStatusController extends Notifier<NetworkState> {
  static const Duration pollInterval = Duration(seconds: 3);

  Timer? _poll;
  AppLifecycleListener? _lifecycle;

  @override
  NetworkState build() {
    final checker = ref.watch(internetCheckerProvider);
    if (checker == null) {
      return const NetworkState(status: NetworkStatus.online);
    }
    _lifecycle = AppLifecycleListener(onResume: check);
    ref.onDispose(() {
      _poll?.cancel();
      _lifecycle?.dispose();
    });
    scheduleMicrotask(check);
    return const NetworkState();
  }

  /// Checks now (the "Try again" button). Safe to call repeatedly.
  Future<void> check() async {
    final checker = ref.read(internetCheckerProvider);
    if (!ref.mounted || checker == null || state.checking) return;
    state = state.copyWith(checking: true);
    final online = await checker.hasInternet();
    if (!ref.mounted) return;
    final wasOffline = state.isOffline;
    state = NetworkState(
      status: online ? NetworkStatus.online : NetworkStatus.offline,
    );
    if (online) {
      _poll?.cancel();
      _poll = null;
      if (wasOffline) _onReconnected();
    } else {
      _poll ??= Timer.periodic(pollInterval, (_) => check());
    }
  }

  void _onReconnected() {
    // The membership check failed while offline: ask again.
    if (ref.read(authStatusProvider) == AuthStatus.membershipError) {
      ref.invalidate(memberAccessProvider);
    }
    unawaited(ref.read(contentSyncProvider.notifier).onAppResumed());
  }
}

final networkStatusProvider =
    NotifierProvider<NetworkStatusController, NetworkState>(
      NetworkStatusController.new,
    );

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/local/local_database_providers.dart';
import '../../../authentication/presentation/providers/auth_state_provider.dart';
import '../../../authentication/presentation/providers/member_access_provider.dart';
import '../../data/content_remote_datasource.dart';
import '../../data/content_sync_service.dart';
import '../../domain/sync_result.dart';

/// Null when there is no backend. Tests override it with a fake.
final contentRemoteDataSourceProvider = Provider<ContentRemoteDataSource?>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseContentDataSource(client);
});

final syncConfigProvider = Provider<SyncConfig>((ref) => const SyncConfig());

final contentSyncServiceProvider = Provider<ContentSyncService?>((ref) {
  final remote = ref.watch(contentRemoteDataSourceProvider);
  if (remote == null) return null;
  return ContentSyncService(
    database: ref.watch(appDatabaseProvider),
    remote: remote,
    config: ref.watch(syncConfigProvider),
  );
});

/// What the UI needs to know about content sync.
@immutable
class ContentSyncState {
  const ContentSyncState({
    this.status = SyncStatus.idle,
    this.isRunning = false,
    this.lastSuccessfulSyncAt,
    this.lastResult,
  });

  final SyncStatus status;
  final bool isRunning;

  /// Device time of the last successful sync (persisted), or null if this
  /// device has never synced.
  final DateTime? lastSuccessfulSyncAt;

  /// Counts and failure of the latest attempt in this app run.
  final SyncResult? lastResult;

  /// Safe, user-readable description of the latest failure.
  String? get message => lastResult?.message;

  ContentSyncState copyWith({
    SyncStatus? status,
    bool? isRunning,
    DateTime? lastSuccessfulSyncAt,
    SyncResult? lastResult,
  }) => ContentSyncState(
    status: status ?? this.status,
    isRunning: isRunning ?? this.isRunning,
    lastSuccessfulSyncAt: lastSuccessfulSyncAt ?? this.lastSuccessfulSyncAt,
    lastResult: lastResult ?? this.lastResult,
  );
}

/// Triggers and tracks shared-content sync.
///
/// * **Automatic:** when the user becomes an active member (restored
///   session at startup, or sign-in) and on [onAppResumed]; skipped while a
///   sync runs or when the last success is newer than
///   [SyncConfig.autoSyncMinInterval].
/// * **Manual:** [syncContentManually], always attempted (joins a running
///   sync instead of starting a second one).
/// * Both read-only members and editors sync: reading needs membership, not the
///   editing permission.
/// * Signing out, losing membership or switching user cancels a running
///   sync before anything is applied. The cache and personal data are never
///   cleared.
///
/// Reading screens never call this; they watch the SQLite providers
/// (`localChaptersProvider` …), which update when sync commits.
class ContentSyncController extends Notifier<ContentSyncState> {
  @override
  ContentSyncState build() {
    ref.listen<AuthStatus>(authStatusProvider, (previous, next) {
      if (next.isMember && previous?.isMember != true) {
        // After build; state can't change while building.
        scheduleMicrotask(_autoSync);
      }
    }, fireImmediately: true);
    scheduleMicrotask(_loadPersisted);
    return const ContentSyncState();
  }

  /// For a future "sync now" control. Returns the structured result.
  Future<SyncResult> syncContentManually() => _sync();

  /// Call when the app returns to the foreground.
  Future<void> onAppResumed() => _autoSync();

  Future<void> _loadPersisted() async {
    final service = ref.read(contentSyncServiceProvider);
    if (service == null) return;
    try {
      final meta = await service.readMetadata();
      if (!ref.mounted || meta.lastSuccessfulAt == null) return;
      state = state.copyWith(lastSuccessfulSyncAt: meta.lastSuccessfulAt);
    } on Object catch (e) {
      debugPrint('Could not read sync metadata (${e.runtimeType}).');
    }
  }

  Future<void> _autoSync() async {
    if (!ref.mounted || !ref.read(authStatusProvider).isMember) return;
    final service = ref.read(contentSyncServiceProvider);
    if (service == null || service.isRunning) return;
    final DateTime? last;
    try {
      last = (await service.readMetadata()).lastSuccessfulAt;
    } on Object catch (e) {
      debugPrint('Could not read sync metadata (${e.runtimeType}).');
      return;
    }
    if (!ref.mounted) return;
    final now = ref.read(appDatabaseProvider).now();
    final minInterval = ref.read(syncConfigProvider).autoSyncMinInterval;
    if (last != null && now.difference(last) < minInterval) return;
    await _sync();
  }

  Future<SyncResult> _sync() async {
    final blocked = _blockedReason();
    final service = ref.read(contentSyncServiceProvider);
    if (blocked != null || service == null) {
      final result = SyncResult.failed(blocked ?? SyncFailureKind.offline);
      state = state.copyWith(status: result.status, lastResult: result);
      return result;
    }

    final userId = ref.read(currentUserProvider)?.id;
    bool cancelled() =>
        !ref.mounted ||
        !ref.read(authStatusProvider).isMember ||
        ref.read(currentUserProvider)?.id != userId;

    state = state.copyWith(status: SyncStatus.syncing, isRunning: true);
    final result = await service.sync(isCancelled: cancelled);
    if (!ref.mounted) return result;

    state = ContentSyncState(
      status: result.failure == SyncFailureKind.cancelled
          ? (_blockedReason()?.status ?? SyncStatus.failed)
          : result.status,
      isRunning: service.isRunning,
      lastSuccessfulSyncAt: result.succeeded
          ? result.finishedAt
          : state.lastSuccessfulSyncAt,
      lastResult: result,
    );
    return result;
  }

  /// Why the current user may not sync, or null if they may.
  SyncFailureKind? _blockedReason() => switch (ref.read(authStatusProvider)) {
    AuthStatus.readOnly || AuthStatus.editor => null,
    AuthStatus.backendUnavailable => SyncFailureKind.offline,
    AuthStatus.signedOut => SyncFailureKind.unauthenticated,
    AuthStatus.passwordRecovery ||
    AuthStatus.loadingMembership ||
    AuthStatus.membershipMissing ||
    AuthStatus.membershipError => SyncFailureKind.membershipUnavailable,
  };
}

final contentSyncProvider =
    NotifierProvider<ContentSyncController, ContentSyncState>(
      ContentSyncController.new,
    );

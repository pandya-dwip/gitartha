import 'dart:async';

import 'package:gitartha/features/authentication/domain/entities/app_user.dart';
import 'package:gitartha/features/authentication/domain/entities/auth_failure.dart';
import 'package:gitartha/features/authentication/domain/entities/member_access.dart';
import 'package:gitartha/features/authentication/domain/repositories/auth_repository.dart';

const reader = AppUser(
  id: '00000000-0000-4000-8000-00000000a001',
  email: 'reader@example.test',
);
const editor = AppUser(
  id: '00000000-0000-4000-8000-00000000a002',
  email: 'editor@example.test',
);

MemberAccess membership(AppUser user, {required bool isAccessible}) =>
    MemberAccess(
      userId: user.id,
      isAccessible: isAccessible,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

/// In-memory [AuthRepository] that behaves like Supabase from the app's
/// point of view: a session, an auth event stream and a membership table.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AppUser? restoredUser,
    Map<String, String>? passwords,
    Map<String, MemberAccess>? members,
  }) : _user = restoredUser,
       passwords =
           passwords ??
           {reader.email!: 'pw-reader', editor.email!: 'pw-editor'},
       members = members ?? {};

  AppUser? _user;
  final Map<String, String> passwords;

  /// Server-side `app_members`, keyed by user id. Tests change it to model
  /// the owner granting or revoking permission.
  final Map<String, MemberAccess> members;

  /// When set, the next operations of that kind fail with it.
  AuthFailure? signInFailure;
  AuthFailure? signOutFailure;
  AuthFailure? updatePasswordFailure;
  MembershipFailure? membershipFailure;

  /// Hold sign-in / membership lookups until completed (to observe loading).
  Completer<void>? signInGate;
  Completer<void>? membershipGate;

  int signInCalls = 0;
  int membershipCalls = 0;
  int listenCount = 0;
  final List<String> resetRequests = [];
  final List<String> passwordUpdates = [];

  final _changes = StreamController<AuthChange>.broadcast();

  void emit(AuthChange change) {
    _user = change.user;
    _changes.add(change);
  }

  void emitError(Object error) => _changes.addError(error);

  /// Simulates the session ending on the server (expired/revoked refresh).
  void expireSession() => emit(const AuthChange(user: null));

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AuthChange> get authChanges {
    listenCount++;
    return _changes.stream;
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    await signInGate?.future;
    final failure = signInFailure;
    if (failure != null) throw failure;
    if (passwords[email.trim()] != password) {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    }
    final user = [reader, editor].firstWhere((u) => u.email == email.trim());
    emit(AuthChange(user: user));
    return user;
  }

  @override
  Future<void> signOut() async {
    final failure = signOutFailure;
    if (failure != null) throw failure;
    emit(const AuthChange(user: null));
  }

  @override
  Future<MemberAccess?> fetchOwnMembership() async {
    membershipCalls++;
    await membershipGate?.future;
    final failure = membershipFailure;
    if (failure != null) throw failure;
    final user = _user;
    if (user == null) {
      throw const MembershipFailure(MembershipFailureKind.accessDenied);
    }
    return members[user.id];
  }

  @override
  Future<void> requestPasswordReset(String email) async =>
      resetRequests.add(email);

  @override
  Future<void> updatePassword(String newPassword) async {
    final failure = updatePasswordFailure;
    if (failure != null) throw failure;
    passwordUpdates.add(newPassword);
    emit(AuthChange(user: _user));
  }
}

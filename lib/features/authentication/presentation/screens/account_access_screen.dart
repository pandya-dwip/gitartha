import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_failure.dart';
import '../providers/auth_state_provider.dart';
import '../providers/member_access_provider.dart';
import '../widgets/auth_widgets.dart';

/// Signed in, but not (confirmed as) a member: either there is no
/// membership, or it could not be checked. Offers retry and sign-out.
class AccountAccessScreen extends ConsumerStatefulWidget {
  const AccountAccessScreen({super.key});

  @override
  ConsumerState<AccountAccessScreen> createState() =>
      _AccountAccessScreenState();
}

class _AccountAccessScreenState extends ConsumerState<AccountAccessScreen> {
  String? _signOutError;

  Future<void> _signOut() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _signOutError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final missing =
        ref.watch(authStatusProvider) == AuthStatus.membershipMissing;
    return AuthPage(
      title: missing ? 'Access unavailable' : 'Could not check access',
      children: [
        Text(
          missing
              ? 'This account is not currently authorized to access '
                    'Gitartha. If you were invited, contact the project owner.'
              : MembershipFailure.message,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_signOutError != null) AuthErrorText(_signOutError!),
        FilledButton(
          onPressed: () => ref.invalidate(memberAccessProvider),
          child: const Text('Try again'),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: _signOut, child: const Text('Sign out')),
      ],
    );
  }
}

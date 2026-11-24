import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/auth_validators.dart';
import '../../domain/entities/auth_failure.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/auth_widgets.dart';

/// Requests a password-reset email. The link opens the app, which then asks
/// for a new password (see ResetPasswordScreen).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _busy = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .requestPasswordReset(_email.text);
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Reset password',
      children: [
        if (_sent)
          // Supabase does not reveal whether the address has an account.
          const Text(
            'If an account exists for that email, a reset link is on its '
            'way. Open it on this device to choose a new password.',
          )
        else ...[
          if (_error != null) AuthErrorText(_error!),
          Form(
            key: _form,
            child: TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              onFieldSubmitted: (_) => _submit(),
              validator: AuthValidators.email,
              enabled: !_busy,
            ),
          ),
          const SizedBox(height: 24),
          BusyButton(label: 'Send reset link', busy: _busy, onPressed: _submit),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : () => context.go(AppRoutes.login),
          child: const Text('Back to sign in'),
        ),
      ],
    );
  }
}

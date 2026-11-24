import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/auth_validators.dart';
import '../../domain/entities/auth_failure.dart';
import '../providers/auth_state_provider.dart';
import '../widgets/auth_widgets.dart';

/// Shown after the user opens a password-reset link: they are signed in
/// with a recovery session and must choose a new password.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updatePassword(_password.text);
      // Only reached once Supabase has confirmed the change.
      messenger.showSnackBar(
        const SnackBar(content: Text('Your password has been changed.')),
      );
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    try {
      await ref.read(authControllerProvider.notifier).signOut();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibility = IconButton(
      tooltip: _obscure ? 'Show password' : 'Hide password',
      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return AuthPage(
      title: 'Choose a new password',
      children: [
        if (_error != null) AuthErrorText(_error!),
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _password,
                decoration: InputDecoration(
                  labelText: 'New password',
                  suffixIcon: visibility,
                ),
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.newPassword,
                enabled: !_busy,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirm,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                obscureText: _obscure,
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    v == _password.text ? null : 'The passwords do not match.',
                enabled: !_busy,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        BusyButton(label: 'Save password', busy: _busy, onPressed: _submit),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy ? null : _cancel,
          child: const Text('Cancel and sign out'),
        ),
      ],
    );
  }
}

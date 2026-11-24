import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../domain/auth_validators.dart';
import '../../domain/entities/auth_failure.dart';
import '../providers/auth_state_provider.dart';
import '../providers/member_access_provider.dart';
import '../widgets/auth_widgets.dart';

/// Email + password sign-in for invited members. There is intentionally no
/// sign-up: accounts are created by invitation only.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
          .signIn(email: _email.text, password: _password.text);
      // The router moves on once the session and membership are known.
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available =
        ref.watch(authStatusProvider) != AuthStatus.backendUnavailable;

    return AuthPage(
      title: 'Sign in',
      children: [
        if (!available)
          AuthErrorText(AuthFailureKind.backendUnavailable.message)
        else if (_error != null)
          AuthErrorText(_error!),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.email,
                  enabled: !_busy,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: AuthValidators.password,
                  enabled: !_busy,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        BusyButton(
          label: 'Sign in',
          busy: _busy,
          onPressed: available ? _submit : null,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy || !available
              ? null
              : () => context.go(AppRoutes.forgotPassword),
          child: const Text('Forgot password?'),
        ),
      ],
    );
  }
}

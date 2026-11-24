import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/auth_validators.dart';
import '../../domain/entities/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_state_provider.dart';
import '../providers/member_access_provider.dart';
import '../widgets/auth_widgets.dart';

/// Account registration (Supabase Auth). The new account automatically
/// receives a read-only membership from the database; editing permission is
/// still granted only by the project owner.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  /// Set when Supabase asks the user to confirm their email first.
  String? _confirmationSentTo;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final outcome = await ref
          .read(authControllerProvider.notifier)
          .signUp(
            fullName: _name.text,
            email: _email.text,
            password: _password.text,
          );
      // signedIn: the router moves on by itself.
      if (outcome == SignUpOutcome.confirmEmail && mounted) {
        setState(() => _confirmationSentTo = _email.text.trim());
      }
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
    final sentTo = _confirmationSentTo;

    return AuthPage(
      title: sentTo == null ? 'Begin your journey' : 'Check your email',
      subtitle: sentTo == null
          ? 'Create your Gitartha account'
          : 'One last step to activate your account',
      footer: AuthFooterLink(
        prompt: sentTo == null ? 'Already have an account?' : 'Confirmed it?',
        action: 'Sign in',
        onPressed: _busy ? null : () => context.go(AppRoutes.login),
      ),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: sentTo == null
              ? _buildForm(context, available)
              : _ConfirmationSent(email: sentTo),
        ),
      ],
    );
  }

  Widget _buildForm(BuildContext context, bool available) {
    final c = context.colors;
    final t = context.text;
    final visibility = IconButton(
      tooltip: _obscure ? 'Show password' : 'Hide password',
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );

    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedAuthError(
          available ? _error : AuthFailureKind.backendUnavailable.message,
        ),
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.name],
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.fullName,
                  enabled: !_busy,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
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
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: visibility,
                  ),
                  obscureText: _obscure,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                  validator: AuthValidators.newPassword,
                  enabled: !_busy,
                ),
                _StrengthMeter(password: _password.text),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirm,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => v == _password.text
                      ? null
                      : 'The passwords do not match.',
                  enabled: !_busy,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BusyButton(
          label: 'Create account',
          busy: _busy,
          onPressed: available ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.gutter),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 16, color: c.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Your reflections, notes and bookmarks stay private on your '
                'device.',
                style: t.ui.copyWith(fontSize: 12, color: c.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Four-segment password strength hint (Supabase enforces the real policy).
class _StrengthMeter extends StatelessWidget {
  const _StrengthMeter({required this.password});

  final String password;

  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final score = AuthValidators.passwordStrength(password);
    final color = switch (score) {
      0 || 1 => Theme.of(context).colorScheme.error,
      2 => c.textSecondary,
      _ => c.accent,
    };
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: password.isEmpty ? 0 : 1,
      child: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            for (var i = 1; i <= 4; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= score ? color : c.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
            const SizedBox(width: 4),
            SizedBox(
              width: 48,
              child: Text(
                _labels[score],
                style: context.text.ui.copyWith(fontSize: 11, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationSent extends StatelessWidget {
  const _ConfirmationSent({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.text;
    return Column(
      key: const ValueKey('sent'),
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.accentSoft,
          ),
          child: Icon(
            Icons.mark_email_read_outlined,
            size: 30,
            color: c.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'We have sent a confirmation link to',
          textAlign: TextAlign.center,
          style: t.commentary.copyWith(fontSize: 14, color: c.textSecondary),
        ),
        Text(
          email,
          textAlign: TextAlign.center,
          style: t.ui.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Open it on this phone to activate your account. If it does not '
          'arrive in a few minutes, check your spam folder, or try signing '
          'in: the address may already be registered.',
          textAlign: TextAlign.center,
          style: t.commentary.copyWith(fontSize: 13, color: c.textSecondary),
        ),
      ],
    );
  }
}

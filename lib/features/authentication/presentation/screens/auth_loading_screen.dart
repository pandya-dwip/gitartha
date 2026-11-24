import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/gitartha_splash.dart';

/// Shown while the signed-in user's membership is being checked.
///
/// It is the same splash the app starts with (logo + name, no entrance
/// replay), so going from app start to "checking access" shows no change:
/// one continuous splash. Only if the check takes a while does a short hint
/// fade in below the name (in the splash's fixed footer area, so nothing
/// moves).
class AuthLoadingScreen extends StatefulWidget {
  const AuthLoadingScreen({super.key});

  /// How long the check may take before the hint appears.
  static const hintDelay = Duration(milliseconds: 1200);

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> {
  Timer? _timer;
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(AuthLoadingScreen.hintDelay, () {
      if (mounted) setState(() => _showHint = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Checking your access',
    liveRegion: true,
    child: GitarthaSplash(
      animateIn: false,
      footer: _showHint
          ? Text(
              'Checking your access…',
              key: const ValueKey('hint'),
              style: context.text.ui.copyWith(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            )
          : null,
    ),
  );
}

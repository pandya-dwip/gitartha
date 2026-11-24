import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Gitartha logo (Krishna guiding Arjuna) as a round medallion with the
/// soft gold halo. Used on the startup and authentication screens; the same
/// artwork is the launcher icon.
class GitarthaLogo extends StatelessWidget {
  const GitarthaLogo({super.key, this.size = 104});

  final double size;

  static const asset = 'assets/images/branding/gitartha_logo.png';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Gitartha logo',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: c.halo),
        child: ClipOval(
          child: Image.asset(
            asset,
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

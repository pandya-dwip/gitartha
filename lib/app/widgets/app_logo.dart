import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The Gitartha logo (Krishna guiding Arjuna) as a round medallion with the
/// soft gold halo. Used on the splash and authentication screens; the same
/// artwork is the launcher icon.
class GitarthaLogo extends StatelessWidget {
  const GitarthaLogo({super.key, this.size = 104});

  final double size;

  static const asset = 'assets/images/branding/gitartha_logo.png';

  /// The image provider for a logo of [size] on this screen: decoded at the
  /// pixels actually shown instead of the full 512 px source, which saves
  /// memory and decode time. Use it to precache the exact same image.
  static ImageProvider provider(BuildContext context, double size) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;
    return ResizeImage(
      const AssetImage(asset),
      width: (size * dpr).round(),
      height: (size * dpr).round(),
    );
  }

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
          child: Image(
            image: provider(context, size),
            width: size,
            height: size,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }
}

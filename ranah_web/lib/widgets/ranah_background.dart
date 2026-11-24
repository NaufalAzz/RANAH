import 'package:flutter/material.dart';

import '../theme/ranah_theme.dart';

class RanahBackground extends StatelessWidget {
  const RanahBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            RanahColors.backgroundStart,
            RanahColors.backgroundMiddle,
            RanahColors.backgroundEnd,
          ],
          stops: [0, .55, 1],
        ),
      ),
      child: child,
    );
  }
}

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
      child: Stack(
        children: [
          const Positioned(
            left: -104,
            top: 0,
            child: _BackgroundRing(size: 238, opacity: .09),
          ),
          const Positioned(
            left: 68,
            top: 280,
            child: _BackgroundRing(size: 176, opacity: .055),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _BackgroundRing extends StatelessWidget {
  const _BackgroundRing({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 23,
        ),
      ),
    ),
  );
}

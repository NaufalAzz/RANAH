import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Ink, sea blue and glacier blue shared by information surfaces on both clients.
abstract final class RanahPalette {
  static const deep = Color(0xFF102E46);
  static const panel = Color(0xFF153D58);
  static const line = Color(0xFF486C81);
  static const text = Color(0xFFF2F8FA);
  static const secondary = Color(0xFFC3D7E2);
  static const highlight = Color(0xFF96E0DE);
  static const warning = Color(0xFFFFB6A6);
}

/// Contours at the edge of a header leave its title and controls unobstructed.
class RanahContours extends CustomPainter {
  const RanahContours();
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final width = math.min(320.0, size.width * .42);
    final ink = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..shader = const LinearGradient(
        colors: [Color(0x008CDACF), Color(0x358CDACF)],
      ).createShader(Rect.fromLTWH(-width, 0, width, size.height));
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width + width * .12, size.height * .35);
    for (var ring = 1; ring <= 11; ring++) {
      final path = Path();
      for (var i = 0; i <= 96; i++) {
        final t = math.pi * 2 * i / 96;
        final radius =
            (8 + ring * width / 10) *
            (1 + .08 * math.sin(3 * t + .3) + .055 * math.cos(5 * t - .5));
        final x = radius * math.cos(t);
        final y = radius * math.sin(t) * .62 - .16 * x;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path..close(), ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(RanahContours oldDelegate) => false;
}

/// An editorial category symbol for articles whose publisher supplied no photo.
class RanahNewsCover extends StatelessWidget {
  const RanahNewsCover({required this.category, super.key});

  final String category;

  @override
  Widget build(BuildContext context) {
    final normalized = category.toLowerCase();
    final (symbol, tint) = switch (normalized) {
      _ when normalized.contains('banjir') => (
        Icons.water_rounded,
        const Color(0xFF296373),
      ),
      _ when normalized.contains('longsor') => (
        Icons.terrain_outlined,
        const Color(0xFF455F60),
      ),
      _ when normalized.contains('erupsi') || normalized.contains('gunung') => (
        Icons.landscape_outlined,
        const Color(0xFF51526D),
      ),
      _ when normalized.contains('gempa') => (
        Icons.graphic_eq_rounded,
        const Color(0xFF3C566D),
      ),
      _ when normalized.contains('cuaca') => (
        Icons.cloud_outlined,
        const Color(0xFF355C74),
      ),
      _ => (Icons.article_outlined, RanahPalette.panel),
    };
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [RanahPalette.deep, tint]),
        ),
        child: CustomPaint(
          painter: const RanahContours(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final extent = constraints.biggest.shortestSide;
              return Center(
                child: Icon(
                  symbol,
                  size: (extent * .45).clamp(21.0, 68.0),
                  color: const Color(0xFFC8E1E6),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A short entrance for a newly opened page; the child keeps its own state.
class RanahPageReveal extends StatelessWidget {
  const RanahPageReveal({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: .70 + .30 * t,
        child: Transform.translate(
          offset: Offset(0, 7 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}

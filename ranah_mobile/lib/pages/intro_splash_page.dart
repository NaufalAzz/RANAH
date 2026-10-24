import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Automatic cinematic intro. Its mark is the same temporary symbol used by
/// BrandHeader; the repository does not contain an official logo asset.
class IntroSplashPage extends StatefulWidget {
  const IntroSplashPage({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<IntroSplashPage> createState() => _IntroSplashPageState();
}

class _IntroSplashPageState extends State<IntroSplashPage>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 3200);

  late final AnimationController _controller;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _nameProgress;
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;
  late final Timer _fallbackTimer;
  bool _hasFinished = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    _markOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.53, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(begin: 0.76, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.52, curve: Curves.easeOutBack),
      ),
    );
    _nameProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.43, 0.74, curve: Curves.easeOutCubic),
    );
    _taglineOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.65, 0.83, curve: Curves.easeOut),
    );
    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.65, 0.84, curve: Curves.easeOutCubic),
          ),
        );

    // Keep startup recoverable if the animation does not reach its final tick.
    _fallbackTimer = Timer(
      _duration + const Duration(milliseconds: 800),
      _finish,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _reduceMotion = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  void _finish() {
    if (!mounted || _hasFinished) return;
    _hasFinished = true;
    _fallbackTimer.cancel();
    widget.onFinished();
  }

  @override
  void dispose() {
    _fallbackTimer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        _reduceMotion || MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: const Color(0xFF071323),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final progress = reduceMotion ? 1.0 : _controller.value;
              final reveal = Curves.easeOutCubic.transform(
                ((progress - 0.02) / 0.22).clamp(0.0, 1.0),
              );
              final exit = reduceMotion
                  ? 0.0
                  : Curves.easeInOutCubic.transform(
                      ((progress - 0.83) / 0.17).clamp(0.0, 1.0),
                    );
              final compositionOpacity = 1 - exit * 0.12;
              final compositionScale = 1 + exit * 0.035;

              return Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF10052E),
                          Color(0xFF101B38),
                          Color(0xFF071323),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _VolcanicAtmospherePainter(
                        progress: progress,
                        reveal: reveal,
                      ),
                    ),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - AppSpacing.lg * 2,
                          maxWidth: 480,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: Opacity(
                            opacity: compositionOpacity,
                            child: Transform.scale(
                              scale: compositionScale,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 224,
                                    height: 224,
                                    child: CustomPaint(
                                      painter: _PulseRingsPainter(
                                        progress: progress,
                                      ),
                                      child: Center(
                                        child: FadeTransition(
                                          opacity: reduceMotion
                                              ? const AlwaysStoppedAnimation(1)
                                              : _markOpacity,
                                          child: ScaleTransition(
                                            scale: reduceMotion
                                                ? const AlwaysStoppedAnimation(
                                                    1,
                                                  )
                                                : _markScale,
                                            child: _brandMark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Transform.scale(
                                    scale: reduceMotion
                                        ? 1
                                        : 0.78 + _nameProgress.value * 0.22,
                                    child: _IdentityTitle(progress: progress),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  FadeTransition(
                                    opacity: reduceMotion
                                        ? const AlwaysStoppedAnimation(1)
                                        : _taglineOpacity,
                                    child: SlideTransition(
                                      position: reduceMotion
                                          ? const AlwaysStoppedAnimation(
                                              Offset.zero,
                                            )
                                          : _taglineSlide,
                                      child: Text(
                                        'Informasi Gunung Api dan Mitigasi Bencana',
                                        textAlign: TextAlign.center,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.mutedOnDark,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget get _brandMark => Container(
    width: 88,
    height: 88,
    decoration: BoxDecoration(
      color: AppColors.brandTile,
      borderRadius: BorderRadius.circular(AppRadii.card),
      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      boxShadow: const [
        BoxShadow(color: Color(0x55211A70), blurRadius: 36, spreadRadius: 2),
      ],
    ),
    alignment: Alignment.center,
    child: const Icon(
      Icons.home_work_rounded,
      color: AppColors.onDark,
      size: 50,
    ),
  );
}

class _IdentityTitle extends StatelessWidget {
  const _IdentityTitle({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final flash = ((progress - 0.53) / 0.2).clamp(0.0, 1.0);
    final beamStart = -1.8 + flash * 3.6;
    final baseStyle = AppTypography.headline.copyWith(
      color: Colors.white,
      fontSize: 34,
      letterSpacing: 3,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Text('RANAH', textAlign: TextAlign.center, style: baseStyle),
        if (flash > 0 && flash < 1)
          Opacity(
            opacity: math.sin(flash * math.pi),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(beamStart, -1),
                end: Alignment(beamStart + 0.7, 1),
                colors: const [
                  Colors.transparent,
                  Color(0xFFE9DEFF),
                  Colors.transparent,
                ],
                stops: const [0.35, 0.5, 0.65],
              ).createShader(bounds),
              child: Text(
                'RANAH',
                textAlign: TextAlign.center,
                style: baseStyle,
              ),
            ),
          ),
      ],
    );
  }
}

class _VolcanicAtmospherePainter extends CustomPainter {
  const _VolcanicAtmospherePainter({
    required this.progress,
    required this.reveal,
  });

  final double progress;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.39);

    _drawGlow(canvas, center, w * 0.54, const Color(0xFF7139C9), 0.33);
    _drawGlow(
      canvas,
      Offset(w * 0.5, h * 0.67),
      w * 0.36,
      const Color(0xFFD65B36),
      0.12 * reveal,
    );
    _drawParticles(canvas, size);
    _drawFog(canvas, size);
    _drawMountains(canvas, size);
    _drawVentLight(canvas, size);
  }

  void _drawGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double alpha,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawParticles(Canvas canvas, Size size) {
    final paint = Paint();
    for (var index = 0; index < 24; index++) {
      final seed = index * 37;
      final x =
          ((seed % 101) / 100 + progress * (0.035 + index % 3 * 0.009)) % 1;
      final y = (0.12 + ((seed * 13) % 69) / 100 - progress * 0.045) % 0.82;
      final pulse = 0.55 + 0.45 * math.sin(progress * math.pi * 5 + index);
      final isEmber = index % 7 == 0;
      paint.color = (isEmber ? const Color(0xFFFFA16A) : Colors.white)
          .withValues(alpha: (isEmber ? 0.28 : 0.22) * pulse);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        isEmber ? 1.5 : 0.8 + (index % 3) * 0.25,
        paint,
      );
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9D91C5).withValues(alpha: 0.045)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final drift = math.sin(progress * math.pi * 2) * size.width * 0.045;
    for (var i = 0; i < 4; i++) {
      final x = size.width * (0.12 + i * 0.27) + (i.isEven ? drift : -drift);
      final y = size.height * (0.68 + (i % 2) * 0.045);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: size.width * 0.46,
          height: size.height * 0.045,
        ),
        paint,
      );
    }
  }

  void _drawMountains(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final slideUp = (1 - reveal) * h * 0.045;
    canvas.save();
    canvas.translate(0, slideUp);

    final farRidge = Path()
      ..moveTo(0, h * 0.72)
      ..lineTo(w * 0.17, h * 0.61)
      ..lineTo(w * 0.31, h * 0.71)
      ..lineTo(w * 0.47, h * 0.62)
      ..lineTo(w * 0.68, h * 0.72)
      ..lineTo(w * 0.84, h * 0.64)
      ..lineTo(w, h * 0.7)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(farRidge, Paint()..color = const Color(0xFF111A35));

    final mountain = Path()
      ..moveTo(0, h * 0.85)
      ..lineTo(w * 0.18, h * 0.77)
      ..lineTo(w * 0.33, h * 0.68)
      ..lineTo(w * 0.42, h * 0.63)
      ..lineTo(w * 0.465, h * 0.65)
      ..lineTo(w * 0.485, h * 0.665)
      ..lineTo(w * 0.515, h * 0.665)
      ..lineTo(w * 0.54, h * 0.645)
      ..lineTo(w * 0.59, h * 0.67)
      ..lineTo(w * 0.72, h * 0.77)
      ..lineTo(w, h * 0.84)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF17152E), Color(0xFF090F1C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, h * 0.62, w, h * 0.4)),
    );

    final ridge = Path()
      ..moveTo(w * 0.33, h * 0.68)
      ..lineTo(w * 0.42, h * 0.63)
      ..lineTo(w * 0.465, h * 0.65)
      ..moveTo(w * 0.54, h * 0.645)
      ..lineTo(w * 0.59, h * 0.67);
    canvas.drawPath(
      ridge,
      Paint()
        ..color = const Color(0xFF88759F).withValues(alpha: 0.25 * reveal)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.restore();
  }

  void _drawVentLight(Canvas canvas, Size size) {
    final point = Offset(size.width * 0.5, size.height * 0.662);
    _drawGlow(
      canvas,
      point,
      size.width * 0.11,
      const Color(0xFFFF784B),
      0.16 * reveal,
    );
    final paint = Paint()
      ..color = const Color(0xFFFFA16A).withValues(alpha: 0.32 * reveal)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(point.dx - size.width * 0.012, point.dy),
      Offset(point.dx, point.dy - size.height * 0.017),
      paint,
    );
    canvas.drawLine(
      Offset(point.dx, point.dy - size.height * 0.017),
      Offset(point.dx + size.width * 0.014, point.dy),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VolcanicAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.reveal != reveal;
}

class _PulseRingsPainter extends CustomPainter {
  const _PulseRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.shortestSide * 0.46;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    for (var index = 0; index < 3; index++) {
      final start = 0.27 + index * 0.13;
      final phase = ((progress - start) / 0.34).clamp(0.0, 1.0);
      if (phase <= 0 || phase >= 1) continue;
      paint.color = const Color(0xFFBCA6FF)
          .withValues(alpha: 0.23 * (1 - phase));
      canvas.drawCircle(center, maxRadius * (0.28 + phase * 0.72), paint);
    }

    final transition = ((progress - 0.83) / 0.17).clamp(0.0, 1.0);
    if (transition > 0) {
      paint.strokeWidth = 2;
      paint.color = Colors.white.withValues(alpha: 0.22 * (1 - transition));
      canvas.drawCircle(center, maxRadius * (0.25 + transition * 1.9), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulseRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

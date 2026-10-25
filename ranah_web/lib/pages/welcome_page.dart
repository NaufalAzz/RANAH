import 'dart:math' as math;

import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2800);

  late final AnimationController _controller;
  late final Animation<double> _markOpacity;
  late final Animation<double> _markScale;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _copyOpacity;
  bool _started = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finish();
      });
    _markOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.05, 0.42, curve: Curves.easeOut),
    );
    _markScale = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.62, curve: Curves.easeOut),
    );
    _copyOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.57, 0.82, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _controller.forward();
    }
  }

  void _finish() {
    if (!mounted || _finished) return;
    _finished = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071323),
      body: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;
            final markSize = (constraints.maxHeight * 0.19)
                .clamp(92.0, 132.0)
                .toDouble();
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
                    painter: _WelcomeAtmospherePainter(progress: progress),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 56)
                            .clamp(0.0, double.infinity)
                            .toDouble(),
                        maxWidth: 540,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: markSize * 1.8,
                              height: markSize * 1.8,
                              child: CustomPaint(
                                painter: _WelcomeRingsPainter(
                                  progress: progress,
                                ),
                                child: Center(
                                  child: FadeTransition(
                                    opacity: _markOpacity,
                                    child: ScaleTransition(
                                      scale: _markScale,
                                      child: Container(
                                        width: markSize,
                                        height: markSize,
                                        clipBehavior: Clip.antiAlias,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(22),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x66713CC6),
                                              blurRadius: 42,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Image.asset(
                                          'assets/images/brand_mark.png',
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            FadeTransition(
                              opacity: _titleOpacity,
                              child: const Text(
                                'RANAH',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  height: 1,
                                  letterSpacing: 5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            FadeTransition(
                              opacity: _copyOpacity,
                              child: const Column(
                                children: [
                                  Text(
                                    'Informasi Bencana dan Evakuasi',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFE6E2F5),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Informasi Gunung Api dan Mitigasi Bencana',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFBDB8D3),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: Center(
                    child: SizedBox(
                      width: 112,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.14),
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF9C86F4),
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
    );
  }
}

class _WelcomeAtmospherePainter extends CustomPainter {
  const _WelcomeAtmospherePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF633DB8).withValues(alpha: 0.2),
          const Color(0xFF633DB8).withValues(alpha: 0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.shortestSide * 0.52),
      );
    canvas.drawCircle(center, size.shortestSide * 0.52, glow);

    final ridge = Path()
      ..moveTo(0, size.height * 0.82)
      ..lineTo(size.width * 0.20, size.height * 0.70)
      ..lineTo(size.width * 0.36, size.height * 0.78)
      ..lineTo(size.width * 0.51, size.height * 0.64)
      ..lineTo(size.width * 0.70, size.height * 0.77)
      ..lineTo(size.width * 0.86, size.height * 0.69)
      ..lineTo(size.width, size.height * 0.78)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0x18121A35));

    final particles = Paint();
    for (var index = 0; index < 30; index++) {
      final seed = index * 41;
      final x = ((seed % 103) / 103 + progress * (0.012 + index % 3 * 0.006)) % 1;
      final y = 0.1 + ((seed * 17) % 75) / 100;
      final ember = index % 8 == 0;
      final pulse = 0.65 + 0.35 * math.sin(progress * math.pi * 4 + index);
      particles.color = (ember ? const Color(0xFFFFA16A) : Colors.white)
          .withValues(alpha: (ember ? 0.38 : 0.22) * pulse);
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        ember ? 1.7 : 0.9,
        particles,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeAtmospherePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WelcomeRingsPainter extends CustomPainter {
  const _WelcomeRingsPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var index = 0; index < 3; index++) {
      final phase = ((progress - 0.12 - index * 0.13) / 0.43).clamp(0.0, 1.0);
      if (phase <= 0 || phase >= 1) continue;
      paint.color = const Color(0xFFBCA6FF).withValues(
        alpha: 0.3 * (1 - phase),
      );
      canvas.drawCircle(
        center,
        size.shortestSide * (0.2 + phase * 0.29),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WelcomeRingsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ranah_visuals.dart';

class RanahIntro extends StatefulWidget {
  const RanahIntro({
    required this.onFinished,
    this.wideLayout = false,
    super.key,
  });

  final VoidCallback onFinished;
  final bool wideLayout;

  @override
  State<RanahIntro> createState() => _RanahIntroState();
}

class _RanahIntroState extends State<RanahIntro>
    with SingleTickerProviderStateMixin {
  late final _clock =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _finish();
        });
  late final _markOpacity = _clock.drive(
    CurveTween(curve: const Interval(0, .19, curve: Curves.easeOut)),
  );
  late final _markScale = Tween(begin: .68, end: 1.0)
      .chain(
        CurveTween(curve: const Interval(0, .39, curve: Curves.easeOutBack)),
      )
      .animate(_clock);
  late final _nameReveal = _clock.drive(
    CurveTween(curve: const Interval(.20, .58, curve: Curves.easeInOutCubic)),
  );
  late final _tagline = _clock.drive(
    CurveTween(curve: const Interval(.47, .74, curve: Curves.easeOutCubic)),
  );
  bool _finished = false;

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _clock.stop();
    widget.onFinished();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.stop();
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else if (_clock.isDismissed && !_finished) {
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = widget.wideLayout && MediaQuery.sizeOf(context).width >= 720;
    final markSize = wide ? 116.0 : 92.0;
    final mark = SizedBox.square(
      dimension: markSize * 1.72,
      child: CustomPaint(
        painter: _SignalRings(_clock),
        child: Center(
          child: FadeTransition(
            opacity: _markOpacity,
            child: ScaleTransition(
              scale: _markScale,
              child: Container(
                width: markSize,
                height: markSize,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF102E47),
                  borderRadius: BorderRadius.circular(markSize * .24),
                  border: Border.all(color: const Color(0xFF6295A6)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3D071723),
                      blurRadius: 22,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/brand_mark.png',
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: ClipRect(
            clipper: _WordmarkClipper(_nameReveal),
            child: Text(
              'RANAH',
              style: TextStyle(
                color: RanahPalette.text,
                fontSize: wide ? 64 : 48,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: wide ? 6 : 4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FadeTransition(
          opacity: _tagline,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .30),
              end: Offset.zero,
            ).animate(_tagline),
            child: Text(
              'Informasi Bencana dan Evakuasi',
              textAlign: wide ? TextAlign.start : TextAlign.center,
              style: const TextStyle(
                color: RanahPalette.secondary,
                fontSize: 16,
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D172F), Color(0xFF12374D), Color(0xFF165769)],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Align(
              alignment: Alignment.topCenter,
              child: FractionallySizedBox(
                widthFactor: 1,
                heightFactor: .29,
                child: RepaintBoundary(
                  child: CustomPaint(painter: RanahContours()),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(painter: _VolcanicLandscape(_clock)),
            ),
            SafeArea(
              minimum: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
              child: Center(
                child: SingleChildScrollView(
                  child: wide
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            mark,
                            const SizedBox(width: 12),
                            Flexible(child: identity),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [mark, identity],
                        ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: SafeArea(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: RanahPalette.secondary,
                  ),
                  onPressed: _finish,
                  child: const Text('Lewati'),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                minimum: const EdgeInsets.only(bottom: 22),
                child: ExcludeSemantics(
                  child: SizedBox(
                    width: wide ? 112 : 84,
                    child: AnimatedBuilder(
                      animation: _clock,
                      builder: (context, _) => LinearProgressIndicator(
                        value: _clock.value,
                        minHeight: 2,
                        borderRadius: BorderRadius.circular(2),
                        color: RanahPalette.highlight,
                        backgroundColor: const Color(0x33528190),
                        stopIndicatorRadius: 0,
                        trackGap: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the final text width throughout the reveal so the adjacent logo stays still.
class _WordmarkClipper extends CustomClipper<Rect> {
  _WordmarkClipper(this.reveal) : super(reclip: reveal);
  final Animation<double> reveal;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * reveal.value, size.height);

  @override
  bool shouldReclip(_WordmarkClipper oldClipper) => oldClipper.reveal != reveal;
}

class _SignalRings extends CustomPainter {
  _SignalRings(this.clock) : super(repaint: clock);
  final Animation<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .49;
    final paint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 2; i++) {
      final phase = ((clock.value - .06 - i * .26) / .52).clamp(0.0, 1.0);
      if (phase == 0 || phase == 1) continue;
      final spread = Curves.easeOutQuad.transform(phase);
      paint
        ..strokeWidth = 2.3 - spread
        ..color = RanahPalette.highlight.withValues(
          alpha: .62 * math.sin(phase * math.pi),
        );
      canvas.drawCircle(center, radius * (.59 + .41 * spread), paint);
    }
  }

  @override
  bool shouldRepaint(_SignalRings oldDelegate) => oldDelegate.clock != clock;
}

class _VolcanicLandscape extends CustomPainter {
  _VolcanicLandscape(this.clock) : super(repaint: clock);
  final Animation<double> clock;
  static const _ridgeColors = [
    Color(0xFF285067),
    Color(0xFF1A4057),
    Color(0xFF102D42),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final w = size.width;
    final h = size.height;
    final t = clock.value;
    final light = const Interval(
      .18,
      .78,
      curve: Curves.easeInOut,
    ).transform(t);

    // A lower horizon in portrait keeps the lit crater clear of the wordmark.
    final horizon = h * (w < h ? .81 : .745);
    final summit = Offset(w * .74, horizon - h * .14);
    for (var i = 0; i < _ridgeColors.length; i++) {
      // Nearby ridges travel farther and settle later than the distant summit.
      final rise = Interval(
        i * .07,
        .68 + i * .14,
        curve: Curves.easeOutCubic,
      ).transform(t);
      canvas.save();
      canvas.translate(
        (1 - t) * (i - 1) * math.min(w * .036, 27.0),
        (1 - rise) * math.min(h * .12, 76.0) * (.58 + .21 * i),
      );
      final ridge = _skyline(i, size, horizon, summit);
      if (i == 0) {
        _drawCraterGlow(
          canvas,
          summit + Offset(w * .006, h * .01),
          size,
          t,
          light,
        );
      }
      final land = Path.from(ridge)
        ..lineTo(w * 1.1, h * 1.1)
        ..lineTo(-w * .1, h * 1.1)
        ..close();
      canvas.drawPath(land, Paint()..color = _ridgeColors[i]);
      if (i == 0) {
        final face = Path()
          ..moveTo(summit.dx + w * .029, summit.dy + h * .003)
          ..relativeLineTo(w * .045, h * .055)
          ..relativeLineTo(w * .006, h * .028)
          ..relativeLineTo(w * .071, h * .073)
          ..relativeLineTo(-w * .06, -h * .02)
          ..close();
        canvas.drawPath(face, Paint()..color = const Color(0x26598CA0));
      }
      canvas.drawPath(
        ridge,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0x487BB1BE),
      );
      canvas.restore();
    }
  }

  Path _skyline(int layer, Size size, double y, Offset summit) {
    final w = size.width;
    final h = size.height;
    return switch (layer) {
      0 =>
        Path()
          ..moveTo(-w * .1, y + h * .04)
          ..quadraticBezierTo(.12 * w, y - h * .07, .23 * w, y + h * .01)
          ..cubicTo(
            .34 * w,
            y + h * .08,
            .49 * w,
            y - h * .016,
            summit.dx - .13 * w,
            summit.dy + h * .082,
          )
          ..lineTo(summit.dx - .057 * w, summit.dy + h * .032)
          ..lineTo(summit.dx - .029 * w, summit.dy)
          ..lineTo(summit.dx - .006 * w, summit.dy + h * .012)
          ..lineTo(summit.dx + .01 * w, summit.dy + h * .014)
          ..lineTo(summit.dx + .029 * w, summit.dy + h * .003)
          ..lineTo(summit.dx + .086 * w, summit.dy + h * .054)
          ..quadraticBezierTo(.93 * w, y + h * .012, 1.1 * w, y + h * .028),
      1 =>
        Path()
          ..moveTo(-w * .1, y + h * .08)
          ..quadraticBezierTo(.085 * w, y - h * .032, .17 * w, y + h * .018)
          ..lineTo(w * .28, y + h * .051)
          ..lineTo(w * .35, y + h * .043)
          ..cubicTo(
            w * .48,
            y + h * .096,
            w * .55,
            y + h * .09,
            w * .68,
            y + h * .025,
          )
          ..lineTo(w * .82, y - h * .022)
          ..quadraticBezierTo(.92 * w, y + h * .03, 1.1 * w, y - h * .008),
      _ =>
        Path()
          ..moveTo(-w * .1, y + h * .07)
          ..quadraticBezierTo(.08 * w, y + h * .05, .2 * w, y + h * .11)
          ..cubicTo(
            .36 * w,
            y + h * .16,
            .46 * w,
            y + h * .06,
            .6 * w,
            y + h * .067,
          )
          ..lineTo(w * .75, y + h * .105)
          ..quadraticBezierTo(.9 * w, y + h * .16, 1.1 * w, y + h * .045),
    };
  }

  void _drawCraterGlow(
    Canvas canvas,
    Offset crater,
    Size size,
    double t,
    double light,
  ) {
    if (light == 0) return;
    final radius = math.min(size.shortestSide * .25, 155.0);
    const amber = Color(0xFFFFB381);
    final halo = RadialGradient(
      colors: [
        amber.withValues(alpha: .56 * light),
        amber.withValues(alpha: .16 * light),
        amber.withValues(alpha: 0),
      ],
      stops: const [0, .24, 1],
    );
    final bounds = Rect.fromCircle(center: crater, radius: radius);
    canvas.drawCircle(
      crater,
      radius,
      Paint()..shader = halo.createShader(bounds),
    );
    final paint = Paint();
    for (var i = 0; i < 9; i++) {
      final phase = (t * 1.45 + i / 9) % 1;
      final x =
          crater.dx +
          radius * (phase * .42 + .12 * math.sin(phase * 5 + i * 2.3));
      final y = crater.dy - radius * phase * (.58 + (i % 3) * .19);
      paint.color = amber.withValues(
        alpha: .82 * light * math.sin(math.pi * phase),
      );
      canvas.drawCircle(Offset(x, y), 1.1 + (i % 3) * .45, paint);
    }
  }

  @override
  bool shouldRepaint(_VolcanicLandscape oldDelegate) =>
      oldDelegate.clock != clock;
}

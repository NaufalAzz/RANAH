import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mitigation_content.dart';

/// Original vector illustrations. Motion loops while visible, can be paused,
/// and is disabled when the device requests reduced animation.
class GuideIllustration extends StatefulWidget {
  const GuideIllustration({
    required this.step,
    required this.accent,
    super.key,
  });
  final IllustratedGuideStep step;
  final Color accent;
  @override
  State<GuideIllustration> createState() => _GuideIllustrationState();
}

class _GuideIllustrationState extends State<GuideIllustration>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4400),
  );
  bool _paused = false;
  bool _reduceMotion = false;
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }

  void _syncMotion() {
    if (_reduceMotion || !_visible || !_foreground || _paused) {
      _controller.stop();
      if (_reduceMotion) _controller.value = .8;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF103954),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.accent.withValues(alpha: .3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          RepaintBoundary(
            child: SizedBox(
              height: 178,
              width: double.infinity,
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _ScenePainter(
                    widget.step.scene,
                    _controller,
                    widget.accent,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.step.caption,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          if (reduced)
            const Text(
              'Ilustrasi statis · animasi dikurangi sesuai pengaturan perangkat',
              style: TextStyle(color: Color(0xFFB5CDDE), fontSize: 12),
              textAlign: TextAlign.center,
            )
          else
            TextButton.icon(
              key: const ValueKey('guide-animation-toggle'),
              onPressed: () {
                setState(() => _paused = !_paused);
                _syncMotion();
              },
              style: TextButton.styleFrom(
                foregroundColor: widget.accent,
                minimumSize: const Size(48, 48),
              ),
              icon: Icon(
                !_paused ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(!_paused ? 'Jeda animasi' : 'Lanjutkan animasi'),
            ),
        ],
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter(this.scene, this.clock, this.accent) : super(repaint: clock);
  final GuideScene scene;
  final Animation<double> clock;
  double get progress => ((clock.value - .07) / .65).clamp(0.0, 1.0);
  final Color accent;
  void _line(Canvas c, Offset a, Offset b, Color color, [double width = 4]) =>
      c.drawLine(
        a,
        b,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
  void _rect(Canvas c, Rect r, Color color, [double radius = 8]) => c.drawRRect(
    RRect.fromRectAndRadius(r, Radius.circular(radius)),
    Paint()..color = color,
  );
  void _person(Canvas c, Offset o, Color color, {bool walk = false}) {
    c.drawCircle(
      o + const Offset(0, -30),
      11,
      Paint()..color = const Color(0xFFFFD4B4),
    );
    _line(c, o + const Offset(0, -14), o + const Offset(0, 17), color, 13);
    final swing = walk ? math.sin(progress * math.pi * 6) * 8 : 6.0;
    _line(c, o + const Offset(0, 14), o + Offset(-10 - swing, 38), color, 6);
    _line(c, o + const Offset(0, 14), o + Offset(10 + swing, 38), color, 6);
    _line(c, o + const Offset(0, -8), o + const Offset(-18, 9), color, 5);
    _line(c, o + const Offset(0, -8), o + const Offset(18, 9), color, 5);
  }

  void _house(Canvas c, double x, double y) {
    _rect(c, Rect.fromLTWH(x - 48, y, 96, 74), const Color(0xFF416D8A));
    c.drawPath(
      Path()
        ..moveTo(x - 62, y + 3)
        ..lineTo(x, y - 42)
        ..lineTo(x + 62, y + 3)
        ..close(),
      Paint()..color = accent,
    );
    _rect(c, Rect.fromLTWH(x - 13, y + 29, 26, 45), const Color(0xFF153B57), 3);
    _rect(c, Rect.fromLTWH(x - 36, y + 20, 17, 22), const Color(0xFFB2DEEF), 3);
    _rect(c, Rect.fromLTWH(x + 19, y + 20, 17, 22), const Color(0xFFB2DEEF), 3);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = math.min(size.width / 340, size.height / 174);
    canvas.translate(
      (size.width - 340 * scale) / 2,
      (size.height - 174 * scale) / 2,
    );
    canvas.scale(scale);
    final p = Curves.easeInOut.transform(progress);
    // A quiet landscape anchors the action. Fade only the drawing at the
    // seam so every demonstration repeats in the intended direction.
    final horizon = Path()
      ..moveTo(0, 130)
      ..quadraticBezierTo(42, 93, 79, 101)
      ..lineTo(128, 57)
      ..quadraticBezierTo(138, 50, 150, 63)
      ..lineTo(197, 101)
      ..quadraticBezierTo(228, 83, 249, 89)
      ..lineTo(304, 49)
      ..lineTo(340, 74)
      ..lineTo(340, 146)
      ..lineTo(0, 146)
      ..close();
    canvas.drawPath(
      horizon,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: .15),
            accent.withValues(alpha: .025),
          ],
        ).createShader(const Rect.fromLTWH(0, 45, 340, 101)),
    );
    final opacity = math.min(
      1.0,
      math.min(clock.value / .06, (1 - clock.value) / .09),
    );
    final fade = opacity < 1;
    if (fade)
      canvas.saveLayer(
        const Rect.fromLTWH(-4, -5, 348, 185),
        Paint()
          ..color = Colors.white.withValues(alpha: opacity.clamp(0.0, 1.0)),
      );
    canvas.drawOval(
      const Rect.fromLTWH(40, 144, 260, 14),
      Paint()..color = const Color(0xFF0B2A41),
    );
    switch (scene) {
      case GuideScene.window:
        _rect(
          canvas,
          const Rect.fromLTWH(102, 30, 136, 112),
          const Color(0xFF93B5C5),
          6,
        );
        _rect(
          canvas,
          const Rect.fromLTWH(109, 37, 122, 98),
          const Color(0xFF23475B),
          3,
        );
        for (var i = 0; i < 12; i++) {
          final x = 113.0 + (i * 19) % 112;
          canvas.drawCircle(
            Offset(x, 45 + (i * 23 + progress * 50) % 81),
            2,
            Paint()..color = const Color(0xFFC7CED3),
          );
        }
        for (final x in [109.0, 170.0]) {
          final inset = (1 - p) * 23;
          _rect(
            canvas,
            Rect.fromLTWH(x + (x == 109 ? 0 : inset), 37, 60 - inset, 98),
            accent.withValues(alpha: .85),
            2,
          );
          _line(
            canvas,
            Offset(x + 12, 71),
            Offset(x + 26, 54),
            Colors.white54,
            2,
          );
        }
        _rect(
          canvas,
          const Rect.fromLTWH(94, 140, 152, 7),
          const Color(0xFF496F86),
          3,
        );
      case GuideScene.water:
        for (final x in [110.0, 174.0]) {
          _rect(
            canvas,
            Rect.fromLTWH(x, 55, 46, 82),
            const Color(0xFFC2E4ED),
            10,
          );
          final level = 26 + 38 * p;
          _rect(
            canvas,
            Rect.fromLTWH(x + 4, 133 - level, 38, level),
            const Color(0xFF429DAC),
            7,
          );
          _rect(
            canvas,
            Rect.fromLTWH(x + 11, 45, 24, 12),
            const Color(0xFF72A6B5),
            2,
          );
          _rect(canvas, Rect.fromLTWH(x + 9, 26 + p * 14, 28, 11), accent, 3);
        }
      case GuideScene.meeting:
        _person(
          canvas,
          Offset(105 + 17 * p, 97),
          const Color(0xFF71B7C2),
          walk: true,
        );
        _person(canvas, const Offset(173, 85), accent);
        _person(
          canvas,
          Offset(238 - 17 * p, 101),
          const Color(0xFF86A8D8),
          walk: true,
        );
      case GuideScene.vehicle:
        _line(
          canvas,
          const Offset(48, 141),
          const Offset(291, 141),
          const Color(0xFF568093),
          2,
        );
        canvas.save();
        canvas.translate(30 * p - 15, 0);
        _rect(canvas, const Rect.fromLTWH(91, 64, 141, 62), accent, 12);
        _rect(
          canvas,
          const Rect.fromLTWH(98, 72, 79, 24),
          const Color(0xFF20455F),
          4,
        );
        _line(canvas, const Offset(137, 72), const Offset(137, 96), accent, 3);
        _rect(
          canvas,
          const Rect.fromLTWH(185, 72, 38, 24),
          const Color(0xFFB9DAE3),
          4,
        );
        for (final x in [117.0, 208.0]) {
          canvas.drawCircle(
            Offset(x, 125),
            13,
            Paint()..color = const Color(0xFF0D263A),
          );
          canvas.drawCircle(
            Offset(x, 125),
            6,
            Paint()..color = const Color(0xFFA4C4CF),
          );
        }
        canvas.restore();
      case GuideScene.radio:
        _rect(
          canvas,
          const Rect.fromLTWH(100, 45, 140, 100),
          const Color(0xFF436E8D),
          16,
        );
        _rect(
          canvas,
          const Rect.fromLTWH(117, 62, 106, 25),
          const Color(0xFFB2DEEF),
          4,
        );
        _line(canvas, const Offset(206, 45), const Offset(231, 15), accent);
        for (var i = 0; i < 3; i++) {
          _line(
            canvas,
            Offset(122, 105.0 + i * 10),
            Offset(183, 105.0 + i * 10),
            const Color(0xFFB2DEEF),
            3,
          );
        }
        canvas.drawCircle(const Offset(212, 114), 10, Paint()..color = accent);
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(
            Rect.fromCircle(
              center: const Offset(231, 27),
              radius: 12 + i * 9 + p * 8,
            ),
            -1.2,
            1.4,
            false,
            Paint()
              ..color = accent.withValues(alpha: (1 - p) * .6)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      case GuideScene.bag:
        _rect(
          canvas,
          const Rect.fromLTWH(130, 24, 80, 30),
          const Color(0xFF335E7E),
          15,
        );
        _rect(canvas, const Rect.fromLTWH(113, 46, 114, 103), accent, 20);
        _rect(
          canvas,
          const Rect.fromLTWH(129, 91, 82, 42),
          const Color(0xFF254E70),
          10,
        );
        _line(
          canvas,
          const Offset(137, 101),
          const Offset(203, 101),
          const Color(0xFFA8DAE9),
          3,
        );
        final x = 55 + p * 43;
        _rect(canvas, Rect.fromLTWH(x, 61, 25, 61), const Color(0xFF8AD6E9), 6);
        _rect(
          canvas,
          Rect.fromLTWH(x + 5, 51, 15, 12),
          const Color(0xFFE4F6FA),
          3,
        );
        final mx = 270 - p * 29;
        _rect(
          canvas,
          Rect.fromLTWH(mx, 79, 34, 34),
          const Color(0xFFE4F6FA),
          8,
        );
        _line(
          canvas,
          Offset(mx + 17, 87),
          Offset(mx + 17, 105),
          const Color(0xFFD45C6C),
          6,
        );
        _line(
          canvas,
          Offset(mx + 8, 96),
          Offset(mx + 26, 96),
          const Color(0xFFD45C6C),
          6,
        );
      case GuideScene.mask:
        _rect(
          canvas,
          const Rect.fromLTWH(116, 113, 108, 44),
          const Color(0xFF416D8A),
          24,
        );
        canvas.drawCircle(
          const Offset(170, 70),
          39,
          Paint()..color = const Color(0xFFFFD4B4),
        );
        _rect(
          canvas,
          const Rect.fromLTWH(135, 48, 70, 23),
          const Color(0xFF204A68),
          7,
        );
        _rect(
          canvas,
          const Rect.fromLTWH(140, 52, 26, 14),
          const Color(0xFFB2DEEF),
          4,
        );
        _rect(
          canvas,
          const Rect.fromLTWH(174, 52, 26, 14),
          const Color(0xFFB2DEEF),
          4,
        );
        final maskX = 270 - 126 * p;
        _rect(canvas, Rect.fromLTWH(maskX, 77, 52, 28), accent, 9);
        _line(
          canvas,
          Offset(maskX + 9, 88),
          Offset(maskX + 43, 88),
          const Color(0xFF416D8A),
          2,
        );
        _line(
          canvas,
          Offset(maskX + 9, 94),
          Offset(maskX + 43, 94),
          const Color(0xFF416D8A),
          2,
        );
        for (var i = 0; i < 8; i++) {
          canvas.drawCircle(
            Offset(40.0 + (i % 3) * 18, 27.0 + (i * 17 + progress * 35) % 104),
            2.5,
            Paint()..color = const Color(0xFF8DAAB8),
          );
        }
      case GuideScene.route:
        final path = Path()
          ..moveTo(60, 125)
          ..cubicTo(105, 150, 185, 30, 267, 78);
        canvas.drawPath(
          path,
          Paint()
            ..color = accent.withValues(alpha: .5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round,
        );
        _house(canvas, 275, 63);
        final metric = path.computeMetrics().first;
        final point = metric.getTangentForOffset(metric.length * p)!.position;
        _person(canvas, point + const Offset(0, -27), accent, walk: true);
        _line(
          canvas,
          const Offset(72, 76),
          const Offset(72, 39),
          const Color(0xFFE4F6FA),
          3,
        );
        canvas.drawPath(
          Path()
            ..moveTo(72, 39)
            ..lineTo(99, 46)
            ..lineTo(72, 55)
            ..close(),
          Paint()..color = accent,
        );
      case GuideScene.shelter:
        _house(canvas, 172, 66);
        _rect(canvas, Rect.fromLTWH(159, 95, 26 * p, 45), accent, 2);
        for (var i = 0; i < 8; i++) {
          canvas.drawCircle(
            Offset(25.0 + i * 13, 24.0 + (i * 19 + progress * 45) % 92),
            2.2,
            Paint()..color = const Color(0xFF8DAAB8),
          );
        }
      case GuideScene.river:
        canvas.drawPath(
          Path()
            ..moveTo(218, 19)
            ..lineTo(280, 93)
            ..lineTo(156, 93)
            ..close(),
          Paint()..color = const Color(0xFF55768E),
        );
        final river = Path()
          ..moveTo(222, 82)
          ..cubicTo(282, 110, 163, 115, 203, 156);
        canvas.drawPath(
          river,
          Paint()
            ..color = const Color(0xFF71BDDE)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 19,
        );
        final metric = river.computeMetrics().first;
        for (var i = 0; i < 4; i++) {
          final o = metric
              .getTangentForOffset(metric.length * ((p + i * .25) % 1))!
              .position;
          canvas.drawCircle(o, 4, Paint()..color = const Color(0xFF52677C));
        }
        _line(
          canvas,
          const Offset(83, 109),
          const Offset(135, 109),
          const Color(0xFFFFA0AD),
          8,
        );
        _line(
          canvas,
          const Offset(91, 109),
          const Offset(91, 149),
          const Color(0xFFE4F6FA),
          5,
        );
        _line(
          canvas,
          const Offset(127, 109),
          const Offset(127, 149),
          const Color(0xFFE4F6FA),
          5,
        );
      case GuideScene.help:
        _person(canvas, const Offset(128, 101), accent);
        _person(canvas, Offset(200 + p * 10, 101), const Color(0xFFB8D8EE));
        _line(
          canvas,
          const Offset(148, 99),
          Offset(180 + p * 10, 99),
          accent,
          5,
        );
        _line(
          canvas,
          Offset(223 + p * 10, 106),
          Offset(223 + p * 10, 144),
          const Color(0xFFE4F6FA),
          4,
        );
        canvas.drawCircle(
          const Offset(265, 40),
          18,
          Paint()..color = accent.withValues(alpha: .2),
        );
        _line(canvas, const Offset(256, 40), const Offset(274, 40), accent, 4);
        _line(canvas, const Offset(265, 31), const Offset(265, 49), accent, 4);
      case GuideScene.clean:
        for (var i = 0; i < 12; i++) {
          canvas.drawCircle(
            Offset(105.0 + i * 12, 130.0 + (i % 3) * 5),
            2.5,
            Paint()
              ..color = const Color(0xFF8DAAB8).withValues(alpha: 1 - p * .7),
          );
        }
        final x = 135 + p * 77;
        _line(
          canvas,
          Offset(x + 25, 55),
          Offset(x, 121),
          const Color(0xFFB8D8EE),
          7,
        );
        canvas.drawPath(
          Path()
            ..moveTo(x - 15, 121)
            ..lineTo(x + 10, 121)
            ..lineTo(x + 23, 143)
            ..lineTo(x - 26, 143)
            ..close(),
          Paint()..color = accent,
        );
        canvas.drawPath(
          Path()
            ..moveTo(68, 64)
            ..quadraticBezierTo(41, 99, 68, 108)
            ..quadraticBezierTo(95, 99, 68, 64)
            ..close(),
          Paint()..color = const Color(0xFF71BDDE),
        );
    }
    if (fade) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.clock != clock ||
      oldDelegate.scene != scene ||
      oldDelegate.accent != accent;
}

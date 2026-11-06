import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'mitigation_content.dart';

/// Original vector illustrations. Motion is finite, can be paused/replayed,
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
    duration: const Duration(milliseconds: 2600),
  );
  bool _initialized = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_initialized) {
      _controller.forward();
    }
    _initialized = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller.stop();
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
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'LIHAT & PAHAMI',
              style: TextStyle(
                color: Color(0xFFC0D8E7),
                fontSize: 12,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => Column(
              children: [
                SizedBox(
                  height: 174,
                  width: double.infinity,
                  child: ExcludeSemantics(
                    child: CustomPaint(
                      painter: _ScenePainter(
                        widget.step.scene,
                        _controller.value,
                        widget.accent,
                      ),
                    ),
                  ),
                ),
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
                      if (_controller.isAnimating) {
                        _controller.stop();
                        setState(() {});
                      } else {
                        _controller.forward(
                          from: _controller.isCompleted ? 0 : _controller.value,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: widget.accent,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: Icon(
                      _controller.isAnimating
                          ? Icons.pause_rounded
                          : Icons.replay_rounded,
                    ),
                    label: Text(
                      _controller.isAnimating
                          ? 'Jeda animasi'
                          : 'Putar ilustrasi',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.scene, this.progress, this.accent);
  final GuideScene scene;
  final double progress;
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
    canvas.drawOval(
      const Rect.fromLTWH(40, 144, 260, 14),
      Paint()..color = const Color(0xFF0B2A41),
    );
    switch (scene) {
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.scene != scene ||
      oldDelegate.accent != accent;
}

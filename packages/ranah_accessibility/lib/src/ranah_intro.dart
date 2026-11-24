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
  late final AnimationController _clock =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2100),
      )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      });
  bool _finished = false;

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
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
    final markSize = wide ? 112.0 : 86.0;
    final mark = Container(
      width: markSize,
      height: markSize,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF102E47),
        borderRadius: BorderRadius.circular(markSize * .24),
        border: Border.all(color: const Color(0xFF427187)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3D061721),
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/brand_mark.png',
        excludeFromSemantics: true,
      ),
    );
    final identity = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          'RANAH',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: RanahPalette.text,
            fontSize: wide ? 60 : 44,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: wide ? 6 : 4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Informasi Bencana dan Evakuasi',
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: const TextStyle(
            color: RanahPalette.secondary,
            fontSize: 16,
            height: 1.45,
          ),
        ),
      ],
    );
    final entrance = _clock.drive(
      CurveTween(curve: const Interval(0, .53, curve: Curves.easeOutCubic)),
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
            const RepaintBoundary(child: CustomPaint(painter: _Ridgelines())),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 52,
                  ),
                  child: FadeTransition(
                    opacity: entrance,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, .06),
                        end: Offset.zero,
                      ).animate(entrance),
                      child: wide
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                mark,
                                const SizedBox(width: 32),
                                Flexible(child: identity),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                mark,
                                const SizedBox(height: 24),
                                identity,
                              ],
                            ),
                    ),
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
          ],
        ),
      ),
    );
  }
}

class _Ridgelines extends CustomPainter {
  const _Ridgelines();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    // Distinct overlapping ridges keep the silhouette legible in portrait and landscape.
    for (var i = 0; i < 3; i++) {
      final y = h * (.70 + i * .09);
      final path = Path()
        ..moveTo(0, y + .035 * h)
        ..quadraticBezierTo(.13 * w, y - h * .045, .23 * w, y + .015 * h)
        ..cubicTo(
          .38 * w,
          y + .095 * h,
          .50 * w,
          y - .025 * h,
          .61 * w,
          y - .055 * h,
        )
        ..lineTo(w * (.72 - .035 * i), y - h * (.14 - i * .022))
        ..lineTo(w * (.745 - .035 * i), y - h * (.133 - i * .022))
        ..quadraticBezierTo(.87 * w, y - .036 * h, w, y + h * (.025 - i * .02));
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..color = const Color(0x4474B8B8),
      );
      canvas.drawPath(
        path
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close(),
        Paint()
          ..color = const [
            Color(0xFF204C61),
            Color(0xFF173C52),
            Color(0xFF102D42),
          ][i],
      );
    }
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h * .46));
    const RanahContours().paint(canvas, Size(w, h * .28));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Ridgelines oldDelegate) => false;
}

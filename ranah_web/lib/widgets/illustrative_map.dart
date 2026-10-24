import 'package:flutter/material.dart';

import '../data/map_sample_data.dart';

class IllustrativeMap extends StatelessWidget {
  const IllustrativeMap({
    required this.padang,
    required this.onSampleLocationTap,
    super.key,
  });

  final bool padang;
  final VoidCallback onSampleLocationTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _MapPainter(padang: padang)),
              if (!padang)
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onSampleLocationTap,
                      splashColor: Colors.white12,
                    ),
                  ),
                ),
              Positioned(
                right: 9,
                top: 8,
                child: _MapTag(
                  text: padang ? 'AREA CONTOH · PADANG' : 'PETA ILUSTRATIF',
                ),
              ),
              if (!padang) ...[
                _MapText(
                  'SUMATERA',
                  constraints.maxWidth * .15,
                  constraints.maxHeight * .49,
                ),
                _MapText(
                  'KALIMANTAN',
                  constraints.maxWidth * .40,
                  constraints.maxHeight * .37,
                ),
                _MapText(
                  'INDONESIA',
                  constraints.maxWidth * .50,
                  constraints.maxHeight * .80,
                ),
                _MountainMarker(
                  constraints.maxWidth * .18,
                  constraints.maxHeight * .40,
                  const Color(0xFF2EAF55),
                  onSampleLocationTap,
                ),
                _MountainMarker(
                  constraints.maxWidth * .22,
                  constraints.maxHeight * .55,
                  const Color(0xFFFFCB2F),
                  onSampleLocationTap,
                ),
                _MountainMarker(
                  constraints.maxWidth * .27,
                  constraints.maxHeight * .73,
                  const Color(0xFFF47A27),
                  onSampleLocationTap,
                ),
                _MountainMarker(
                  constraints.maxWidth * .39,
                  constraints.maxHeight * .71,
                  const Color(0xFFFFCB2F),
                  onSampleLocationTap,
                ),
                _MountainMarker(
                  constraints.maxWidth * .66,
                  constraints.maxHeight * .60,
                  const Color(0xFFF47A27),
                  onSampleLocationTap,
                ),
                _MountainMarker(
                  constraints.maxWidth * .78,
                  constraints.maxHeight * .38,
                  const Color(0xFFFFCB2F),
                  onSampleLocationTap,
                ),
                _MountainMarker(
                  constraints.maxWidth * .88,
                  constraints.maxHeight * .63,
                  const Color(0xFF2EAF55),
                  onSampleLocationTap,
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _ActivityLegend(compact: constraints.maxWidth < 480),
                ),
              ] else ...[
                Positioned(
                  left: constraints.maxWidth * .23,
                  top: constraints.maxHeight * .38,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEB3037),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x77000000), blurRadius: 6),
                      ],
                    ),
                    child: const Icon(
                      Icons.place,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                Positioned(
                  right: constraints.maxWidth * .32,
                  top: constraints.maxHeight * .20,
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF3AC567),
                    size: 34,
                  ),
                ),
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: _MapTag(text: 'JALUR & POSISI CONTOH'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter({required this.padang});

  final bool padang;

  @override
  void paint(Canvas canvas, Size size) {
    if (padang) {
      _paintPadang(canvas, size);
    } else {
      _paintIndonesia(canvas, size);
    }
  }

  void _paintIndonesia(Canvas canvas, Size size) {
    final ocean = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF12617A), Color(0xFF073F5E), Color(0xFF147083)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, ocean);
    final land = Paint()..color = const Color(0xFF6F8453);
    final coast = Paint()
      ..color = const Color(0xFFB8AA72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final islands = <List<Offset>>[
      [
        const Offset(.03, .08),
        const Offset(.09, .06),
        const Offset(.14, .18),
        const Offset(.18, .29),
        const Offset(.21, .43),
        const Offset(.25, .57),
        const Offset(.29, .73),
        const Offset(.27, .91),
        const Offset(.23, .98),
        const Offset(.19, .85),
        const Offset(.17, .68),
        const Offset(.13, .54),
        const Offset(.10, .36),
        const Offset(.06, .20),
      ],
      [
        const Offset(.28, .69),
        const Offset(.39, .66),
        const Offset(.51, .70),
        const Offset(.66, .76),
        const Offset(.72, .83),
        const Offset(.65, .88),
        const Offset(.50, .86),
        const Offset(.36, .82),
        const Offset(.29, .77),
      ],
      [
        const Offset(.39, .13),
        const Offset(.48, .10),
        const Offset(.57, .19),
        const Offset(.60, .36),
        const Offset(.55, .52),
        const Offset(.48, .58),
        const Offset(.41, .50),
        const Offset(.38, .32),
      ],
      [
        const Offset(.62, .28),
        const Offset(.68, .20),
        const Offset(.71, .30),
        const Offset(.68, .40),
        const Offset(.74, .47),
        const Offset(.70, .56),
        const Offset(.65, .47),
        const Offset(.62, .39),
        const Offset(.58, .34),
      ],
      [
        const Offset(.79, .39),
        const Offset(.88, .35),
        const Offset(.98, .39),
        const Offset(1.02, .50),
        const Offset(.97, .61),
        const Offset(.88, .64),
        const Offset(.80, .58),
        const Offset(.76, .48),
      ],
    ];
    for (final points in islands) {
      final path = _polygon(points, size);
      canvas.drawPath(path, land);
      canvas.drawPath(path, coast);
    }
    final roads = Paint()
      ..color = const Color(0xFFDAC990).withValues(alpha: .7)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    _line(canvas, size, roads, const [
      Offset(.13, .20),
      Offset(.17, .41),
      Offset(.21, .61),
      Offset(.25, .81),
    ]);
    _line(canvas, size, roads, const [
      Offset(.33, .76),
      Offset(.45, .75),
      Offset(.57, .78),
      Offset(.67, .82),
    ]);
    _line(canvas, size, roads, const [
      Offset(.44, .18),
      Offset(.48, .32),
      Offset(.51, .47),
    ]);
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      final y = size.height * (i + .5) / 8;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), wave);
    }
  }

  void _paintPadang(Canvas canvas, Size size) {
    final ocean = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0B6681), Color(0xFF164C62)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, ocean);
    final land = Path()
      ..moveTo(size.width * .28, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .18, size.height)
      ..lineTo(size.width * .25, size.height * .74)
      ..lineTo(size.width * .22, size.height * .55)
      ..lineTo(size.width * .30, size.height * .33)
      ..close();
    canvas.drawPath(land, Paint()..color = const Color(0xFF727D55));
    final blocks = Paint()
      ..color = const Color(0xFF9A956D).withValues(alpha: .72);
    for (var row = 0; row < 7; row++) {
      for (var col = 0; col < 10; col++) {
        final x = size.width * (.32 + col * .073 + (row.isEven ? .005 : .025));
        final y = size.height * (.06 + row * .135);
        final width = size.width * (.035 + (col % 3) * .008);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, width, size.height * .038),
            const Radius.circular(2),
          ),
          blocks,
        );
      }
    }
    final road = Paint()
      ..color = const Color(0xFFF1E3B8)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    _line(canvas, size, road, const [
      Offset(.27, .14),
      Offset(.42, .29),
      Offset(.52, .48),
      Offset(.61, .67),
      Offset(.72, .88),
    ]);
    _line(canvas, size, road, const [
      Offset(.35, .88),
      Offset(.51, .67),
      Offset(.68, .48),
      Offset(.88, .26),
    ]);
    final route = Paint()
      ..color = const Color(0xFFFF765C)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    _line(canvas, size, route, const [
      Offset(.23, .60),
      Offset(.36, .54),
      Offset(.50, .49),
      Offset(.64, .39),
      Offset(.70, .21),
    ]);
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..strokeWidth = .7;
    for (var i = 1; i < 7; i++) {
      canvas.drawLine(
        Offset(size.width * i / 7, 0),
        Offset(size.width * i / 7, size.height),
        grid,
      );
    }
  }

  Path _polygon(List<Offset> points, Size size) {
    final path = Path()
      ..moveTo(size.width * points.first.dx, size.height * points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(size.width * point.dx, size.height * point.dy);
    }
    return path..close();
  }

  void _line(Canvas canvas, Size size, Paint paint, List<Offset> points) {
    final path = Path()
      ..moveTo(size.width * points.first.dx, size.height * points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(size.width * point.dx, size.height * point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      padang != oldDelegate.padang;
}

class _MountainMarker extends StatelessWidget {
  const _MountainMarker(this.left, this.top, this.color, this.onTap);

  final double left;
  final double top;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: InkResponse(
      onTap: onTap,
      radius: 18,
      child: Icon(Icons.change_history_rounded, color: color, size: 18),
    ),
  );
}

class _MapText extends StatelessWidget {
  const _MapText(this.text, this.left, this.top);

  final String text;
  final double left;
  final double top;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    child: IgnorePointer(
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .76),
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: .7,
          shadows: const [Shadow(color: Colors.black87, blurRadius: 3)],
        ),
      ),
    ),
  );
}

class _MapTag extends StatelessWidget {
  const _MapTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xB80A2140),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
      ),
    ),
  );
}

class _ActivityLegend extends StatelessWidget {
  const _ActivityLegend({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xD90B2140),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in activityLevels)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: Color(item.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.label} · ${item.detail}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 2),
        const Text(
          'Contoh level · bukan status terkini',
          style: TextStyle(color: Colors.white70, fontSize: 8),
        ),
      ],
    ),
  );
}

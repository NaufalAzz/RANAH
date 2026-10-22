import 'dart:math' as math;

import 'package:flutter/material.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF102C49), Color(0xFF08273F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -100,
            top: 340,
            child: _BackgroundRing(size: 300),
          ),
          Positioned.fill(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
              children: const [
                _MapTitlePanel(),
                SizedBox(height: 14),
                _IllustrativeMap(),
                SizedBox(height: 14),
                _LocationAction(),
                SizedBox(height: 10),
                _ActivityReportHeading(),
                SizedBox(height: 10),
                _LocationSummary(),
                SizedBox(height: 12),
                _RoutePanel(),
                SizedBox(height: 12),
                _NearbyVolcanoPanel(),
                SizedBox(height: 12),
                _HazardPanel(),
                SizedBox(height: 12),
                _MapSourceNote(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundRing extends StatelessWidget {
  const _BackgroundRing({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.035),
            width: 26,
          ),
        ),
      ),
    );
  }
}

class _MapTitlePanel extends StatelessWidget {
  const _MapTitlePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF29107C), Color(0xFF18064A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.landscape_outlined, color: Colors.white, size: 42),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PETA DAN KESIAPSIAGAAN',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF8BC8FF),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Peta dan Zona Bencana',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Zona bahaya dan titik evakuasi',
                  style: TextStyle(color: Color(0xFFD0C9E7), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IllustrativeMap extends StatelessWidget {
  const _IllustrativeMap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AspectRatio(
        aspectRatio: 1.78,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const CustomPaint(painter: _MapSketchPainter()),
              const Align(
                alignment: Alignment(-0.38, -0.18),
                child: _MapPin(
                  icon: Icons.landscape_rounded,
                  color: Color(0xFFDF5538),
                ),
              ),
              const Align(
                alignment: Alignment(0.42, 0.48),
                child: _MapPin(
                  icon: Icons.shield_rounded,
                  color: Color(0xFF128A78),
                ),
              ),
              const Align(
                alignment: Alignment(-0.7, 0.38),
                child: _MapPin(
                  icon: Icons.place_rounded,
                  color: Color(0xFFDF3D39),
                ),
              ),
              Positioned(
                top: 9,
                left: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE6191232),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      'ILUSTRASI - BUKAN PETA AKTUAL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 9,
                right: 9,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xE6191232),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      'TITIK AMAN - CONTOH',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const Positioned(left: 8, bottom: 8, child: _MapLevelLegend()),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

class _MapLevelLegend extends StatelessWidget {
  const _MapLevelLegend();

  static const levels = <({String name, Color color})>[
    (name: 'Level I - Normal', color: Color(0xFF38A65B)),
    (name: 'Level II - Waspada', color: Color(0xFFF4D22F)),
    (name: 'Level III - Siaga', color: Color(0xFFF07831)),
    (name: 'Level IV - Awas', color: Color(0xFFE33C39)),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xD9001324),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in levels)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: item.color, size: 9),
                    const SizedBox(width: 5),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationAction extends StatelessWidget {
  const _LocationAction();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: const Color(0xFF201064),
        borderRadius: BorderRadius.circular(15),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lokasi belum tersedia pada pratinjau ini.'),
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Icon(Icons.location_on, size: 42, color: Colors.white),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Temukan Lokasi Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gunakan lokasi untuk melihat informasi evakuasi di sekitar.',
                        style: TextStyle(
                          color: Color(0xFFD0C9E7),
                          fontSize: 11,
                          height: 1.25,
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
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _InfoPanel(
        icon: Icons.my_location_rounded,
        title: 'Lokasi saat ini',
        detail:
            'Belum tersedia - lokasi pengguna tidak diakses pada tahap ini.',
      ),
    );
  }
}

class _ActivityReportHeading extends StatelessWidget {
  const _ActivityReportHeading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF201064),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [
            BoxShadow(
              color: Color(0x44000000),
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          'Laporan Aktivitas Gunung',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RoutePanel extends StatelessWidget {
  const _RoutePanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: const [
          _InfoPanel(
            icon: Icons.alt_route_rounded,
            title: 'Jalur Evakuasi',
            detail: 'Rute pada peta hanya ilustrasi dan bukan arahan evakuasi nyata.',
          ),
          SizedBox(height: 8),
          _InfoPanel(
            icon: Icons.route_rounded,
            title: 'Rute Evakuasi Terdekat',
            detail: 'Titik awal dan rute belum tersedia pada data lokal.',
          ),
        ],
      ),
    );
  }
}

class _NearbyVolcanoPanel extends StatelessWidget {
  const _NearbyVolcanoPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _InfoPanel(
        icon: Icons.landscape_rounded,
        title: 'Gunung Api Terdekat',
        detail:
            'Nama, status, dan jarak gunung belum tersedia pada data lokal.',
      ),
    );
  }
}

class _HazardPanel extends StatelessWidget {
  const _HazardPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _InfoPanel(
        icon: Icons.warning_amber_rounded,
        title: 'Potensi Bencana di Lokasi',
        detail: 'Informasi zona bahaya dan titik aman belum tersedia. Elemen pada peta adalah contoh visual.',
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF123D5B),
        border: Border.all(color: const Color(0xFF1D5778)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF155780),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: const Color(0xFF69C7DE), size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFB9D2E1),
                    fontSize: 11,
                    height: 1.3,
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

class _MapSourceNote extends StatelessWidget {
  const _MapSourceNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Text(
        'Sumber peta dan waktu pembaruan belum tersedia pada pratinjau ilustrasi ini. Ikuti arahan resmi BPBD dan PVMBG.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: const Color(0xFFB9D2E1)),
      ),
    );
  }
}

class _MapSketchPainter extends CustomPainter {
  const _MapSketchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF526D4D),
    );
    _drawTerrain(canvas, size);
    _drawCoastAndWater(canvas, size);
    _drawRoads(canvas, size);
    _drawDangerZones(canvas, size);
    _drawRoute(canvas, size);
  }

  void _drawTerrain(Canvas canvas, Size size) {
    final colors = [
      const Color(0xFF687C50),
      const Color(0xFF7F8153),
      const Color(0xFF4E7056),
    ];
    for (var row = 0; row < 5; row++) {
      for (var column = 0; column < 8; column++) {
        final rect = Rect.fromLTWH(
          column * size.width / 8,
          row * size.height / 5,
          size.width / 8 + 1,
          size.height / 5 + 1,
        );
        final paint = Paint()
          ..color = colors[(row * 3 + column * 5) % colors.length].withValues(
            alpha: 0.2,
          );
        canvas.drawRect(rect, paint);
      }
    }
    final hillsPaint = Paint()
      ..color = const Color(0xFF9BA26A).withValues(alpha: 0.24);
    for (var i = 0; i < 7; i++) {
      canvas.drawCircle(
        Offset(
          size.width * (0.08 + i * 0.145),
          size.height * (0.22 + (i % 3) * 0.28),
        ),
        size.height * 0.12,
        hillsPaint,
      );
    }
  }

  void _drawCoastAndWater(Canvas canvas, Size size) {
    final coastline = Path()
      ..moveTo(size.width * 0.77, 0)
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.23,
        size.width * 0.88,
        size.height * 0.35,
        size.width * 0.78,
        size.height * 0.57,
      )
      ..cubicTo(
        size.width * 0.68,
        size.height * 0.77,
        size.width * 0.88,
        size.height * 0.82,
        size.width * 0.75,
        size.height,
      );
    final water = Path.from(coastline)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(
      water,
      Paint()..color = const Color(0xFF126080).withValues(alpha: 0.88),
    );
    final shore = Paint()
      ..color = const Color(0xFFBAC89A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(coastline, shore);
  }

  void _drawRoads(Canvas canvas, Size size) {
    final paths = <Path>[
      Path()
        ..moveTo(0, size.height * 0.67)
        ..cubicTo(
          size.width * 0.2,
          size.height * 0.5,
          size.width * 0.45,
          size.height * 0.8,
          size.width * 0.75,
          size.height * 0.39,
        ),
      Path()
        ..moveTo(size.width * 0.12, 0)
        ..cubicTo(
          size.width * 0.28,
          size.height * 0.28,
          size.width * 0.38,
          size.height * 0.6,
          size.width * 0.61,
          size.height,
        ),
      Path()
        ..moveTo(0, size.height * 0.22)
        ..cubicTo(
          size.width * 0.3,
          size.height * 0.34,
          size.width * 0.52,
          size.height * 0.08,
          size.width * 0.77,
          size.height * 0.25,
        ),
    ];
    final edge = Paint()
      ..color = const Color(0xFF725F47)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = const Color(0xFFE7D9AF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final path in paths) {
      canvas.drawPath(path, edge);
      canvas.drawPath(path, road);
    }
  }

  void _drawDangerZones(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.39, size.height * 0.4);
    final radius = math.min(size.height * 0.43, size.width * 0.28).toDouble();
    canvas.drawCircle(center, radius, Paint()..color = const Color(0x44F9C51C));
    canvas.drawCircle(
      center,
      radius * 0.62,
      Paint()..color = const Color(0x55F06C35),
    );
    canvas.drawCircle(
      center,
      radius * 0.28,
      Paint()..color = const Color(0x66D93832),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0x99F2C42A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  void _drawRoute(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.73)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.68,
        size.width * 0.35,
        size.height * 0.54,
        size.width * 0.45,
        size.height * 0.56,
      )
      ..cubicTo(
        size.width * 0.56,
        size.height * 0.59,
        size.width * 0.55,
        size.height * 0.75,
        size.width * 0.72,
        size.height * 0.62,
      );
    final paint = Paint()
      ..color = const Color(0xFF21D2C1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 6, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapSketchPainter oldDelegate) => false;
}

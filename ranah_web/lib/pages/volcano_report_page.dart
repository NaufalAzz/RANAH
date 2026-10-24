import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/volcanic_activity_data.dart';
import '../theme/ranah_theme.dart';

class VolcanoReportPage extends StatefulWidget {
  const VolcanoReportPage({
    required this.volcano,
    required this.onBack,
    super.key,
  });

  final VolcanoActivitySample volcano;
  final VoidCallback onBack;

  @override
  State<VolcanoReportPage> createState() => _VolcanoReportPageState();
}

class _VolcanoReportPageState extends State<VolcanoReportPage> {
  bool _showKrb = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      final panelWidth = mobile
          ? math.min(constraints.maxWidth - 16, constraints.maxWidth * .50)
          : 380.0;
      return Column(
        children: [
          const _ReportTitleBanner(),
          _ReportBackBar(volcano: widget.volcano, onBack: widget.onBack),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _ReportMapPainter(
                    showKrb: _showKrb,
                    volcanoName: widget.volcano.name,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: _MapDisclosure(
                    text: _showKrb
                        ? 'ZONA KRB ILUSTRATIF - BUKAN BATAS RESMI'
                        : 'PETA ILUSTRATIF - BUKAN PETA NAVIGASI',
                    warning: _showKrb,
                  ),
                ),
                SingleChildScrollView(
                  padding: EdgeInsets.all(mobile ? 8 : 18),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: panelWidth,
                      child: _ReportPanel(
                        volcano: widget.volcano,
                        showKrb: _showKrb,
                        onToggleKrb: () => setState(() => _showKrb = !_showKrb),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _ReportTitleBanner extends StatelessWidget {
  const _ReportTitleBanner();

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    color: const Color(0xFF17003E),
    child: const Row(
      children: [
        Icon(Icons.landscape_outlined, size: 27),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISASTER EVACUATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: .9,
                  color: Color(0xFF91A8D0),
                ),
              ),
              Text(
                'Volcanic Activity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Memantau aktivitas gunung api',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 9, color: Color(0xFFC1C8D7)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ReportBackBar extends StatelessWidget {
  const _ReportBackBar({required this.volcano, required this.onBack});

  final VolcanoActivitySample volcano;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    color: const Color(0xFF12304C),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 14),
          label: const Text('Kembali', style: TextStyle(fontSize: 10)),
          style: TextButton.styleFrom(
            foregroundColor: RanahColors.ink,
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            minimumSize: const Size(0, 26),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFB51B).withValues(alpha: .8),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            'Level ${volcano.level} - ${_levelName(volcano.level)} (contoh)',
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xFF332308),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({
    required this.volcano,
    required this.showKrb,
    required this.onToggleKrb,
  });

  final VolcanoActivitySample volcano;
  final bool showKrb;
  final VoidCallback onToggleKrb;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xD9154770),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFF4B91B4)),
      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Laporan Gunung Api - DATA CONTOH',
          style: TextStyle(fontSize: 9, color: Color(0xFFE3ECF5)),
        ),
        Text(
          volcano.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1.78,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Image.asset(volcano.image, fit: BoxFit.cover),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 3),
          child: Text(
            'Foto ilustrasi dari mockup - bukan bukti status terkini.',
            style: TextStyle(fontSize: 8),
          ),
        ),
        const SizedBox(height: 5),
        SizedBox(
          height: 30,
          child: OutlinedButton(
            onPressed: onToggleKrb,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0xFF164D79),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.centerLeft,
              side: const BorderSide(color: Color(0xFF7AB2D2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            child: Text(
              showKrb ? 'Sembunyikan Zona KRB' : 'Tampilkan Peta KRB',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        if (showKrb)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Zona ini hanya ilustrasi perkiraan, bukan batas KRB resmi.',
              style: TextStyle(
                fontSize: 9,
                color: Color(0xFFFFD77D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 7),
        for (final entry in sampleVolcanoReportSections.entries)
          _ReportSection(title: entry.key, body: entry.value),
        const SizedBox(height: 5),
        const Text(
          'Demo lokal - periksa sumber resmi PVMBG/BPBD untuk informasi kebencanaan.',
          style: TextStyle(fontSize: 8, color: Color(0xFFFFD77D)),
        ),
      ],
    ),
  );
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: const TextStyle(
            fontSize: 9,
            height: 1.15,
            color: Color(0xFFF0F3F8),
          ),
        ),
      ],
    ),
  );
}

class _MapDisclosure extends StatelessWidget {
  const _MapDisclosure({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: warning ? const Color(0xE9663D0B) : const Color(0xD9102B42),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: warning ? const Color(0xFFFFC04B) : Colors.white30,
      ),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFFFFE6AC) : Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ReportMapPainter extends CustomPainter {
  const _ReportMapPainter({required this.showKrb, required this.volcanoName});

  final bool showKrb;
  final String volcanoName;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF567A50), Color(0xFF365A45), Color(0xFF244E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds),
    );
    final patches = Paint()
      ..color = const Color(0xFF9A9A59).withValues(alpha: .24);
    for (var row = 0; row < 8; row++) {
      for (var column = 0; column < 12; column++) {
        final x = size.width * (column + .5) / 12;
        final y = size.height * (row + .5) / 8;
        final r =
            size.shortestSide * (.025 + ((row * 7 + column * 3) % 4) * .012);
        canvas.drawCircle(Offset(x, y), r, patches);
      }
    }
    final coastline = Path()
      ..moveTo(size.width * .76, size.height * .65)
      ..cubicTo(
        size.width * .70,
        size.height * .78,
        size.width * .82,
        size.height * .88,
        size.width * .72,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, size.height * .58)
      ..close();
    canvas.drawPath(
      coastline,
      Paint()..color = const Color(0xFF164D5B).withValues(alpha: .88),
    );
    final road = Paint()
      ..color = const Color(0xFFE6D397).withValues(alpha: .9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    _drawPath(canvas, size, road, const [
      Offset(.02, .28),
      Offset(.26, .22),
      Offset(.44, .33),
      Offset(.66, .29),
      Offset(.98, .17),
    ]);
    _drawPath(canvas, size, road, const [
      Offset(.04, .74),
      Offset(.27, .63),
      Offset(.46, .67),
      Offset(.62, .52),
      Offset(.91, .46),
    ]);
    _drawPath(canvas, size, road, const [
      Offset(.32, .02),
      Offset(.40, .22),
      Offset(.54, .43),
      Offset(.55, .70),
      Offset(.72, .90),
    ]);
    final contour = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(size.width * .52, size.height * .48),
          width: size.width * (.2 + i * .12),
          height: size.height * (.11 + i * .08),
        ),
        contour,
      );
    }
    _drawLabel(canvas, size, 'Bulakan', .60, .17);
    _drawLabel(canvas, size, '$volcanoName - ilustrasi', .52, .37);
    _drawLabel(canvas, size, 'Batusangkar', .69, .64);
    _drawLabel(canvas, size, 'PETA ILUSTRATIF', .83, .91);
    _drawPath(canvas, size, Paint()..color = const Color(0xFFE04432), const [
      Offset(.53, .49),
      Offset(.55, .45),
      Offset(.58, .49),
    ]);
    if (showKrb) _drawKrb(canvas, size);
  }

  void _drawKrb(Canvas canvas, Size size) {
    final center = Offset(size.width * .53, size.height * .47);
    final radius = size.shortestSide * .38;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFA322).withValues(alpha: .31),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFFFC45B).withValues(alpha: .9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      radius * .48,
      Paint()..color = const Color(0xFFE64A2F).withValues(alpha: .36),
    );
    canvas.drawCircle(
      center,
      radius * .48,
      Paint()
        ..color = const Color(0xFFFF6A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawPath(Canvas canvas, Size size, Paint paint, List<Offset> points) {
    final path = Path()
      ..moveTo(size.width * points.first.dx, size.height * points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(size.width * point.dx, size.height * point.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, Size size, String text, double x, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * .45);
    painter.paint(canvas, Offset(size.width * x, size.height * y));
  }

  @override
  bool shouldRepaint(covariant _ReportMapPainter oldDelegate) =>
      showKrb != oldDelegate.showKrb || volcanoName != oldDelegate.volcanoName;
}

String _levelName(int level) => switch (level) {
  4 => 'Awas',
  3 => 'Siaga',
  2 => 'Waspada',
  _ => 'Normal',
};

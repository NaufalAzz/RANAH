import 'package:flutter/material.dart';
import 'volcano_reference.dart';

const _illustrations = <String, (String, int)>{
  'bromo': ('volcano-atlas', 0),
  'merapi': ('volcano-atlas', 1),
  'semeru': ('volcano-atlas', 2),
  'marapi': ('volcano-atlas', 3),
  'talang': ('volcano-atlas', 4),
  'tandikat': ('volcano-atlas', 5),
  'kerinci': ('volcano-atlas', 6),
  'rinjani': ('volcano-atlas', 7),
  'agung': ('volcano-atlas', 8),
  'anakkrakatau': ('volcano-atlas', 9),
  'ibu': ('volcano-atlas', 10),
  'dukono': ('volcano-atlas', 11),
  'ambang': ('volcano-atlas-1', 0),
  'anakranakah': ('volcano-atlas-1', 1),
  'arjunowelirang': ('volcano-atlas-1', 2),
  'awu': ('volcano-atlas-1', 3),
  'bandaapi': ('volcano-atlas-1', 4),
  'batur': ('volcano-atlas-1', 5),
  'batutara': ('volcano-atlas-1', 6),
  'burnitelong': ('volcano-atlas-1', 7),
  'ciremai': ('volcano-atlas-1', 8),
  'colo': ('volcano-atlas-1', 9),
  'dempo': ('volcano-atlas-1', 10),
  'dieng': ('volcano-atlas-1', 11),
  'ebulobo': ('volcano-atlas-2', 0),
  'egon': ('volcano-atlas-2', 1),
  'galunggung': ('volcano-atlas-2', 2),
  'gamalama': ('volcano-atlas-2', 3),
  'gamkonora': ('volcano-atlas-2', 4),
  'gede': ('volcano-atlas-2', 5),
  'guntur': ('volcano-atlas-2', 6),
  'hobal': ('volcano-atlas-2', 7),
  'ijen': ('volcano-atlas-2', 8),
  'ilewerung': ('volcano-atlas-2', 9),
  'iliboleng': ('volcano-atlas-2', 10),
  'ililewotolok': ('volcano-atlas-2', 11),
  'inielika': ('volcano-atlas-3', 0),
  'inierie': ('volcano-atlas-3', 1),
  'iya': ('volcano-atlas-3', 2),
  'kaba': ('volcano-atlas-3', 3),
  'karangetang': ('volcano-atlas-3', 4),
  'kelimutu': ('volcano-atlas-3', 5),
  'kelud': ('volcano-atlas-3', 6),
  'kiebesi': ('volcano-atlas-3', 7),
  'lamongan': ('volcano-atlas-3', 8),
  'lereboleng': ('volcano-atlas-3', 9),
  'lewotobilakilaki': ('volcano-atlas-3', 10),
  'lewotobiperempuan': ('volcano-atlas-3', 11),
  'lokon': ('volcano-atlas-4', 0),
  'mahawu': ('volcano-atlas-4', 1),
  'papandayan': ('volcano-atlas-4', 2),
  'peutsague': ('volcano-atlas-4', 3),
  'raung': ('volcano-atlas-4', 4),
  'rokatenda': ('volcano-atlas-4', 5),
  'ruang': ('volcano-atlas-4', 6),
  'salak': ('volcano-atlas-4', 7),
  'sangeangapi': ('volcano-atlas-4', 8),
  'seulawahagam': ('volcano-atlas-4', 9),
  'sinabung': ('volcano-atlas-4', 10),
  'sirung': ('volcano-atlas-4', 11),
  'slamet': ('volcano-atlas-5', 0),
  'soputan': ('volcano-atlas-5', 1),
  'sorikmarapi': ('volcano-atlas-5', 2),
  'sumbing': ('volcano-atlas-5', 3),
  'sundoro': ('volcano-atlas-5', 4),
  'tambora': ('volcano-atlas-5', 5),
  'tangkoko': ('volcano-atlas-5', 6),
  'tangkubanparahu': ('volcano-atlas-5', 7),
  'wurlali': ('volcano-atlas-5', 8),
};

/// Whether a known name or alias has an explicitly mapped illustration.
bool hasVolcanoIllustration(String name) =>
    _illustrations.containsKey(normalizeVolcanoName(name));

/// Name-specific local illustrations; never substituted for an observation photo.
/// Unknown names use a geographic locator instead of borrowing another peak.
class VolcanoArtwork extends StatelessWidget {
  const VolcanoArtwork({required this.name, this.showLabel = true, super.key});
  final String name;
  final bool showLabel;
  @override
  Widget build(BuildContext context) {
    final illustration = _illustrations[normalizeVolcanoName(name)];
    final tile = illustration?.$2;
    final label = tile == null ? 'Peta lokasi · $name' : name;
    return Semantics(
      label: label,
      image: true,
      child: Tooltip(
        message: label,
        child: ClipRect(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final width = bounds.maxWidth;
              final height = bounds.maxHeight;
              // Crop atlas cells without stretching the mountain silhouettes.
              final tileWidth = width > height * 9 / 8 ? width : height * 9 / 8;
              final tileHeight = tileWidth * 8 / 9;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (tile != null)
                    Positioned(
                      left: -(tile % 4) * tileWidth + (width - tileWidth) / 2,
                      top:
                          -(tile ~/ 4) * tileHeight + (height - tileHeight) / 2,
                      width: tileWidth * 4,
                      height: tileHeight * 3,
                      child: Image.asset(
                        'assets/${illustration!.$1}.webp',
                        package: 'ranah_accessibility',
                        fit: BoxFit.fill,
                        errorBuilder: (_, _, _) => CustomPaint(
                          painter: _Locator(volcanoReference(name)),
                        ),
                      ),
                    ),
                  if (tile == null)
                    CustomPaint(painter: _Locator(volcanoReference(name))),
                  if (!showLabel && tile == null)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        color: Colors.black.withValues(alpha: .7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 1,
                        ),
                        child: Text(
                          'Peta',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  if (showLabel && tile == null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.black.withValues(alpha: .65),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          maxLines: 2,
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
}

class _Locator extends CustomPainter {
  _Locator(this.reference);
  final VolcanoReference? reference;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF123D5B),
    );
    Offset point(VolcanoReference r) => Offset(
      (r.longitude - 94) / 48 * size.width,
      (8 - r.latitude) / 20 * size.height,
    );
    for (final r in volcanoReferences.values) {
      canvas.drawCircle(
        point(r),
        2.5,
        Paint()..color = const Color(0xFF6BA89B),
      );
    }
    if (reference != null) {
      final at = point(reference!);
      canvas.drawCircle(at, 12, Paint()..color = const Color(0x55FFCC66));
      canvas.drawCircle(at, 5, Paint()..color = const Color(0xFFFFCC66));
    }
  }

  @override
  bool shouldRepaint(_Locator oldDelegate) =>
      oldDelegate.reference != reference;
}

import 'package:flutter/material.dart';
import 'volcano_reference.dart';

const _illustrations = <String, int>{
  'bromo': 0,
  'merapi': 1,
  'semeru': 2,
  'marapi': 3,
  'talang': 4,
  'tandikat': 5,
  'kerinci': 6,
  'rinjani': 7,
  'agung': 8,
  'anakkrakatau': 9,
  'ibu': 10,
  'dukono': 11,
};

/// Name-specific local illustrations; never substituted for an observation photo.
/// Other volcanoes use an honest geographic locator instead of another peak.
class VolcanoArtwork extends StatelessWidget {
  const VolcanoArtwork({required this.name, this.showLabel = true, super.key});
  final String name;
  final bool showLabel;
  @override
  Widget build(BuildContext context) {
    final tile = _illustrations[normalizeVolcanoName(name)];
    final label = tile == null ? 'Peta lokasi · $name' : 'Ilustrasi AI · $name';
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
                        'assets/volcano-atlas.webp',
                        package: 'ranah_accessibility',
                        fit: BoxFit.fill,
                        errorBuilder: (_, _, _) => CustomPaint(
                          painter: _Locator(volcanoReference(name)),
                        ),
                      ),
                    ),
                  if (tile == null)
                    CustomPaint(painter: _Locator(volcanoReference(name))),
                  if (!showLabel)
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
                          tile == null ? 'Peta' : 'AI',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ),
                  if (showLabel)
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

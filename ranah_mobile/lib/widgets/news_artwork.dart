import 'package:flutter/material.dart';

import '../models/news_item.dart';
import '../theme/app_theme.dart';

class NewsArtwork extends StatelessWidget {
  const NewsArtwork({required this.item, this.featured = false, super.key});

  final NewsItem item;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: featured ? 188 : 86,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          featured ? AppRadii.image : AppRadii.control,
        ),
        gradient: LinearGradient(
          colors: [item.accent.withValues(alpha: 0.95), AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (featured) const CustomPaint(painter: _NewsScenePainter()),
          if (item.imageUrl case final imageUrl?)
            Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _ArtworkFallbackLabel(),
            ),
          if (item.imageUrl != null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22101A2C),
                    Color(0x00101A2C),
                    Color(0xCC101A2C),
                  ],
                ),
              ),
            ),
          if (item.imageUrl == null)
            const Positioned(top: 8, left: 8, child: _ArtworkFallbackLabel()),
          Positioned(
            right: featured ? 8 : -9,
            bottom: featured ? -34 : -18,
            child: Icon(
              item.icon,
              size: featured ? 142 : 78,
              color: Colors.white.withValues(alpha: featured ? 0.2 : 0.16),
            ),
          ),
          Positioned(
            left: featured ? 20 : 12,
            bottom: featured ? 18 : 12,
            child: Icon(
              item.icon,
              size: featured ? 52 : 32,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkFallbackLabel extends StatelessWidget {
  const _ArtworkFallbackLabel();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xCC101A2C),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        'ILUSTRASI',
        style: AppTypography.badge.copyWith(fontSize: 10),
      ),
    ),
  );
}

class _NewsScenePainter extends CustomPainter {
  const _NewsScenePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final clouds = Paint()
      ..color = const Color(0xFFDCE8EC).withValues(alpha: 0.78);
    final cloudShadow = Paint()
      ..color = const Color(0xFFBACBD5).withValues(alpha: 0.55);
    for (final cloud in <(double, double, double)>[
      (0.48, 0.13, 0.13),
      (0.56, 0.18, 0.17),
      (0.66, 0.22, 0.13),
      (0.43, 0.29, 0.12),
      (0.57, 0.31, 0.18),
      (0.73, 0.33, 0.13),
    ]) {
      canvas.drawCircle(
        Offset(size.width * cloud.$1, size.height * cloud.$2),
        size.width * cloud.$3,
        cloudShadow,
      );
      canvas.drawCircle(
        Offset(size.width * cloud.$1, size.height * cloud.$2 - 3),
        size.width * cloud.$3 * 0.82,
        clouds,
      );
    }

    final volcano = Path()
      ..moveTo(size.width * 0.18, size.height * 0.94)
      ..lineTo(size.width * 0.38, size.height * 0.53)
      ..lineTo(size.width * 0.59, size.height * 0.94)
      ..close();
    canvas.drawPath(volcano, Paint()..color = const Color(0xFF384843));
    final lavaSide = Path()
      ..moveTo(size.width * 0.38, size.height * 0.53)
      ..lineTo(size.width * 0.59, size.height * 0.94)
      ..lineTo(size.width * 0.46, size.height * 0.94)
      ..close();
    canvas.drawPath(lavaSide, Paint()..color = const Color(0xFF745041));
    final craterSmoke = Paint()
      ..color = const Color(0xFFDAE2E4).withValues(alpha: 0.72);
    canvas.drawCircle(
      Offset(size.width * 0.38, size.height * 0.52),
      size.width * 0.025,
      craterSmoke,
    );

    final hillBack = Path()
      ..moveTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.34,
        size.height * 0.51,
        size.width * 0.62,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.63,
        size.width,
        size.height * 0.75,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillBack, Paint()..color = const Color(0xFF496C57));

    final hillFront = Path()
      ..moveTo(0, size.height * 0.9)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.7,
        size.width * 0.72,
        size.height * 0.91,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.78,
        size.width,
        size.height * 0.87,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillFront, Paint()..color = const Color(0xFF243F43));

    final shade = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x00101A2C), Color(0x24101A2C), Color(0xD9101A2C)],
        stops: [0, 0.48, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, shade);
  }

  @override
  bool shouldRepaint(covariant _NewsScenePainter oldDelegate) => false;
}

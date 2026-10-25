import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

class MapPage extends StatelessWidget {
  const MapPage({this.onOpenActivity, super.key});

  final VoidCallback? onOpenActivity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBackground.decoration,
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
              children: [
                _MapTitlePanel(),
                SizedBox(height: 14),
                _IllustrativeMap(),
                SizedBox(height: 12),
                _MapLevelLegend(),
                SizedBox(height: 14),
                _LocationAction(),
                SizedBox(height: 10),
                _ActivityReportHeading(onTap: onOpenActivity),
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
            color: AppBackground.ringColor,
            width: AppBackground.ringWidth,
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
    return const AppPageBanner(
      icon: Icons.landscape_outlined,
      eyebrow: 'PETA DAN KESIAPSIAGAAN',
      title: 'Peta dan Zona Bencana',
      subtitle: 'Zona bahaya dan titik evakuasi',
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      iconSize: 42,
      iconGap: AppSpacing.md,
      gradient: AppGradients.sectionBanner,
      eyebrowStyle: TextStyle(
        color: AppColors.bannerEyebrow,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.1,
      ),
      titleStyle: TextStyle(
        color: AppColors.onDark,
        fontSize: 21,
        height: 1.1,
        fontWeight: FontWeight.w800,
      ),
      subtitleStyle: TextStyle(color: AppColors.mutedOnDark, fontSize: 13),
    );
  }
}

class _IllustrativeMap extends StatelessWidget {
  const _IllustrativeMap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AppCardSurface(
        variant: AppCardVariant.information,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) => AspectRatio(
            // Leave vertical room for the wrapped explanatory copy on phones.
            aspectRatio: constraints.maxWidth < 300
                ? 1.0
                : constraints.maxWidth < 360
                ? 1.35
                : 1.55,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: Colors.white70,
                    size: 42,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Peta geografis belum tersedia',
                    textAlign: TextAlign.center,
                    style: AppTypography.sectionTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Sumber peta resmi belum terhubung. Zona, jalur, dan titik aman tidak ditampilkan tanpa data terverifikasi.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyCompact.copyWith(
                      color: AppColors.mutedOnDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapLevelLegend extends StatelessWidget {
  const _MapLevelLegend();

  static const levels = <({String label, Color color})>[
    (label: 'Level I · Normal', color: AppColors.normal),
    (label: 'Level II · Waspada', color: AppColors.warning),
    (label: 'Level III · Siaga', color: AppColors.watch),
    (label: 'Level IV · Awas', color: AppColors.danger),
  ];

  @override
  Widget build(BuildContext context) => AppCardSurface(
    variant: AppCardVariant.information,
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Arti Level Aktivitas',
          style: AppTypography.bodyLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth < 340
                ? constraints.maxWidth
                : (constraints.maxWidth - AppSpacing.md) / 2;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.xs,
              children: [
                for (final level in levels)
                  SizedBox(
                    width: itemWidth,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: AppSizes.iconSmall,
                          color: level.color,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            level.label,
                            softWrap: true,
                            style: AppTypography.bodyCompact.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Legenda ini menjelaskan kategori level, bukan status gunung tertentu.',
          style: AppTypography.caption.copyWith(color: AppColors.mutedOnDark),
        ),
      ],
    ),
  );
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
                          fontSize: 13,
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
  const _ActivityReportHeading({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Ink(
            height: AppSizes.minimumTapTarget,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: const Center(
              child: Text(
                'Laporan Aktivitas Gunung',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
    return AppCardSurface(
      variant: AppCardVariant.information,
      padding: const EdgeInsets.all(AppSpacing.sm),
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
                    fontSize: 13,
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

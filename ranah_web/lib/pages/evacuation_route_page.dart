import 'package:flutter/material.dart';

import '../data/evacuation_route_sample.dart';
import '../theme/ranah_theme.dart';
import '../widgets/illustrative_map.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';

class EvacuationRoutePage extends StatelessWidget {
  const EvacuationRoutePage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mobile = constraints.maxWidth < 700;
      final width = constraints.maxWidth > RanahLayout.maxContentWidth
          ? RanahLayout.maxContentWidth
          : constraints.maxWidth;
      final horizontalInset = mobile ? 12.0 : 28.0;
      final innerWidth = width - horizontalInset * 2;
      final mapHeight = mobile
          ? (constraints.maxWidth < 420 ? 220.0 : 270.0)
          : (MediaQuery.sizeOf(context).height * .43).clamp(340.0, 500.0);
      return RanahPageScrollLayout(
        maxContentWidth: width,
        horizontalInset: horizontalInset,
        title: _RouteBanner(maxContentWidth: innerWidth),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: RanahSpacing.md),
            Container(
              height: 48,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: RanahSpacing.xs),
              color: const Color(0xFF12304C),
              child: RanahBackButton(
                key: const ValueKey('evacuation-route-back'),
                onPressed: onBack,
              ),
            ),
            SizedBox(height: mobile ? RanahSpacing.lg : RanahSpacing.xl),
            SizedBox(
              height: mapHeight,
              child: const IllustrativeMap(
                padang: true,
                onSampleLocationTap: _ignoreMapTap,
              ),
            ),
            const SizedBox(height: RanahSpacing.sm),
            const _SimulationNotice(),
            const SizedBox(height: RanahSpacing.md),
            const _RouteDetailCard(),
          ],
        ),
      );
    },
  );
}

void _ignoreMapTap() {}

class _RouteBanner extends StatelessWidget {
  const _RouteBanner({required this.maxContentWidth});

  final double maxContentWidth;

  @override
  Widget build(BuildContext context) => RanahFullWidthTitleBackground(
    color: const Color(0xFF17003E),
    maxContentWidth: maxContentWidth,
    bottomBorder: const BorderSide(color: Color(0xFF263B65)),
    child: Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF17003E),
        border: Border(bottom: BorderSide(color: Color(0xFF263B65))),
      ),
      child: const Row(
        children: [
          Icon(Icons.alt_route_rounded, size: 28, color: Colors.white),
          SizedBox(width: RanahSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA BENCANA',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Color(0xFF91A8D0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Jalur Evakuasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Rute ilustratif · bukan arahan evakuasi resmi',
                  style: TextStyle(fontSize: 12, color: Color(0xFFC1C8D7)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SimulationNotice extends StatelessWidget {
  const _SimulationNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF59452D),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFB38B42)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Color(0xFFFFD37A)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Data rute, jarak, waktu, dan titik tujuan pada halaman ini adalah simulasi. Periksa arahan resmi setempat saat keadaan darurat.',
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _RouteDetailCard extends StatelessWidget {
  const _RouteDetailCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(RanahSpacing.md),
    decoration: BoxDecoration(
      color: const Color(0xFF174A7D),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF2580B5)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.route_rounded, color: Color(0xFF40B9D2), size: 20),
            SizedBox(width: RanahSpacing.sm),
            Expanded(
              child: Text(
                'Rute Evakuasi Terdekat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            _ExampleChip(),
          ],
        ),
        const SizedBox(height: RanahSpacing.md),
        _RouteEndpoint(
          number: '1',
          title: 'Lokasi awal',
          value: sampleEvacuationRoute.origin,
          color: const Color(0xFF42C8D7),
        ),
        const _RouteConnector(),
        _RouteEndpoint(
          number: '2',
          title: 'Tujuan evakuasi',
          value: sampleEvacuationRoute.destination,
          color: const Color(0xFFB080E6),
        ),
        const SizedBox(height: RanahSpacing.md),
        Wrap(
          spacing: RanahSpacing.sm,
          runSpacing: RanahSpacing.sm,
          children: [
            _RouteMetric(
              icon: Icons.warning_amber_rounded,
              label: 'Jenis bencana',
              value: sampleEvacuationRoute.hazard,
            ),
            _RouteMetric(
              icon: Icons.straighten_rounded,
              label: 'Jarak rute',
              value: sampleEvacuationRoute.distance,
            ),
            _RouteMetric(
              icon: Icons.directions_walk_rounded,
              label: 'Estimasi jalan kaki',
              value: sampleEvacuationRoute.walkingEstimate,
            ),
          ],
        ),
      ],
    ),
  );
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF765B2A),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'DATA SIMULASI',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}

class _RouteEndpoint extends StatelessWidget {
  const _RouteEndpoint({
    required this.number,
    required this.title,
    required this.value,
    required this.color,
  });

  final String number;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 21,
        height: 21,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          number,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFFC9D8E6)),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 10, top: 3, bottom: 3),
    child: SizedBox(
      height: 13,
      child: Align(
        alignment: Alignment.centerLeft,
        child: VerticalDivider(width: 1, thickness: 1, color: Colors.white38),
      ),
    ),
  );
}

class _RouteMetric extends StatelessWidget {
  const _RouteMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 150),
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF123E68),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF68C8DC)),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFFC7D2E0)),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

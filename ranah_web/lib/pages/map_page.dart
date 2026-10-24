import 'package:flutter/material.dart';

import '../data/map_sample_data.dart';
import '../theme/ranah_theme.dart';
import '../widgets/illustrative_map.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    required this.onActivityTap,
    required this.onMountainTap,
    super.key,
  });

  final VoidCallback onActivityTap;
  final ValueChanged<SampleMountain> onMountainTap;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _showPadang = false;

  void _showLocationNotice() {
    setState(() => _showPadang = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'GPS belum tersedia. Peta menampilkan lokasi contoh Padang, bukan lokasi aktual Anda.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobile = width < 700;
        final contentWidth = width > 1260 ? 1260.0 : width;
        final mapHeight = mobile
            ? (width < 420 ? 205.0 : 232.0)
            : (MediaQuery.sizeOf(context).height * .43).clamp(330.0, 510.0);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: contentWidth,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                mobile ? 12 : 28,
                0,
                mobile ? 12 : 28,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _MapTitleBanner(),
                  if (_showPadang)
                    _MapBackBar(
                      onBack: () => setState(() => _showPadang = false),
                    ),
                  SizedBox(height: mobile ? 10 : 18),
                  SizedBox(
                    height: mapHeight,
                    child: IllustrativeMap(
                      padang: _showPadang,
                      onSampleLocationTap: () =>
                          setState(() => _showPadang = true),
                    ),
                  ),
                  if (_showPadang)
                    _buildLocationDetail(mobile)
                  else
                    _buildMapActions(mobile),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapActions(bool mobile) => Padding(
    padding: EdgeInsets.fromLTRB(mobile ? 8 : 0, 14, mobile ? 8 : 0, 0),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final gap = mobile ? 12.0 : 20.0;
        final actionWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: 18,
          children: [
            _MapAction(
              width: actionWidth,
              icon: Icons.location_on_rounded,
              label: 'Temukan Lokasi Saya',
              description: 'Lihat lokasi dan informasi sekitar.',
              onTap: _showLocationNotice,
            ),
            _MapAction(
              width: actionWidth,
              icon: Icons.landscape_rounded,
              label: 'Laporan Aktivitas Gunung',
              description: 'Contoh daftar tingkat aktivitas gunung.',
              onTap: widget.onActivityTap,
            ),
          ],
        );
      },
    ),
  );

  Widget _buildLocationDetail(bool mobile) => Padding(
    padding: EdgeInsets.fromLTRB(mobile ? 4 : 0, 12, mobile ? 4 : 0, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _CurrentLocationCard(),
        const SizedBox(height: 14),
        const _SectionHeading(
          icon: Icons.alt_route_rounded,
          title: 'Jalur Evakuasi',
          subtitle: 'Rute ilustratif ke zona aman bencana',
        ),
        const SizedBox(height: 8),
        const _EvacuationRouteCard(),
        const SizedBox(height: 15),
        _SectionHeading(
          icon: Icons.landscape_outlined,
          title: 'Gunung Aktif',
          subtitle: 'Data gunung contoh · bukan status terkini',
          trailing: TextButton(
            onPressed: widget.onActivityTap,
            child: const Text('Lihat daftar'),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            final cardWidth = mobile ? box.maxWidth : (box.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                for (final mountain in sampleMountains)
                  SizedBox(
                    width: cardWidth,
                    child: _MountainCard(
                      mountain: mountain,
                      onTap: () => widget.onMountainTap(mountain),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 15),
        const _SectionHeading(
          icon: Icons.monitor_heart_outlined,
          title: 'Potensi Bencana di Lokasi',
          subtitle: 'Contoh potensi berdasarkan karakter wilayah',
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, box) {
            final cardWidth = mobile ? box.maxWidth : (box.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hazard in sampleHazards)
                  SizedBox(
                    width: cardWidth,
                    child: _HazardCard(hazard: hazard),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class _MapTitleBanner extends StatelessWidget {
  const _MapTitleBanner();

  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xFF17003E),
      border: Border(bottom: BorderSide(color: Color(0xFF263B65))),
    ),
    child: const Row(
      children: [
        Icon(Icons.landscape_outlined, size: 28, color: Colors.white),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PETA & ZONA BAHAYA',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1,
                  color: Color(0xFF91A8D0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Peta dan Jalur Evakuasi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                'Informasi contoh wilayah Padang dan Sumatera Barat',
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

class _MapBackBar extends StatelessWidget {
  const _MapBackBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    alignment: Alignment.centerLeft,
    color: const Color(0xFF12304C),
    child: TextButton.icon(
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, size: 14),
      label: const Text('Kembali', style: TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(
        foregroundColor: RanahColors.ink,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
    ),
  );
}

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 17),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: RanahColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFD1DCE9), fontSize: 11),
        ),
      ],
    ),
  );
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF174476),
      borderRadius: BorderRadius.circular(9),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: const Row(
      children: [
        Icon(Icons.location_pin, color: Color(0xFFFF3941), size: 25),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LOKASI CONTOH',
                style: TextStyle(
                  fontSize: 9,
                  color: Color(0xFFC8D7E8),
                  letterSpacing: .6,
                ),
              ),
              Text(
                'UNP, Air Tawar, Kota Padang',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                'Bukan lokasi perangkat Anda',
                style: TextStyle(fontSize: 10, color: Color(0xFFD1DCE9)),
              ),
            ],
          ),
        ),
        Icon(Icons.my_location, size: 19, color: Colors.white70),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF0F5473),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1884A4)),
        ),
        child: Icon(icon, color: const Color(0xFF45C6D5), size: 19),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Color(0xFFC7D2E0)),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class _EvacuationRouteCard extends StatelessWidget {
  const _EvacuationRouteCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF174A7D),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF2580B5)),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.alt_route, color: Color(0xFF40B9D2), size: 19),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rute Evakuasi Terdekat',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Rute contoh · bukan arahan evakuasi resmi',
                    style: TextStyle(fontSize: 9, color: Color(0xFFC7D2E0)),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 9),
        _RouteStop(title: 'Lokasi awal', name: 'Universitas Negeri Padang'),
        _RouteStop(
          title: 'Tujuan contoh',
          name: 'Titik aman ilustratif · Jl. Bypass',
        ),
      ],
    ),
  );
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({required this.title, required this.name});

  final String title;
  final String name;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 3, bottom: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 9, top: 2),
          child: Icon(
            Icons.radio_button_checked,
            color: Color(0xFF43C9D5),
            size: 12,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 9, color: Color(0xFFC9D8E6)),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _MountainCard extends StatelessWidget {
  const _MountainCard({required this.mountain, required this.onTap});

  final SampleMountain mountain;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF174A7D),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        constraints: const BoxConstraints(minHeight: 78),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF286D9C)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: const LinearGradient(
                  colors: [Color(0xFF487A66), Color(0xFFB77748)],
                ),
              ),
              child: const Icon(Icons.terrain, color: Colors.white70, size: 31),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    mountain.name,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    mountain.level,
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(mountain.color),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    mountain.distance,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFC7D2E0),
                    ),
                  ),
                  const Text(
                    'DATA DUMMY',
                    style: TextStyle(fontSize: 8, color: Color(0xFFE6B866)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    ),
  );
}

class _HazardCard extends StatelessWidget {
  const _HazardCard({required this.hazard});

  final SampleHazard hazard;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 63),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF174A7D),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFF286D9C)),
    ),
    child: Row(
      children: [
        Icon(_iconFor(hazard.icon), color: Color(hazard.color), size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hazard.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                hazard.description,
                style: const TextStyle(fontSize: 9, color: Color(0xFFC7D2E0)),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  IconData _iconFor(String icon) => switch (icon) {
    'tsunami' => Icons.waves_rounded,
    'flood' => Icons.water_rounded,
    _ => Icons.vibration_rounded,
  };
}

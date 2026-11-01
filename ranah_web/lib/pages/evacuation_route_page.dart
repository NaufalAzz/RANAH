import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/browser_location.dart';
import '../services/osm_assembly_point_repository.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';
import '../widgets/ranah_header.dart';

typedef OsmReferenceLoader = Future<OsmAssemblyPointDataset> Function();

class EvacuationRoutePage extends StatefulWidget {
  const EvacuationRoutePage({
    required this.onBack,
    required this.currentLocation,
    this.repository,
    this.dataLoader,
    this.tilesEnabled = true,
    super.key,
  });

  final VoidCallback onBack;
  final BrowserLocation? currentLocation;
  final OsmAssemblyPointRepository? repository;
  final OsmReferenceLoader? dataLoader;
  final bool tilesEnabled;

  @override
  State<EvacuationRoutePage> createState() => _EvacuationRoutePageState();
}

class _EvacuationRoutePageState extends State<EvacuationRoutePage> {
  OsmAssemblyPointRepository? _ownedRepository;
  OsmAssemblyPointDataset? _dataset;
  OsmAssemblyPoint? _selected;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.repository == null && widget.dataLoader == null) {
      _ownedRepository = OsmAssemblyPointRepository();
    }
    _load();
  }

  @override
  void dispose() {
    _ownedRepository?.close();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dataset =
          await (widget.dataLoader?.call() ??
              (widget.repository ?? _ownedRepository!).load());
      if (!mounted) return;
      setState(() {
        _dataset = dataset;
        _selected = dataset.features.isEmpty ? null : dataset.features.first;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

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
          ? (constraints.maxWidth < 420 ? 250.0 : 310.0)
          : (MediaQuery.sizeOf(context).height * .48).clamp(360.0, 560.0);

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
                onPressed: widget.onBack,
              ),
            ),
            SizedBox(height: mobile ? RanahSpacing.lg : RanahSpacing.xl),
            SizedBox(height: mapHeight, child: _buildMap()),
            const SizedBox(height: RanahSpacing.sm),
            const _AcademicRouteNotice(),
            const SizedBox(height: RanahSpacing.md),
            if (_loading)
              const _StatusCard(
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              )
            else if (_error != null)
              _StatusCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Referensi OpenStreetMap tidak dapat dimuat.',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Periksa koneksi ke API RANAH, lalu coba lagi.',
                      style: TextStyle(color: Color(0xFFC7D2E0)),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const ValueKey('retry-osm-references'),
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              )
            else if (_dataset case final dataset?) ...[
              if (dataset.features.isEmpty)
                const _StatusCard(
                  child: Text('Tidak ada fitur referensi pada ekspor OSM ini.'),
                )
              else ...[
                if (_selected case final selected?)
                  _FeatureDetailCard(feature: selected),
                const SizedBox(height: RanahSpacing.sm),
                for (final feature in dataset.features) ...[
                  _FeatureListCard(
                    feature: feature,
                    selected: feature.id == _selected?.id,
                    onTap: () => setState(() => _selected = feature),
                  ),
                  const SizedBox(height: RanahSpacing.sm),
                ],
                _SourceAndCoverageCard(metadata: dataset.metadata),
              ],
            ],
          ],
        ),
      );
    },
  );

  Widget _buildMap() {
    if (_loading || _error != null || _dataset == null) {
      return const _StatusCard(
        child: Center(
          child: Text(
            'Peta referensi OSM sedang dimuat.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final dataset = _dataset!;
    if (dataset.features.isEmpty) {
      return const _StatusCard(
        child: Center(
          child: Text(
            'Tidak ada geometri untuk ditampilkan.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final mapCenter = _referenceCenter(dataset.features);
    final userLocation = widget.currentLocation;
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF102B43)),
        child: FlutterMap(
          key: const ValueKey('osm-assembly-points-map'),
          options: MapOptions(
            initialCenter: mapCenter,
            initialZoom: 16,
            minZoom: 3,
            maxZoom: 19,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            if (widget.tilesEnabled)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ranah.web',
                maxNativeZoom: 19,
              ),
            PolygonLayer(
              polygons: [
                for (final feature in dataset.features)
                  if (feature.geometryType == 'Polygon')
                    Polygon(
                      points: feature.rings.first,
                      holePointsList: feature.rings.skip(1).toList(),
                      color: const Color(0xFF40B9D2).withValues(
                        alpha: feature.id == _selected?.id ? .38 : .23,
                      ),
                      borderColor: const Color(0xFF67D3E3),
                      borderStrokeWidth: 2,
                    ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (final feature in dataset.features)
                  Marker(
                    point: feature.displayPosition,
                    width: 52,
                    height: 58,
                    child: Semantics(
                      button: true,
                      label:
                          '${feature.name ?? 'Objek OSM'}, ${feature.geometryType == 'Point' ? 'titik' : 'area referensi'}, belum diverifikasi',
                      child: GestureDetector(
                        key: ValueKey('osm-reference-${feature.id}'),
                        onTap: () => setState(() => _selected = feature),
                        child: Icon(
                          feature.geometryType == 'Point'
                              ? Icons.location_on
                              : Icons.crop_square_rounded,
                          color: feature.id == _selected?.id
                              ? const Color(0xFFFFD37A)
                              : const Color(0xFF51C6D7),
                          size: 42,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (userLocation?.isValid == true)
                  Marker(
                    point: LatLng(
                      userLocation!.latitude,
                      userLocation.longitude,
                    ),
                    width: 48,
                    height: 52,
                    child: Semantics(
                      label: 'Lokasi perangkat saat ini',
                      child: Icon(
                        Icons.location_pin,
                        key: ValueKey('device-location-marker'),
                        color: Color(0xFFFF3941),
                        size: 44,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (widget.tilesEnabled)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            const Positioned(
              top: 8,
              left: 8,
              child: _MapBadge(text: 'REFERENSI OSM'),
            ),
          ],
        ),
      ),
    );
  }
}

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
                  'Referensi OSM · belum diverifikasi',
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

class _AcademicRouteNotice extends StatelessWidget {
  const _AcademicRouteNotice();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF59452D),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xFFB38B42)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 17, color: Color(0xFFFFD37A)),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Simulasi Rute Akademik — Bukan Jalur Evakuasi Resmi. Rute hanya dapat diminta secara eksplisit dari peta utama jika layanan ORS pada server tersedia. Referensi ini bukan penetapan titik aman.',
            style: TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _FeatureDetailCard extends StatelessWidget {
  const _FeatureDetailCard({required this.feature});

  final OsmAssemblyPoint feature;

  @override
  Widget build(BuildContext context) {
    final location = feature.displayPosition;
    final isArea = feature.geometryType == 'Polygon';
    final attributes = feature.attributes;
    return Container(
      key: ValueKey('osm-feature-detail-${feature.id}'),
      padding: const EdgeInsets.all(RanahSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF174A7D),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF2580B5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isArea ? Icons.crop_square_rounded : Icons.location_on,
                color: const Color(0xFF68D3E3),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  feature.name ?? 'Objek OSM tanpa nama',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            feature.status,
            style: const TextStyle(
              color: Color(0xFFFFD37A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text('Tipe geometri: ${isArea ? 'area Polygon' : 'Point'}'),
          Text('ID OSM: ${feature.id}'),
          Text(
            'Koordinat tampilan: ${location.latitude.toStringAsFixed(7)}, ${location.longitude.toStringAsFixed(7)}',
          ),
          if (isArea)
            const Text(
              'Penanda area hanya untuk memilih geometri; bukan pintu masuk atau akses resmi.',
              style: TextStyle(color: Color(0xFFC7D2E0), fontSize: 12),
            ),
          Text(
            'Tag emergency: ${attributes['emergency'] ?? 'tidak tercantum'}',
          ),
          Text(
            'Kesesuaian tsunami: ${attributes['assembly_point_tsunami'] ?? 'tidak dicantumkan pada ekspor'}',
          ),
          Text('Operator: ${attributes['operator'] ?? 'tidak dicantumkan'}'),
          Text('Akses: ${attributes['access'] ?? 'tidak dicantumkan'}'),
          Text(
            'Waktu pembaruan OSM: ${attributes['tanggal_pembaruan'] ?? 'tidak tersedia'}',
          ),
          Text(
            'Sumber: ${attributes['source'] ?? 'tag sumber tidak tercantum'}',
          ),
          const Text(
            'Jenis bencana tidak ditetapkan dari tag yang tersedia.',
            style: TextStyle(color: Color(0xFFC7D2E0), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FeatureListCard extends StatelessWidget {
  const _FeatureListCard({
    required this.feature,
    required this.selected,
    required this.onTap,
  });

  final OsmAssemblyPoint feature;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF1C588A) : const Color(0xFF174A7D),
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      key: ValueKey('select-osm-reference-${feature.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.all(RanahSpacing.sm),
        child: Row(
          children: [
            Icon(
              feature.geometryType == 'Polygon'
                  ? Icons.crop_square_rounded
                  : Icons.location_on,
              color: const Color(0xFF68D3E3),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.name ?? 'Objek OSM tanpa nama',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${feature.geometryType} · ${feature.status}',
                    style: const TextStyle(
                      color: Color(0xFFC7D2E0),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.center_focus_strong,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceAndCoverageCard extends StatelessWidget {
  const _SourceAndCoverageCard({required this.metadata});

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(RanahSpacing.md),
    decoration: BoxDecoration(
      color: const Color(0xFF123E68),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF286D9C)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sumber dan cakupan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text('${metadata['sumber']}'),
        Text('${metadata['atribusi']} · ${metadata['lisensi']}'),
        SelectableText('${metadata['url_lisensi']}'),
        const SizedBox(height: 6),
        Text('${metadata['cakupan']}'),
        Text(
          'Tanggal ekspor: ${metadata['tanggal_export'] ?? 'tidak tersedia'}',
        ),
        const Text(
          'OSM adalah referensi pemetaan terbuka; data ini bukan daftar fasilitas BPBD yang telah diperiksa.',
          style: TextStyle(color: Color(0xFFC7D2E0), fontSize: 12),
        ),
      ],
    ),
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 92),
    padding: const EdgeInsets.all(RanahSpacing.md),
    decoration: BoxDecoration(
      color: const Color(0xFF174A7D),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF286D9C)),
    ),
    child: child,
  );
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE6102639),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: const Color(0xFF67D3E3)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

LatLng _referenceCenter(List<OsmAssemblyPoint> features) {
  var latitude = 0.0;
  var longitude = 0.0;
  for (final feature in features) {
    latitude += feature.displayPosition.latitude;
    longitude += feature.displayPosition.longitude;
  }
  return LatLng(latitude / features.length, longitude / features.length);
}

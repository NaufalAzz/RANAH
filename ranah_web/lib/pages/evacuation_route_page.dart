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
      final mapHeight = RanahMapLayout.heightFor(
        screenWidth: constraints.maxWidth,
        screenHeight: MediaQuery.sizeOf(context).height,
      );

      return RanahPageScrollLayout(
        maxContentWidth: width,
        horizontalInset: horizontalInset,
        title: _RouteBanner(maxContentWidth: width),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: RanahSpacing.md),
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                horizontal: RanahSpacing.md,
                vertical: RanahSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF12304C),
                borderRadius: BorderRadius.circular(RanahRadii.sm),
              ),
              child: RanahBackButton(
                key: const ValueKey('evacuation-route-back'),
                onPressed: widget.onBack,
              ),
            ),
            SizedBox(height: mobile ? RanahSpacing.lg : RanahSpacing.xl),
            RanahFullBleed(height: mapHeight, child: _buildMap()),
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
      borderRadius: BorderRadius.circular(RanahRadii.md),
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
      constraints: const BoxConstraints(
        minHeight: RanahPageHeaderStyle.minHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: RanahPageHeaderStyle.horizontalPadding,
        vertical: RanahPageHeaderStyle.verticalPadding,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF17003E),
        border: Border(bottom: BorderSide(color: Color(0xFF263B65))),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.alt_route_rounded,
            size: RanahPageHeaderStyle.iconSize,
            color: Colors.white,
          ),
          SizedBox(width: RanahPageHeaderStyle.iconGap),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIAGA BENCANA',
                  style: RanahPageHeaderStyle.kicker,
                ),
                Text(
                  'Jalur Evakuasi',
                  style: RanahPageHeaderStyle.title,
                ),
                Text(
                  'Referensi OSM · belum diverifikasi',
                  style: RanahPageHeaderStyle.subtitle,
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
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF59452D),
      borderRadius: BorderRadius.circular(RanahRadii.sm),
      border: Border.all(color: const Color(0xFFB38B42)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 19, color: Color(0xFFFFD37A)),
        SizedBox(width: RanahSpacing.sm),
        Expanded(
          child: Text(
            'Simulasi Rute Akademik — Bukan Jalur Evakuasi Resmi. Rute hanya dapat diminta secara eksplisit dari peta utama jika layanan ORS pada server tersedia. Referensi ini bukan penetapan titik aman.',
            style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
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
      padding: const EdgeInsets.all(RanahSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF174A7D),
        borderRadius: BorderRadius.circular(RanahRadii.md),
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
          const SizedBox(height: RanahSpacing.sm),
          Text(
            feature.status,
            style: const TextStyle(
              color: Color(0xFFFFD37A),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RanahSpacing.xs),
          _FeatureMetadataLine(
            label: 'Tipe geometri',
            value: isArea ? 'Area Polygon' : 'Point',
          ),
          _FeatureMetadataLine(label: 'ID OSM', value: feature.id),
          _FeatureMetadataLine(
            label: 'Koordinat tampilan',
            value:
                '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
          ),
          if (isArea)
            const Text(
              'Penanda area hanya untuk memilih geometri; bukan pintu masuk atau akses resmi.',
              style: TextStyle(
                color: Color(0xFFC7D2E0),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          const SizedBox(height: RanahSpacing.sm),
          _FeatureMetadataLine(
            label: 'Tag emergency',
            value: '${attributes['emergency'] ?? 'tidak tercantum'}',
          ),
          _FeatureMetadataLine(
            label: 'Kesesuaian tsunami',
            value:
                '${attributes['assembly_point_tsunami'] ?? 'tidak dicantumkan pada ekspor'}',
          ),
          _FeatureMetadataLine(
            label: 'Operator',
            value: '${attributes['operator'] ?? 'tidak dicantumkan'}',
          ),
          _FeatureMetadataLine(
            label: 'Akses',
            value: '${attributes['access'] ?? 'tidak dicantumkan'}',
          ),
          _FeatureMetadataLine(
            label: 'Waktu pembaruan OSM',
            value: '${attributes['tanggal_pembaruan'] ?? 'tidak tersedia'}',
          ),
          _FeatureMetadataLine(
            label: 'Sumber',
            value: '${attributes['source'] ?? 'tag sumber tidak tercantum'}',
          ),
          const Text(
            'Jenis bencana tidak ditetapkan dari tag yang tersedia.',
            style: TextStyle(
              color: Color(0xFFC7D2E0),
              fontSize: 13,
              height: 1.4,
            ),
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
    borderRadius: BorderRadius.circular(RanahRadii.md),
    child: InkWell(
      key: ValueKey('select-osm-reference-${feature.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(RanahRadii.md),
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

class _FeatureMetadataLine extends StatelessWidget {
  const _FeatureMetadataLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: RanahSpacing.xs),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(
              color: Color(0xFFC7D8E8),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: value),
        ],
      ),
      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
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
      borderRadius: BorderRadius.circular(RanahRadii.md),
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
      borderRadius: BorderRadius.circular(RanahRadii.md),
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
      borderRadius: BorderRadius.circular(RanahRadii.sm),
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

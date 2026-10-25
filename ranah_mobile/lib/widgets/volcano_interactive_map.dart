import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

const _levelColors = <String, Color>{
  'i': Color(0xFF36C78B),
  'ii': Color(0xFFF2C94C),
  'iii': Color(0xFFF2994A),
  'iv': Color(0xFFEB5757),
  'unknown': Color(0xFF9AA7B5),
};

const _simulationZoneColors = <String, Color>{
  'I': Color(0xFF39A9DB),
  'II': Color(0xFF9566D9),
  'III': Color(0xFFE85D9E),
};

const _simulationZoneFills = <String, Color>{
  'I': Color(0x5539A9DB),
  'II': Color(0x559566D9),
  'III': Color(0x55E85D9E),
};

const simulatedKrbWarning =
    'SIMULASI \u2014 BUKAN PETA KRB RESMI. Tidak untuk panduan evakuasi nyata.';

@immutable
class VolcanoSimulationPolygon {
  const VolcanoSimulationPolygon({
    required this.volcano,
    required this.zone,
    required this.polygon,
    this.official = false,
    this.sourceYear,
  });

  final String volcano;
  final String zone;
  final Polygon polygon;
  final bool official;
  final int? sourceYear;
}

@immutable
class _KrbOverlayData {
  const _KrbOverlayData({
    required this.official,
    required this.simulated,
    this.officialError,
    this.simulatedError,
  });

  final List<VolcanoSimulationPolygon> official;
  final List<VolcanoSimulationPolygon> simulated;
  final String? officialError;
  final String? simulatedError;
}

/// Parses synthetic demo polygons only. GeoJSON coordinates are [longitude,
/// latitude], while [LatLng] takes latitude first.
List<VolcanoSimulationPolygon> parseSimulatedKrbGeoJson(String source) {
  return _parseKrbGeoJson(source, official: false);
}

/// Parses only verified polygons exported from the official BIG KRB area layer.
List<VolcanoSimulationPolygon> parseOfficialKrbGeoJson(String source) {
  return _parseKrbGeoJson(source, official: true);
}

List<VolcanoSimulationPolygon> _parseKrbGeoJson(
  String source, {
  required bool official,
}) {
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic> ||
      decoded['type'] != 'FeatureCollection') {
    throw const FormatException('GeoJSON must be a FeatureCollection.');
  }

  final metadata = decoded['metadata'];
  if (metadata is! Map<String, dynamic>) {
    throw const FormatException('GeoJSON metadata is missing.');
  }
  if (official) {
    if (metadata['status'] != 'OFFICIAL_BIG_LAYER_GEOMETRY' ||
        metadata['source_url'] != _bigKrbLayerUrl ||
        metadata['spatial_reference'] != 'EPSG:4326') {
      throw const FormatException('GeoJSON is not a verified BIG KRB export.');
    }
  } else if (metadata['status'] != 'SYNTHETIC_DEMO_ONLY' ||
      metadata['is_official_krb'] != false ||
      metadata['is_for_evacuation_guidance'] != false) {
    throw const FormatException('GeoJSON is not marked as simulation-only.');
  }

  final features = decoded['features'];
  if (features is! List) {
    throw const FormatException('GeoJSON features must be a list.');
  }

  final result = <VolcanoSimulationPolygon>[];
  for (final feature in features) {
    if (feature is! Map<String, dynamic> || feature['type'] != 'Feature') {
      continue;
    }
    final properties = feature['properties'];
    final geometry = feature['geometry'];
    if (properties is! Map<String, dynamic> ||
        geometry is! Map<String, dynamic> ||
        geometry['type'] != 'Polygon' && geometry['type'] != 'MultiPolygon') {
      continue;
    }

    final isVerifiedOfficial =
        official &&
        properties['verification_status'] == 'VERIFIED_NAME_AND_LOCATION';
    final isSimulation =
        !official &&
        properties['data_status'] == 'SYNTHETIC_DEMO_ONLY' &&
        properties['is_official_krb'] == false &&
        properties['is_for_evacuation_guidance'] == false;
    final volcano = official
        ? properties['database_volcano_name']
        : properties['volcano'];
    final zone = official
        ? _officialZone(properties['indga']?.toString())
        : _simulationZone(properties['zone_class']?.toString());
    final coordinates = geometry['coordinates'];
    if ((!isVerifiedOfficial && !isSimulation) ||
        volcano is! String ||
        volcano.trim().isEmpty ||
        zone == null ||
        coordinates is! List ||
        coordinates.isEmpty) {
      continue;
    }

    final polygonCoordinates = geometry['type'] == 'Polygon'
        ? [coordinates]
        : coordinates;
    for (final polygonCoordinate in polygonCoordinates) {
      if (polygonCoordinate is! List || polygonCoordinate.isEmpty) continue;
      final rings = polygonCoordinate.map(_parseRing).toList();
      if (rings.any((ring) => ring == null)) continue;
      final validRings = rings.cast<List<LatLng>>();
      final borderColor = _simulationZoneColors[zone]!;
      result.add(
        VolcanoSimulationPolygon(
          volcano: volcano.trim(),
          zone: zone,
          official: official,
          sourceYear: official
              ? int.tryParse(properties['thterbit']?.toString() ?? '')
              : null,
          polygon: Polygon(
            points: validRings.first,
            holePointsList: validRings.length > 1
                ? validRings.skip(1).toList(growable: false)
                : null,
            color: _simulationZoneFills[zone],
            borderColor: borderColor,
            borderStrokeWidth: 2,
          ),
        ),
      );
    }
  }

  return List.unmodifiable(result);
}

const _bigKrbLayerUrl =
    'https://kspservices.big.go.id/satupeta/rest/services/PUBLIK/'
    'SUMBER_DAYA_ALAM_DAN_LINGKUNGAN/MapServer/11';

String? _officialZone(String? value) => switch (value) {
  '1' => 'I',
  '2' => 'II',
  '3' => 'III',
  _ => null,
};

List<LatLng>? _parseRing(dynamic coordinates) {
  if (coordinates is! List || coordinates.length < 4) return null;
  final points = <LatLng>[];
  for (final coordinate in coordinates) {
    if (coordinate is! List || coordinate.length < 2) return null;
    final longitude = coordinate[0];
    final latitude = coordinate[1];
    if (longitude is! num || latitude is! num) return null;
    final lat = latitude.toDouble();
    final lon = longitude.toDouble();
    if (!lat.isFinite ||
        !lon.isFinite ||
        lat < -90 ||
        lat > 90 ||
        lon < -180 ||
        lon > 180) {
      return null;
    }
    points.add(LatLng(lat, lon));
  }
  if (points.first != points.last) return null;
  return List.unmodifiable(points);
}

String? _simulationZone(String? value) => switch (value?.toUpperCase()) {
  'SIMULASI_I' => 'I',
  'SIMULASI_II' => 'II',
  'SIMULASI_III' => 'III',
  _ => null,
};

@immutable
class VolcanoMapMarker {
  const VolcanoMapMarker({
    required this.id,
    required this.name,
    required this.region,
    required this.status,
    required this.updatedAt,
    required this.position,
    required this.raw,
  });

  final int id;
  final String name;
  final String region;
  final String status;
  final String? updatedAt;
  final LatLng position;
  final Map<String, dynamic> raw;

  String get levelKey => volcanoLevelKey(status);
  Color get color => _levelColors[levelKey] ?? _levelColors['unknown']!;
}

/// Returns a marker only when both coordinates are in range and explicitly
/// marked as verified against a geospatial source.
VolcanoMapMarker? volcanoMapMarkerFrom(Map<String, dynamic> raw) {
  if (raw['status_validasi_koordinat']?.toString().toLowerCase() !=
      'terverifikasi') {
    return null;
  }
  final id = int.tryParse(raw['id']?.toString() ?? '');
  final latitude = double.tryParse(raw['latitude']?.toString() ?? '');
  final longitude = double.tryParse(raw['longitude']?.toString() ?? '');
  if (id == null ||
      latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }
  return VolcanoMapMarker(
    id: id,
    name: _display(raw['nama'], 'Gunung api'),
    region: [raw['kabupaten'], raw['provinsi']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .join(', '),
    status: _display(raw['status_aktivitas'], 'Belum diketahui'),
    updatedAt: raw['waktu_pengambilan']?.toString(),
    position: LatLng(latitude, longitude),
    raw: raw,
  );
}

String volcanoLevelKey(String? value) {
  final match = RegExp(
    r'\blevel\s*(iv|iii|ii|i|4|3|2|1)\b',
    caseSensitive: false,
  ).firstMatch(value ?? '');
  return switch (match?.group(1)?.toLowerCase()) {
    '1' || 'i' => 'i',
    '2' || 'ii' => 'ii',
    '3' || 'iii' => 'iii',
    '4' || 'iv' => 'iv',
    _ => 'unknown',
  };
}

class VolcanoInteractiveMap extends StatefulWidget {
  const VolcanoInteractiveMap({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onOpenDetail,
    this.tilesEnabled = true,
    this.officialPolygonsForTest,
    this.simulationPolygonsForTest,
  });

  final List<Map<String, dynamic>> items;
  final int selectedId;
  final ValueChanged<Map<String, dynamic>> onOpenDetail;
  final bool tilesEnabled;
  final Future<List<VolcanoSimulationPolygon>>? officialPolygonsForTest;
  final Future<List<VolcanoSimulationPolygon>>? simulationPolygonsForTest;

  @override
  State<VolcanoInteractiveMap> createState() => _VolcanoInteractiveMapState();
}

class _VolcanoInteractiveMapState extends State<VolcanoInteractiveMap> {
  late Future<_KrbOverlayData> _overlayData;

  @override
  void initState() {
    super.initState();
    _setOverlayDataFuture();
  }

  @override
  void didUpdateWidget(covariant VolcanoInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.officialPolygonsForTest != widget.officialPolygonsForTest ||
        oldWidget.simulationPolygonsForTest !=
            widget.simulationPolygonsForTest) {
      _setOverlayDataFuture();
    }
  }

  void _setOverlayDataFuture() {
    _overlayData = _loadOverlayData();
  }

  Future<_KrbOverlayData> _loadOverlayData() async {
    List<VolcanoSimulationPolygon> official = const [];
    List<VolcanoSimulationPolygon> simulated = const [];
    String? officialError;
    String? simulatedError;
    try {
      official =
          await (widget.officialPolygonsForTest ?? _loadOfficialPolygons());
    } catch (_) {
      officialError = 'Poligon KRB BIG tidak dapat dimuat.';
    }
    try {
      simulated =
          await (widget.simulationPolygonsForTest ?? _loadSimulationPolygons());
    } catch (_) {
      simulatedError = 'Poligon simulasi tidak dapat dimuat.';
    }
    return _KrbOverlayData(
      official: official,
      simulated: simulated,
      officialError: officialError,
      simulatedError: simulatedError,
    );
  }

  Future<List<VolcanoSimulationPolygon>> _loadOfficialPolygons() async {
    final source = await rootBundle.loadString(
      'assets/geojson/ranah_krb_big_terverifikasi.geojson',
    );
    return parseOfficialKrbGeoJson(source);
  }

  Future<List<VolcanoSimulationPolygon>> _loadSimulationPolygons() async {
    final source = await rootBundle.loadString(
      'assets/geojson/ranah_krb_simulasi.geojson',
    );
    return parseSimulatedKrbGeoJson(source);
  }

  @override
  Widget build(BuildContext context) {
    final markers = widget.items
        .map(volcanoMapMarkerFrom)
        .whereType<VolcanoMapMarker>()
        .toList(growable: false);
    final selected = markers.where((marker) => marker.id == widget.selectedId);
    final center = selected.isNotEmpty
        ? selected.first.position
        : const LatLng(-2.5, 118);
    final selectedVolcano = selected.isNotEmpty ? selected.first.name : null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102B43),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF45627B)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 270,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: selected.isNotEmpty ? 7 : 4,
                    minZoom: 3,
                    maxZoom: 18,
                  ),
                  children: [
                    if (widget.tilesEnabled)
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ranah_mobile',
                        maxNativeZoom: 19,
                      ),
                    FutureBuilder<_KrbOverlayData>(
                      future: _overlayData,
                      builder: (context, snapshot) {
                        final data = snapshot.data;
                        final official = (data?.official ?? const [])
                            .where(
                              (entry) =>
                                  _sameVolcano(entry.volcano, selectedVolcano),
                            )
                            .toList(growable: false);
                        final polygons = official.isNotEmpty
                            ? official
                            : (data?.simulated ?? const [])
                                  .where(
                                    (entry) => _sameVolcano(
                                      entry.volcano,
                                      selectedVolcano,
                                    ),
                                  )
                                  .toList(growable: false);
                        if (polygons.isEmpty) return const SizedBox.shrink();
                        return PolygonLayer(
                          polygons: polygons
                              .map((entry) => entry.polygon)
                              .toList(growable: false),
                        );
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        for (final marker in markers)
                          Marker(
                            point: marker.position,
                            width: 46,
                            height: 54,
                            child: Semantics(
                              button: true,
                              label:
                                  '${marker.name}, ${marker.status}, ${marker.region}',
                              child: GestureDetector(
                                key: ValueKey('volcano-marker-${marker.id}'),
                                onTap: () => _showMarker(context, marker),
                                child: Icon(
                                  Icons.location_on,
                                  color: marker.color,
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
                      ],
                    ),
                    if (widget.tilesEnabled)
                      RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution(
                            '© OpenStreetMap contributors',
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.openstreetmap.org/copyright',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!widget.tilesEnabled)
                  const IgnorePointer(
                    child: Center(
                      child: Text(
                        'Latar peta membutuhkan koneksi internet',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (markers.isEmpty)
                  const Center(
                    child: Card(
                      color: Color(0xE6102639),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          'Belum ada koordinat terverifikasi untuk ditandai.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: const [
                    _LegendItem(label: 'Level I · Normal', level: 'i'),
                    _LegendItem(label: 'Level II · Waspada', level: 'ii'),
                    _LegendItem(label: 'Level III · Siaga', level: 'iii'),
                    _LegendItem(label: 'Level IV · Awas', level: 'iv'),
                    _LegendItem(label: 'Tidak diketahui', level: 'unknown'),
                  ],
                ),
                FutureBuilder<_KrbOverlayData>(
                  future: _overlayData,
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    if (data == null) return const SizedBox.shrink();
                    final official = data.official
                        .where(
                          (entry) =>
                              _sameVolcano(entry.volcano, selectedVolcano),
                        )
                        .toList(growable: false);
                    final polygons = official.isNotEmpty
                        ? official
                        : data.simulated
                              .where(
                                (entry) => _sameVolcano(
                                  entry.volcano,
                                  selectedVolcano,
                                ),
                              )
                              .toList(growable: false);
                    if (polygons.isEmpty) {
                      if (data.officialError != null ||
                          data.simulatedError != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data.officialError ?? data.simulatedError!,
                            style: const TextStyle(color: Color(0xFFFFB4AB)),
                          ),
                        );
                      }
                      if (selectedVolcano == null) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Geometri KRB terverifikasi belum tersedia untuk $selectedVolcano.',
                          style: const TextStyle(
                            color: Color(0xFFD5E2ED),
                            fontSize: 11,
                          ),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _SimulationLegendItem(
                                label: official.isNotEmpty
                                    ? 'KRB I · BIG'
                                    : 'Zona I simulasi',
                                zone: 'I',
                              ),
                              _SimulationLegendItem(
                                label: official.isNotEmpty
                                    ? 'KRB II · BIG'
                                    : 'Zona II simulasi',
                                zone: 'II',
                              ),
                              _SimulationLegendItem(
                                label: official.isNotEmpty
                                    ? 'KRB III · BIG'
                                    : 'Zona III simulasi',
                                zone: 'III',
                              ),
                            ],
                          ),
                          if (official.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                'Sumber BIG MapServer 11 · tahun data: ${_sourceYears(official)}. Generalisasi untuk tampilan peta.',
                                style: const TextStyle(
                                  color: Color(0xFFB8C7D4),
                                  fontSize: 10,
                                ),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                simulatedKrbWarning,
                                style: TextStyle(
                                  color: Color(0xFFFFD166),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 9),
                Text(
                  '${markers.length} dari ${widget.items.length} gunung memiliki '
                  'koordinat BIG yang terverifikasi. Gunung lain tidak '
                  'dipetakan sampai kecocokannya terkonfirmasi.',
                  style: const TextStyle(
                    color: Color(0xFFD5E2ED),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 4),
                const Text(
                  'Status aktivitas berasal dari MAGMA. Data gunung tersimpan '
                  'dapat dibuka offline; tile latar peta memerlukan internet. '
                  'Poligon resmi ditampilkan hanya jika identitas dan lokasinya terverifikasi; selain itu peta dapat memakai ilustrasi simulasi berlabel.',
                  style: TextStyle(
                    color: Color(0xFFB8C7D4),
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMarker(BuildContext context, VolcanoMapMarker marker) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF142B40),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                marker.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                marker.region,
                style: const TextStyle(color: Colors.white70),
              ),
              Text(marker.status, style: TextStyle(color: marker.color)),
              Text(
                'Diperbarui: ${_formatTime(marker.updatedAt)}',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              if (marker.id != widget.selectedId)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    widget.onOpenDetail(marker.raw);
                  },
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Buka laporan gunung'),
                )
              else
                const Text(
                  'Laporan gunung ini sedang dibuka.',
                  style: TextStyle(color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _sameVolcano(String first, String? second) {
  if (second == null) return false;
  String normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'^(gunung|gn)\.?\s*'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalize(first) == normalize(second);
}

String _sourceYears(List<VolcanoSimulationPolygon> polygons) {
  final years =
      polygons
          .map((entry) => entry.sourceYear)
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
  return years.join(', ');
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.level});
  final String label;
  final String level;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, color: _levelColors[level], size: 10),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    ],
  );
}

class _SimulationLegendItem extends StatelessWidget {
  const _SimulationLegendItem({required this.label, required this.zone});
  final String label;
  final String zone;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.crop_square, color: _simulationZoneColors[zone], size: 14),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    ],
  );
}

String _display(dynamic value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

String _formatTime(String? value) {
  final date = DateTime.tryParse(value ?? '')?.toLocal();
  if (date == null) return 'belum tersedia';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

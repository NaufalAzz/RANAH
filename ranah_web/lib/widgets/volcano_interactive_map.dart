import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/gunung_data.dart';
import '../models/verified_krb_data.dart';

const _activityColors = <int, Color>{
  1: Color(0xFF36C78B),
  2: Color(0xFFF2C94C),
  3: Color(0xFFF2994A),
  4: Color(0xFFEB5757),
};
const _unknownColor = Color(0xFF9AA7B5);
const _krbColors = <String, Color>{
  'I': Color(0xFF39A9DB),
  'II': Color(0xFF9566D9),
  'III': Color(0xFFE85D9E),
};

const _krbAssetPath = 'assets/geojson/ranah_krb_big_terverifikasi.geojson';
const _openStreetMapTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

Future<VerifiedKrbDataset>? _cachedKrbDataset;

Future<VerifiedKrbDataset> _loadKrbDataset() => _cachedKrbDataset ??= rootBundle
    .loadString(_krbAssetPath)
    .then(parseVerifiedKrbGeoJson);

class VolcanoInteractiveMap extends StatefulWidget {
  const VolcanoInteractiveMap({
    required this.gunung,
    required this.showKrb,
    this.tilesEnabled = true,
    this.mapController,
    this.krbDataset,
    super.key,
  });

  final GunungRecord gunung;
  final bool showKrb;
  final bool tilesEnabled;
  final MapController? mapController;
  final Future<VerifiedKrbDataset>? krbDataset;

  @override
  State<VolcanoInteractiveMap> createState() => _VolcanoInteractiveMapState();
}

class _VolcanoInteractiveMapState extends State<VolcanoInteractiveMap> {
  late Future<VerifiedKrbDataset> _datasetFuture;
  bool _tileLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _datasetFuture = widget.krbDataset ?? _loadKrbDataset();
  }

  @override
  void didUpdateWidget(covariant VolcanoInteractiveMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.krbDataset != widget.krbDataset) {
      _datasetFuture = widget.krbDataset ?? _loadKrbDataset();
    }
    if (oldWidget.gunung.id != widget.gunung.id) _tileLoadFailed = false;
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xFF102B43),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: const Color(0xFF4B91B4)),
    ),
    clipBehavior: Clip.antiAlias,
    child: FutureBuilder<VerifiedKrbDataset>(
      future: _datasetFuture,
      builder: (context, snapshot) {
        final dataset = snapshot.data;
        final features = dataset?.forGunung(widget.gunung) ?? const [];
        final marker = _markerFor(widget.gunung);
        final center =
            marker?.position ?? _centerOf(features) ?? const LatLng(-2.5, 118);
        final polygons = widget.showKrb
            ? features.expand((feature) => feature.polygons).toList()
            : const <Polygon>[];

        return Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: marker != null || features.isNotEmpty
                          ? 8
                          : 4,
                      minZoom: 3,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                        scrollWheelVelocity: 0.005,
                      ),
                    ),
                    mapController: widget.mapController,
                    children: [
                      if (widget.tilesEnabled)
                        TileLayer(
                          urlTemplate: _openStreetMapTiles,
                          userAgentPackageName: 'com.ranah.web',
                          maxNativeZoom: 19,
                          errorTileCallback: (_, _, _) {
                            // Ignore tile details; the map area reports that
                            // the network background is unavailable.
                            if (mounted && !_tileLoadFailed) {
                              setState(() => _tileLoadFailed = true);
                            }
                          },
                        ),
                      if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
                      if (marker != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: marker.position,
                              width: 42,
                              height: 50,
                              child: Tooltip(
                                message: widget.gunung.nama,
                                child: IconButton(
                                  key: ValueKey(
                                    'web-volcano-marker-${widget.gunung.id}',
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _showMarker(marker),
                                  icon: Icon(
                                    Icons.location_on,
                                    size: 40,
                                    color: marker.color,
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
                        const RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors',
                            ),
                          ],
                        ),
                    ],
                  ),
                  if (marker == null)
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: _MapNotice(
                          text:
                              widget.gunung.statusValidasiKoordinat
                                          ?.toLowerCase() ==
                                      'terverifikasi' &&
                                  widget.gunung.latitude != null &&
                                  widget.gunung.longitude != null
                              ? 'Koordinat gunung tidak valid; marker tidak ditampilkan.'
                              : 'Lokasi gunung belum dapat diverifikasi; marker tidak ditampilkan.',
                        ),
                      ),
                    ),
                  if (snapshot.hasError)
                    const Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: IgnorePointer(
                        child: _MapNotice(
                          text: 'Data poligon KRB gagal dibaca; peta tetap menampilkan lokasi bila tersedia.',
                          warning: true,
                        ),
                      ),
                    ),
                  if (widget.tilesEnabled && _tileLoadFailed)
                    const Positioned(
                      left: 10,
                      right: 10,
                      top: 10,
                      child: IgnorePointer(
                        child: _MapNotice(
                          text: 'Peta dasar gagal dimuat. Periksa koneksi; marker dan poligon tetap tersedia.',
                          warning: true,
                        ),
                      ),
                    ),
                  if (!widget.tilesEnabled)
                    const Positioned(
                      left: 10,
                      right: 10,
                      top: 10,
                      child: IgnorePointer(
                        child: _MapNotice(
                          text: 'Latar peta membutuhkan koneksi internet.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _KrbMapLegend(
              gunung: widget.gunung,
              dataset: dataset,
              features: features,
              loading: snapshot.connectionState == ConnectionState.waiting,
              hasError: snapshot.hasError,
            ),
          ],
        );
      },
    ),
  );

  void _showMarker(_VolcanoMarker marker) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF142B40),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.gunung.nama,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                _region(widget.gunung),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                widget.gunung.statusAktivitas ?? 'Status belum diketahui',
                style: TextStyle(color: marker.color),
              ),
              Text(
                'Diperbarui server: ${_formatDate(widget.gunung.waktuPengambilan)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Koordinat terverifikasi: ${marker.position.latitude}, ${marker.position.longitude}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Sumber koordinat: ${widget.gunung.sumberKoordinat ?? 'tidak tersedia'}'
                '${widget.gunung.sumberKoordinatId == null ? '' : ' · ID ${widget.gunung.sumberKoordinatId}'}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VolcanoMarker {
  const _VolcanoMarker(this.position, this.color);

  final LatLng position;
  final Color color;
}

_VolcanoMarker? _markerFor(GunungRecord gunung) {
  if (gunung.statusValidasiKoordinat?.toLowerCase() != 'terverifikasi') {
    return null;
  }
  final latitude = gunung.latitude;
  final longitude = gunung.longitude;
  if (latitude == null ||
      longitude == null ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      latitude < -90 ||
      latitude > 90 ||
      longitude < -180 ||
      longitude > 180) {
    return null;
  }
  return _VolcanoMarker(
    LatLng(latitude, longitude),
    _activityColors[gunung.activityLevel] ?? _unknownColor,
  );
}

LatLng? _centerOf(List<VerifiedKrbFeature> features) {
  final points = features
      .expand((feature) => feature.polygons)
      .expand((polygon) => polygon.points);
  var minLat = double.infinity;
  var maxLat = -double.infinity;
  var minLon = double.infinity;
  var maxLon = -double.infinity;
  var found = false;
  for (final point in points) {
    found = true;
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLon) minLon = point.longitude;
    if (point.longitude > maxLon) maxLon = point.longitude;
  }
  if (!found) return null;
  return LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
}

class _KrbMapLegend extends StatelessWidget {
  const _KrbMapLegend({
    required this.gunung,
    required this.dataset,
    required this.features,
    required this.loading,
    required this.hasError,
  });

  final GunungRecord gunung;
  final VerifiedKrbDataset? dataset;
  final List<VerifiedKrbFeature> features;
  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final zones = features.map((feature) => feature.zone).toSet();
    final years =
        features
            .map((feature) => feature.sourceYear)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      color: const Color(0xFF102B43),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legenda Kawasan Rawan Bencana (KRB)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final zone in const ['I', 'II', 'III'])
                _LegendItem(
                  color: _krbColors[zone]!,
                  label:
                      'KRB $zone${zones.contains(zone) ? '' : ' (tidak ada)'}',
                ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(minHeight: 2),
            )
          else if (hasError)
            const _LegendNote(
              'Data poligon KRB terverifikasi belum tersedia untuk gunung ini. GeoJSON tidak dapat dibaca.',
              warning: true,
            )
          else if (features.isEmpty)
            const _LegendNote(
              'Data poligon KRB terverifikasi belum tersedia untuk gunung ini.',
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'Data KRB: ${gunung.nama} · '
                'Tahun ${years.isEmpty ? 'tidak tersedia' : years.join(', ')}.',
                style: const TextStyle(color: Color(0xFFD5E2ED), fontSize: 10),
              ),
            ),
            if (dataset != null)
              Text(
                'Sumber data: ${dataset!.sourceName}.',
                style: const TextStyle(color: Color(0xFFD5E2ED), fontSize: 10),
              ),
          ],
          const _LegendNote(
            'Geometri BIG dapat berasal dari tahun lama dan hanya untuk informasi. Bukan panduan evakuasi; ikuti arahan BPBD/PVMBG terkini.',
          ),
          const _LegendNote('Peta dasar: © OpenStreetMap contributors.'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.crop_square, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
    ],
  );
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: warning ? const Color(0xE7663D0B) : const Color(0xE6102639),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: warning ? const Color(0xFFFFE6AC) : Colors.white,
        fontSize: 11,
      ),
    ),
  );
}

class _LegendNote extends StatelessWidget {
  const _LegendNote(this.text, {this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      text,
      style: TextStyle(
        color: warning ? const Color(0xFFFFD166) : const Color(0xFFB8C7D4),
        fontSize: 10,
      ),
    ),
  );
}

String _region(GunungRecord gunung) {
  final values = [gunung.kabupaten, gunung.provinsi]
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  return values.isEmpty ? 'Wilayah belum tersedia' : values.join(', ');
}

String _formatDate(DateTime? value) {
  if (value == null) return 'belum tersedia';
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year} '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}

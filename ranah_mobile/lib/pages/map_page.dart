import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/mobile_map_data.dart';
import '../services/mobile_location_provider.dart';
import '../services/mobile_map_repository.dart';
import '../services/gunung_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

enum _LocationConsent { locationOnly, cancel }

class MapPage extends StatefulWidget {
  const MapPage({
    this.onOpenActivity,
    this.onOpenReport,
    this.repository,
    this.locationProvider,
    this.gunungRepository,
    this.tilesEnabled = true,
    super.key,
  });

  final VoidCallback? onOpenActivity;
  final ValueChanged<Map<String, dynamic>>? onOpenReport;
  final MobileMapRepository? repository;
  final MobileLocationProvider? locationProvider;
  final GunungRepository? gunungRepository;
  final bool tilesEnabled;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const _autoRouteRadiusKm = 10.0;
  final MapController _mapController = MapController();
  late final MobileMapRepository _repository;
  late final MobileLocationProvider _locationProvider;
  late final GunungRepository _gunungRepository;
  bool _locationLoading = false;
  bool _locationRequested = false;
  bool _locationConsentGiven = false;
  bool _routeConsentGiven = false;
  bool _addressLoading = false;
  bool _hazardLoading = false;

  bool _gunungLoading = false;

  DeviceLocationFix? _location;
  MapAddress? _address;
  MapHazardResult? _hazards;
  MapOsmDataset? _osm;
  WalkingRoute? _route;
  MapOsmFeature? _selectedDestination;
  List<Map<String, dynamic>> _nearbyVolcanoes = const [];
  String? _locationError;
  String? _addressError;
  String? _hazardError;
  String? _gunungError;
  int _locationGeneration = 0;
  int _routeGeneration = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LaravelMobileMapRepository();
    _locationProvider =
        widget.locationProvider ?? const GeolocatorLocationProvider();
    _gunungRepository = widget.gunungRepository ?? GunungRepository();
  }

  @override
  void dispose() {
    if (widget.repository == null) _repository.close();
    super.dispose();
  }

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
                if (_locationRequested)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: _MapBackButton(onPressed: _backToMapStart),
                  ),
                SizedBox(height: 14),
                _InteractiveMobileMap(
                  controller: _mapController,
                  location: _location,
                  features: _osm?.features ?? const [],
                  volcanoes: _nearbyVolcanoes,
                  route: _route,
                  selectedDestinationId: _selectedDestination?.id,
                  onSelectDestination: _selectDestination,
                  tilesEnabled: widget.tilesEnabled,
                ),
                if (!_locationRequested) ...[
                  const SizedBox(height: 14),
                  _LocationAction(
                    onTap: _findLocation,
                    loading: _locationLoading,
                  ),
                ],
                const SizedBox(height: 10),
                _ActivityReportHeading(onTap: widget.onOpenActivity),
                if (_locationRequested) ...[
                  const SizedBox(height: 12),
                  const _MapLevelLegend(),
                  const SizedBox(height: 14),
                  _LocationSummary(
                    location: _location,
                    address: _address,
                    locationLoading: _locationLoading,
                    loading: _addressLoading,
                    error: _addressError,
                    onRetry: _locationError == null
                        ? _retryAddress
                        : _findLocation,
                    locationError: _locationError,
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Jalur dan posko evakuasi erupsi resmi belum tersedia. Ikuti arahan BPBD atau petugas setempat. Peta KRB bukan penentu jalur aman.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  _NearbyVolcanoPanel(
                    items: _nearbyVolcanoes,
                    province: _address?.province,
                    location: _location,
                    loading: _gunungLoading,
                    error: _gunungError,
                    onRetry: _retryVolcanoes,
                    onOpenReport: widget.onOpenReport,
                    onOpenActivity: widget.onOpenActivity,
                  ),
                  const SizedBox(height: 12),
                  _HazardPanel(
                    result: _hazards,
                    loading: _hazardLoading,
                    error: _hazardError,
                    onRetry: _retryHazards,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findLocation() async {
    if (_locationLoading) return;
    var routeAfterLocation = false;
    if (!_locationConsentGiven) {
      final choice = await showDialog<_LocationConsent>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pilih penggunaan lokasi'),
          content: const Text(
            'Lokasi dipakai untuk meminta alamat, gunung sekitar, dan analisis KRB melalui server RANAH. Tidak ada rute atau tujuan evakuasi otomatis.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _LocationConsent.cancel),
              child: const Text('Batalkan'),
            ),
            OutlinedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _LocationConsent.locationOnly),
              child: const Text('Gunakan lokasi saja'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == _LocationConsent.cancel) {
        return;
      }
      _locationConsentGiven = true;
      routeAfterLocation = false;
      _routeConsentGiven = routeAfterLocation;
    }
    setState(() {
      _locationRequested = true;
      _locationLoading = true;
      _locationError = null;
      _locationGeneration++;
      _routeGeneration++;
      _route = null;

      _location = null;
      _address = null;
      _hazards = null;
      _osm = null;
      _nearbyVolcanoes = const [];
    });
    final generation = _locationGeneration;
    try {
      final fix = await _locationProvider.currentFix();
      if (!mounted) return;
      if (generation != _locationGeneration) return;
      setState(() {
        _location = fix;
        _address = null;
        _hazards = null;
        _osm = null;
        _route = null;
        _selectedDestination = null;
        _nearbyVolcanoes = const [];
        _locationLoading = false;
        _addressLoading = true;
        _hazardLoading = true;

        _gunungLoading = true;

        _addressError = null;
        _hazardError = null;

        _gunungError = null;
      });
      _mapController.move(LatLng(fix.latitude, fix.longitude), 10);
      final coordinates = DeviceCoordinates(
        latitude: fix.latitude,
        longitude: fix.longitude,
      );
      final addressFuture = _loadAddress(coordinates, generation);
      final hazardFuture = _loadHazards(coordinates, generation);
      final osmFuture = Future<MapOsmDataset?>.value(null);
      final volcanoFuture = _loadVolcanoes(generation, addressFuture);
      if (routeAfterLocation) {
        unawaited(
          _routeToNearestPoint(
            coordinates,
            generation,
            addressFuture,
            osmFuture,
          ),
        );
      }
      await Future.wait<void>([
        addressFuture,
        hazardFuture,
        osmFuture,
        volcanoFuture,
      ]);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = error.toString();
      });
    }
  }

  void _backToMapStart() {
    _locationGeneration++;
    _routeGeneration++;
    _mapController.move(const LatLng(-0.9147, 100.4668), 5);
    setState(() {
      _locationRequested = false;
      _locationConsentGiven = false;
      _routeConsentGiven = false;
      _locationLoading = false;
      _addressLoading = false;
      _hazardLoading = false;

      _gunungLoading = false;

      _location = null;
      _address = null;
      _hazards = null;
      _osm = null;
      _route = null;
      _selectedDestination = null;
      _nearbyVolcanoes = const [];
      _locationError = null;
      _addressError = null;
      _hazardError = null;

      _gunungError = null;
    });
  }

  Future<MapAddress?> _loadAddress(
    DeviceCoordinates location,
    int generation,
  ) async {
    try {
      final result = await _repository.lookupAddress(location);
      if (!mounted || generation != _locationGeneration) return null;
      setState(() {
        _address = result;
        _addressLoading = false;
      });
      return result;
    } catch (error) {
      if (mounted && generation == _locationGeneration) {
        setState(() {
          _addressError = error.toString();
          _addressLoading = false;
        });
      }
      return null;
    }
  }

  Future<void> _loadHazards(DeviceCoordinates location, int generation) async {
    try {
      final result = await _repository.analyze(location);
      if (!mounted || generation != _locationGeneration) return;
      setState(() {
        _hazards = result;
        _hazardLoading = false;
      });
    } catch (error) {
      if (mounted && generation == _locationGeneration) {
        setState(() {
          _hazardError = error.toString();
          _hazardLoading = false;
        });
      }
    }
  }

  Future<void> _loadVolcanoes(
    int generation,
    Future<MapAddress?> addressFuture,
  ) async {
    try {
      final address = await addressFuture;
      if (!mounted || generation != _locationGeneration) return;
      if (address?.province == null) {
        setState(() {
          _gunungLoading = false;
          _gunungError = 'Provinsi belum dapat dikenali dari data alamat.';
        });
        return;
      }
      final snapshot = await _gunungRepository.syncGunung();
      if (!mounted || generation != _locationGeneration) return;
      final province = address!.province!;
      final matching =
          snapshot.items
              .whereType<Map<String, dynamic>>()
              .where(
                (record) =>
                    _sameProvince(record['provinsi']?.toString(), province),
              )
              .toList()
            ..sort((a, b) {
              final distanceA = _volcanoDistanceKm(a, _location);
              final distanceB = _volcanoDistanceKm(b, _location);
              if (distanceA == null && distanceB != null) return 1;
              if (distanceA != null && distanceB == null) return -1;
              if (distanceA != null && distanceB != null) {
                return distanceA.compareTo(distanceB);
              }
              return (a['nama']?.toString() ?? '').compareTo(
                b['nama']?.toString() ?? '',
              );
            });
      setState(() {
        _nearbyVolcanoes = matching;
        _gunungLoading = false;
      });
    } catch (error) {
      if (mounted && generation == _locationGeneration) {
        setState(() {
          _gunungError = error.toString();
          _gunungLoading = false;
        });
      }
    }
  }

  Future<void> _routeToNearestPoint(
    DeviceCoordinates location,
    int generation,
    Future<MapAddress?> addressFuture,
    Future<MapOsmDataset?> osmFuture,
  ) async {
    final results = await Future.wait<Object?>([addressFuture, osmFuture]);
    if (!mounted || generation != _locationGeneration || !_routeConsentGiven) {
      return;
    }
    final address = results[0] as MapAddress?;
    final dataset = results[1] as MapOsmDataset?;
    if (!_isPadang(address?.regency)) {
      _showMessage(
        'Wilayah Kota Padang belum terkonfirmasi; simulasi jalur tidak dijalankan.',
      );
      return;
    }
    final origin = location.point;
    final candidates =
        (dataset?.features ?? const <MapOsmFeature>[])
            .where(
              (feature) =>
                  feature.geometryType == 'Point' && feature.point != null,
            )
            .map(
              (feature) => (
                feature: feature,
                distance: const Distance().as(
                  LengthUnit.Kilometer,
                  origin,
                  feature.point!,
                ),
              ),
            )
            .where((item) => item.distance <= _autoRouteRadiusKm)
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));
    if (candidates.isEmpty) {
      _showMessage(
        'Belum tersedia titik kumpul yang dapat dirutekan di sekitar lokasi Anda.',
      );
      return;
    }
    await _calculateRoute(location, candidates.first.feature, generation);
  }

  Future<void> _calculateRoute(
    DeviceCoordinates location,
    MapOsmFeature destination,
    int locationGeneration,
  ) async {
    if (!_routeConsentGiven || destination.geometryType != 'Point') return;
    final routeGeneration = ++_routeGeneration;
    setState(() {
      _selectedDestination = destination;

      _route = null;
    });
    try {
      final route = await _repository.route(location, destination);
      if (!mounted ||
          locationGeneration != _locationGeneration ||
          routeGeneration != _routeGeneration ||
          _location?.latitude != location.latitude ||
          _location?.longitude != location.longitude ||
          route.destinationId != destination.id) {
        return;
      }
      setState(() {
        _route = route;
      });
    } catch (error) {
      if (mounted &&
          locationGeneration == _locationGeneration &&
          routeGeneration == _routeGeneration) {
        setState(() {});
      }
    }
  }

  void _selectDestination(MapOsmFeature feature) {
    setState(() {
      _selectedDestination = feature;
      _route = null;
    });
  }

  Future<void> _retryAddress() async {
    final fix = _location;
    if (fix == null) return;
    setState(() {
      _addressLoading = true;
      _addressError = null;
    });
    final generation = _locationGeneration;
    final address = await _loadAddress(
      DeviceCoordinates(latitude: fix.latitude, longitude: fix.longitude),
      generation,
    );
    if (address != null) {
      unawaited(_loadVolcanoes(generation, Future.value(address)));
    }
  }

  Future<void> _retryHazards() async {
    final fix = _location;
    if (fix == null) return;
    setState(() {
      _hazardLoading = true;
      _hazardError = null;
    });
    await _loadHazards(
      DeviceCoordinates(latitude: fix.latitude, longitude: fix.longitude),
      _locationGeneration,
    );
  }

  Future<void> _retryVolcanoes() async {
    if (_location == null) return;
    setState(() {
      _gunungLoading = true;
      _gunungError = null;
    });
    await _loadVolcanoes(_locationGeneration, Future.value(_address));
  }

  bool _sameProvince(String? first, String second) {
    String normalize(String value) => value
        .toLowerCase()
        .replaceFirst(RegExp(r'^(provinsi|province)\s+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return first != null && normalize(first) == normalize(second);
  }

  bool _isPadang(String? regency) {
    final value = regency
        ?.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return value == 'padang' || value == 'kota padang';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
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

class _MapBackButton extends StatelessWidget {
  const _MapBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded, size: 17),
      label: const Text('Kembali'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        minimumSize: const Size(0, AppSizes.minimumTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        side: BorderSide(color: Colors.white.withValues(alpha: .45)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: AppTypography.label.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _ActivityReportHeading extends StatelessWidget {
  const _ActivityReportHeading({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
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

class _MapTitlePanel extends StatelessWidget {
  const _MapTitlePanel();

  @override
  Widget build(BuildContext context) {
    return const AppPageBanner(
      icon: Icons.landscape_outlined,
      eyebrow: 'PETA DAN KESIAPSIAGAAN',
      title: 'Peta KRB Gunung Api',
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

class _InteractiveMobileMap extends StatelessWidget {
  const _InteractiveMobileMap({
    required this.controller,
    required this.location,
    required this.features,
    required this.volcanoes,
    required this.route,
    required this.selectedDestinationId,
    required this.onSelectDestination,
    required this.tilesEnabled,
  });

  final MapController controller;
  final DeviceLocationFix? location;
  final List<MapOsmFeature> features;
  final List<Map<String, dynamic>> volcanoes;
  final WalkingRoute? route;
  final String? selectedDestinationId;
  final ValueChanged<MapOsmFeature> onSelectDestination;
  final bool tilesEnabled;

  @override
  Widget build(BuildContext context) {
    final center = location == null
        ? const LatLng(-0.9147, 100.4668)
        : LatLng(location!.latitude, location!.longitude);
    final polygons = features
        .where(
          (feature) =>
              feature.geometryType == 'Polygon' && feature.rings.isNotEmpty,
        )
        .toList();
    final points = features
        .where(
          (feature) => feature.geometryType == 'Point' && feature.point != null,
        )
        .toList();
    final volcanoMarkers = volcanoes
        .map((record) {
          final latitude = double.tryParse(
            record['latitude']?.toString() ?? '',
          );
          final longitude = double.tryParse(
            record['longitude']?.toString() ?? '',
          );
          if (record['status_validasi_koordinat']?.toString().toLowerCase() !=
                  'terverifikasi' ||
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
          return (record: record, point: LatLng(latitude, longitude));
        })
        .whereType<({Map<String, dynamic> record, LatLng point})>()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 310,
          child: ClipRect(
            child: FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: location == null ? 5 : 10,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                if (tilesEnabled)
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.ranah_mobile',
                    maxNativeZoom: 19,
                  ),
                if (polygons.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      for (final polygon in polygons)
                        Polygon(
                          points: polygon.rings.first,
                          holePointsList: polygon.rings.length > 1
                              ? polygon.rings.skip(1).toList()
                              : null,
                          color: const Color(0x5537B7C7),
                          borderColor: const Color(0xFF51D1D4),
                          borderStrokeWidth: 2,
                        ),
                    ],
                  ),
                if (route != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: route!.coordinates,
                        color: const Color(0xFFFFD166),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final feature in points)
                      Marker(
                        point: feature.point!,
                        width: 48,
                        height: 56,
                        child: Semantics(
                          button: true,
                          label:
                              '${feature.name ?? 'Titik referensi'}, ${feature.status}',
                          child: GestureDetector(
                            onTap: () => onSelectDestination(feature),
                            child: Icon(
                              Icons.location_on,
                              color: selectedDestinationId == feature.id
                                  ? const Color(0xFFFFD166)
                                  : const Color(0xFF59D1D4),
                              size: 42,
                            ),
                          ),
                        ),
                      ),
                    for (final volcano in volcanoMarkers)
                      Marker(
                        point: volcano.point,
                        width: 42,
                        height: 48,
                        child: Tooltip(
                          message:
                              '${volcano.record['nama'] ?? 'Gunung api'} · ${volcano.record['status_aktivitas'] ?? 'Status belum diketahui'}',
                          child: Icon(
                            Icons.terrain,
                            color: _volcanoColor(
                              volcano.record['status_aktivitas']?.toString(),
                            ),
                            size: 32,
                          ),
                        ),
                      ),
                    if (location != null)
                      Marker(
                        point: LatLng(location!.latitude, location!.longitude),
                        width: 48,
                        height: 56,
                        child: const Icon(
                          Icons.my_location,
                          color: Color(0xFF69E3A5),
                          size: 38,
                        ),
                      ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      '© OpenStreetMap contributors',
                      onTap: () => launchUrl(
                        Uri.parse('https://www.openstreetmap.org/copyright'),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 8, 14, 2),
          child: Text(
            'Peta dasar memerlukan internet. Buka laporan gunung untuk melihat poligon KRB yang tersedia; bukan penetapan jalur evakuasi.',
            style: TextStyle(color: Color(0xFFD1DCE9), fontSize: 11),
          ),
        ),
      ],
    );
  }
}

Color _volcanoColor(String? status) {
  final level = RegExp(
    r'^\s*Level\s+(IV|III|II|I)\b',
    caseSensitive: false,
  ).firstMatch(status ?? '')?.group(1)?.toUpperCase();
  return switch (level) {
    'I' => const Color(0xFF36C78B),
    'II' => const Color(0xFFF2C94C),
    'III' => const Color(0xFFF2994A),
    'IV' => const Color(0xFFEB5757),
    _ => const Color(0xFF9AA7B5),
  };
}

double? _volcanoDistanceKm(
  Map<String, dynamic> record,
  DeviceLocationFix? location,
) {
  if (location == null ||
      record['status_validasi_koordinat']?.toString().toLowerCase() !=
          'terverifikasi') {
    return null;
  }
  final latitude = double.tryParse(record['latitude']?.toString() ?? '');
  final longitude = double.tryParse(record['longitude']?.toString() ?? '');
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
  return const Distance().as(
    LengthUnit.Kilometer,
    location.point,
    LatLng(latitude, longitude),
  );
}

String _formatMapTime(DateTime? date) {
  if (date == null) return 'waktu analisis tidak tersedia';
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

IconData _hazardIcon(String status) => switch (status) {
  'hasil_tersedia' || 'klasifikasi_belum_diverifikasi' => Icons.info_outline,
  'layanan_bermasalah' || 'layanan_gagal' => Icons.cloud_off_outlined,
  'titik_di_luar_cakupan' || 'di_luar_cakupan_layer' => Icons.help_outline,
  _ => Icons.info_outline,
};

String _hazardStatusLabel(String status) => switch (status) {
  'hasil_tersedia' => 'Ada fitur data yang beririsan; bukan peringatan aktif.',
  'klasifikasi_belum_diverifikasi' =>
    'Data tersedia; klasifikasi belum diverifikasi.',
  'no_data' => 'Data untuk lokasi ini tidak ditemukan; bukan bukti aman.',
  'titik_di_luar_cakupan' ||
  'di_luar_cakupan_layer' => 'Di luar cakupan data yang diperiksa.',
  'layanan_bermasalah' || 'layanan_gagal' => 'Layanan data gagal dimuat.',
  'belum_dapat_ditentukan' ||
  'analisis_tidak_dapat_ditentukan' => 'Belum dapat dipastikan.',
  _ => 'Status belum dapat ditafsirkan.',
};

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
  const _LocationAction({required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

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
          onTap: loading ? null : onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                if (loading)
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: Padding(
                      padding: EdgeInsets.all(9),
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                  )
                else
                  const Icon(Icons.location_on, size: 42, color: Colors.white),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loading ? 'Mencari lokasi...' : 'Temukan Lokasi Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Minta lokasi untuk melihat alamat dan informasi terkait di sekitar.',
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
  const _LocationSummary({
    required this.location,
    required this.address,
    required this.locationLoading,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.locationError,
  });
  final DeviceLocationFix? location;
  final MapAddress? address;
  final bool locationLoading;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final String? locationError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _InfoPanel(
        icon: Icons.my_location_rounded,
        title: 'Lokasi saat ini',
        detail: location == null
            ? locationLoading
                  ? 'Mencari lokasi perangkat...'
                  : locationError ?? 'Tekan Temukan Lokasi Saya untuk meminta posisi perangkat.'
            : '${loading ? 'Memuat alamat...' : address?.shortLabel ?? error ?? 'Alamat belum tersedia.'}\nKoordinat ${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)} · akurasi ±${location!.accuracyMeters.round()} m',
        action: locationError != null || (location != null && error != null)
            ? _retryButton(onRetry)
            : null,
      ),
    );
  }
}

class _MapSectionHeading extends StatelessWidget {
  const _MapSectionHeading({
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFF0F5473),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: const Color(0xFF29849A)),
        ),
        child: Icon(icon, color: const Color(0xFF7ED5DE), size: 21),
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
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFFD1DCE9), fontSize: 12),
            ),
          ],
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 4), trailing!],
    ],
  );
}

class _NearbyVolcanoPanel extends StatelessWidget {
  const _NearbyVolcanoPanel({
    required this.items,
    required this.province,
    required this.location,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onOpenReport,
    required this.onOpenActivity,
  });
  final List<Map<String, dynamic>> items;
  final String? province;
  final DeviceLocationFix? location;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<Map<String, dynamic>>? onOpenReport;
  final VoidCallback? onOpenActivity;

  @override
  Widget build(BuildContext context) {
    final normalizedProvince = province?.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MapSectionHeading(
            icon: Icons.landscape_outlined,
            title: 'Gunung Aktif Sekitar',
            subtitle: normalizedProvince == null || normalizedProvince.isEmpty
                ? 'Provinsi belum dikenali'
                : 'Provinsi $normalizedProvince',
            trailing: TextButton(
              onPressed: onOpenActivity,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
              child: const Text('Lihat daftar'),
            ),
          ),
          if (loading || error != null || items.isEmpty) ...[
            const SizedBox(height: 8),
            _InfoPanel(
              icon: loading ? Icons.hourglass_top : Icons.landscape_rounded,
              title: loading
                  ? 'Memuat daftar gunung...'
                  : error != null
                  ? 'Daftar gunung belum dapat dimuat.'
                  : 'Belum ada data gunung untuk wilayah ini.',
              detail: loading ? 'Memuat daftar gunung dari Laravel.' : error ?? 'Daftar akan tampil setelah provinsi lokasi berhasil dikenali.',
            ),
          ],
          if (error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: _retryButton(onRetry),
            ),
          for (final item in items.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _NearbyVolcanoCard(
                item: item,
                location: location,
                onTap: item['id'] != null && onOpenReport != null
                    ? () => onOpenReport!(item)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _NearbyVolcanoCard extends StatelessWidget {
  const _NearbyVolcanoCard({
    required this.item,
    required this.location,
    this.onTap,
  });

  final Map<String, dynamic> item;
  final DeviceLocationFix? location;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = item['status_aktivitas']?.toString().trim();
    final statusLabel = status == null || status.isEmpty
        ? 'Status belum tersedia'
        : status;
    final statusColor = _volcanoColor(status);
    final region = [item['kabupaten'], item['provinsi']]
        .where((value) => value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString().trim())
        .join(', ');
    final distanceKm = _volcanoDistanceKm(item, location);
    final retrievedAt = DateTime.tryParse(
      item['waktu_pengambilan']?.toString() ?? '',
    );
    final radius = BorderRadius.circular(AppRadii.card);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkPanel,
        borderRadius: radius,
        border: Border.all(color: statusColor.withValues(alpha: .72)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: .2),
                  child: Icon(Icons.landscape_outlined, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nama']?.toString() ?? 'Gunung api',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (region.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          region,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD7E0EA),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        distanceKm == null
                            ? 'Jarak tidak ditampilkan: koordinat belum terverifikasi.'
                            : 'Jarak garis lurus: ${distanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status dari API: $statusLabel',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (retrievedAt != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Diambil server: ${_formatMapTime(retrievedAt)}',
                          style: const TextStyle(
                            color: Color(0xFFD7E0EA),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.open_in_new, color: Colors.white70),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HazardPanel extends StatelessWidget {
  const _HazardPanel({
    required this.result,
    required this.loading,
    required this.error,
    required this.onRetry,
  });
  final MapHazardResult? result;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _MapSectionHeading(
            icon: Icons.monitor_heart_outlined,
            title: 'Kawasan Rawan Erupsi',
            subtitle: 'Analisis data geospasial tersedia atas permintaan',
          ),
          const SizedBox(height: 6),
          const Text(
            'Analisis ini mengkaji data bahaya wilayah, bukan peringatan real-time atau pernyataan lokasi aman.',
            style: TextStyle(
              color: Color(0xFFD1DCE9),
              fontSize: 12,
              height: 1.35,
            ),
          ),
          if (loading) ...[
            const SizedBox(height: 8),
            const _InfoPanel(
              icon: Icons.hourglass_top_rounded,
              title: 'Memeriksa KRB gunung api...',
              detail: 'Menunggu hasil untuk koordinat lokasi yang dipilih.',
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _InfoPanel(
                icon: Icons.cloud_off_outlined,
                title: 'Analisis belum dapat dimuat.',
                detail: error!,
                action: _retryButton(onRetry),
              ),
            ),
          if (result != null)
            for (final item in result!.items)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _HazardResultCard(item: item),
              ),
          if (result == null && !loading && error == null) ...[
            const SizedBox(height: 8),
            const _InfoPanel(
              icon: Icons.info_outline_rounded,
              title: 'Analisis belum dijalankan.',
              detail: 'Temukan lokasi untuk meminta analisis data bahaya.',
            ),
          ],
        ],
      ),
    );
  }
}

class _HazardResultCard extends StatelessWidget {
  const _HazardResultCard({required this.item});

  final MapHazardItem item;

  @override
  Widget build(BuildContext context) {
    final color = _hazardColor(item.status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkPanel,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: color.withValues(alpha: .58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_hazardIcon(item.status), color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            _hazardStatusShort(item.status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_hazardStatusLabel(item.status)}\n${item.explanation}',
            style: const TextStyle(
              color: Color(0xFFD1DCE9),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

Color _hazardColor(String status) => switch (status) {
  'hasil_tersedia' => const Color(0xFF7ED5DE),
  'layanan_bermasalah' || 'layanan_gagal' => const Color(0xFFFF8A80),
  'titik_di_luar_cakupan' || 'di_luar_cakupan_layer' => const Color(0xFFD1DCE9),
  'no_data' => const Color(0xFFFFD166),
  _ => const Color(0xFFFFD166),
};

String _hazardStatusShort(String status) => switch (status) {
  'hasil_tersedia' => 'DATA TERSEDIA',
  'klasifikasi_belum_diverifikasi' => 'KLASIFIKASI BELUM DIVERIFIKASI',
  'no_data' => 'BELUM DAPAT DIPASTIKAN',
  'titik_di_luar_cakupan' || 'di_luar_cakupan_layer' => 'DI LUAR CAKUPAN',
  'layanan_bermasalah' ||
  'layanan_gagal' => 'DATA SEMENTARA TIDAK DAPAT DIMUAT',
  _ => 'BELUM DAPAT DIPASTIKAN',
};

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.icon,
    required this.title,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String title;
  final String detail;
  final Widget? action;

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
                ?action,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _retryButton(VoidCallback onRetry) => TextButton.icon(
  onPressed: onRetry,
  icon: const Icon(Icons.refresh_rounded, size: 18),
  label: const Text('Coba lagi'),
  style: TextButton.styleFrom(
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
  ),
);

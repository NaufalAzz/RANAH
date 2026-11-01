import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mobile_map_data.dart';
import '../services/mobile_location_provider.dart';
import '../services/mobile_map_repository.dart';
import '../services/gunung_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

enum _LocationConsent { locationAndRoute, locationOnly, cancel }

class MapPage extends StatefulWidget {
  const MapPage({
    this.onOpenActivity,
    this.repository,
    this.locationProvider,
    this.gunungRepository,
    this.tilesEnabled = true,
    super.key,
  });

  final VoidCallback? onOpenActivity;
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
  bool _locationConsentGiven = false;
  bool _routeConsentGiven = false;
  bool _addressLoading = false;
  bool _hazardLoading = false;
  bool _osmLoading = false;
  bool _gunungLoading = false;
  bool _routeLoading = false;
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
  String? _osmError;
  String? _gunungError;
  String? _routeError;
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
                SizedBox(height: 12),
                _MapLevelLegend(),
                SizedBox(height: 14),
                _LocationAction(
                  onTap: _findLocation,
                  loading: _locationLoading,
                ),
                SizedBox(height: 10),
                _ActivityReportHeading(onTap: widget.onOpenActivity),
                SizedBox(height: 10),
                _LocationSummary(
                  location: _location,
                  address: _address,
                  loading: _addressLoading,
                  error: _addressError,
                  onRetry: _retryAddress,
                  locationError: _locationError,
                ),
                SizedBox(height: 12),
                _RoutePanel(
                  route: _route,
                  destination: _selectedDestination,
                  loading: _routeLoading,
                  error: _routeError,
                  onRetry: _retryRoute,
                  onStart: _requestRouteForSelected,
                ),
                SizedBox(height: 12),
                _NearbyVolcanoPanel(
                  items: _nearbyVolcanoes,
                  loading: _gunungLoading,
                  error: _gunungError,
                  onRetry: _retryVolcanoes,
                ),
                SizedBox(height: 12),
                _HazardPanel(
                  result: _hazards,
                  loading: _hazardLoading,
                  error: _hazardError,
                  onRetry: _retryHazards,
                ),
                SizedBox(height: 12),
                _MapSourceNote(
                  osm: _osm,
                  osmLoading: _osmLoading,
                  osmError: _osmError,
                  onRetry: _retryOsm,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findLocation() async {
    if (_locationLoading) return;
    var routeAfterLocation = _routeConsentGiven;
    if (!_locationConsentGiven) {
      final choice = await showDialog<_LocationConsent>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pilih penggunaan lokasi'),
          content: const Text(
            'Lokasi dipakai untuk meminta alamat, gunung sekitar, analisis bahaya, dan referensi OSM melalui server RANAH. Jika memilih simulasi jalur, koordinat juga diteruskan server ke penyedia Valhalla untuk menghitung rute. Tujuan dan keamanan akses belum diverifikasi.',
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
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _LocationConsent.locationAndRoute,
              ),
              child: const Text('Lokasi + simulasi jalur'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == _LocationConsent.cancel) {
        return;
      }
      _locationConsentGiven = true;
      routeAfterLocation = choice == _LocationConsent.locationAndRoute;
      _routeConsentGiven = routeAfterLocation;
    }
    setState(() {
      _locationLoading = true;
      _locationError = null;
      _locationGeneration++;
      _routeGeneration++;
      _route = null;
      _routeError = null;
      _routeLoading = false;
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
        _osmLoading = true;
        _gunungLoading = true;
        _routeLoading = false;
        _addressError = null;
        _hazardError = null;
        _osmError = null;
        _gunungError = null;
        _routeError = null;
      });
      _mapController.move(LatLng(fix.latitude, fix.longitude), 10);
      final coordinates = DeviceCoordinates(
        latitude: fix.latitude,
        longitude: fix.longitude,
      );
      final addressFuture = _loadAddress(coordinates, generation);
      final hazardFuture = _loadHazards(coordinates, generation);
      final osmFuture = _loadOsm(generation);
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

  Future<MapOsmDataset?> _loadOsm(int generation) async {
    try {
      final result = await _repository.loadOsm();
      if (!mounted || generation != _locationGeneration) return null;
      setState(() {
        _osm = result;
        _osmLoading = false;
      });
      return result;
    } catch (error) {
      if (mounted && generation == _locationGeneration) {
        setState(() {
          _osmError = error.toString();
          _osmLoading = false;
        });
      }
      return null;
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
      final matching = snapshot.items
          .whereType<Map<String, dynamic>>()
          .where(
            (record) => _sameProvince(record['provinsi']?.toString(), province),
          )
          .toList(growable: false);
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
      _routeLoading = true;
      _routeError = null;
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
        _routeLoading = false;
      });
    } catch (error) {
      if (mounted &&
          locationGeneration == _locationGeneration &&
          routeGeneration == _routeGeneration) {
        setState(() {
          _routeError = error.toString();
          _routeLoading = false;
        });
      }
    }
  }

  void _selectDestination(MapOsmFeature feature) {
    setState(() {
      _selectedDestination = feature;
      _route = null;
      _routeError = null;
    });
  }

  Future<void> _requestRouteForSelected() async {
    final location = _location;
    final destination = _selectedDestination;
    if (location == null ||
        destination == null ||
        destination.geometryType != 'Point') {
      return;
    }
    if (!_routeConsentGiven) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kirim koordinat untuk simulasi jalur?'),
          content: const Text(
            'Koordinat lokasi dan tujuan akan diproses oleh server RANAH dan diteruskan ke penyedia routing Valhalla. Rute bukan penilaian keselamatan akses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Setujui dan hitung'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      _routeConsentGiven = true;
    }
    await _calculateRoute(
      DeviceCoordinates(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      destination,
      _locationGeneration,
    );
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

  Future<void> _retryOsm() async {
    if (_location == null) return;
    setState(() {
      _osmLoading = true;
      _osmError = null;
    });
    final dataset = await _loadOsm(_locationGeneration);
    if (dataset != null && _routeConsentGiven && _address != null) {
      await _routeToNearestPoint(
        DeviceCoordinates(
          latitude: _location!.latitude,
          longitude: _location!.longitude,
        ),
        _locationGeneration,
        Future.value(_address),
        Future.value(dataset),
      );
    }
  }

  Future<void> _retryVolcanoes() async {
    if (_location == null) return;
    setState(() {
      _gunungLoading = true;
      _gunungError = null;
    });
    await _loadVolcanoes(_locationGeneration, Future.value(_address));
  }

  Future<void> _retryRoute() async {
    final location = _location;
    final destination = _selectedDestination;
    if (location == null || destination == null) return;
    if (!_routeConsentGiven) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kirim koordinat untuk simulasi jalur?'),
          content: const Text(
            'Koordinat lokasi dan titik tujuan dikirim melalui server RANAH ke penyedia Valhalla untuk menghitung rute pejalan kaki. Tujuan dan keamanan akses belum diverifikasi.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Setujui dan hitung'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      _routeConsentGiven = true;
    }
    await _calculateRoute(
      DeviceCoordinates(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      destination,
      _locationGeneration,
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: AppCardSurface(
        variant: AppCardVariant.information,
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 270,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
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
                                  volcano.record['status_aktivitas']
                                      ?.toString(),
                                ),
                                size: 32,
                              ),
                            ),
                          ),
                        if (location != null)
                          Marker(
                            point: LatLng(
                              location!.latitude,
                              location!.longitude,
                            ),
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
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(8, 8, 8, 2),
              child: Text(
                'Peta dasar memerlukan internet · Referensi OSM belum diverifikasi sebagai fasilitas evakuasi.',
                style: TextStyle(color: Color(0xFFD1DCE9), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
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
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.locationError,
  });
  final DeviceLocationFix? location;
  final MapAddress? address;
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
            ? locationError ??
                  'Tekan Temukan Lokasi Saya untuk meminta posisi perangkat.'
            : '${loading ? 'Memuat alamat...' : address?.shortLabel ?? error ?? 'Alamat belum tersedia.'}\nKoordinat ${location!.latitude.toStringAsFixed(5)}, ${location!.longitude.toStringAsFixed(5)} · akurasi ±${location!.accuracyMeters.round()} m',
        action: location != null && error != null
            ? TextButton(onPressed: onRetry, child: const Text('Coba lagi'))
            : null,
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
  const _RoutePanel({
    required this.route,
    required this.destination,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onStart,
  });
  final WalkingRoute? route;
  final MapOsmFeature? destination;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: _InfoPanel(
        icon: Icons.alt_route_rounded,
        title: 'Simulasi Jalur Menuju Titik Kumpul',
        detail: route != null
            ? '${route!.destinationName ?? destination?.name ?? 'Titik referensi OSM'} · ${(route!.distanceMeters / 1000).toStringAsFixed(2)} km${route!.durationSeconds == null ? '' : ' · sekitar ${(route!.durationSeconds! / 60).ceil()} menit'}\n${route!.warning}'
            : loading
            ? 'Menghitung rute pejalan kaki melalui Laravel...'
            : error ??
                  (destination == null
                      ? 'Pilih marker Point referensi OSM pada peta. Polygon tidak memiliki titik akses dan tidak dapat dirutekan.'
                      : '${destination!.name ?? 'Titik referensi OSM'} · ${destination!.status}'),
        action: loading
            ? const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              )
            : error != null
            ? TextButton(onPressed: onRetry, child: const Text('Coba lagi'))
            : destination?.geometryType == 'Point' && route == null
            ? TextButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.directions_walk),
                label: const Text('Tampilkan simulasi rute'),
              )
            : null,
      ),
    );
  }
}

class _NearbyVolcanoPanel extends StatelessWidget {
  const _NearbyVolcanoPanel({
    required this.items,
    required this.loading,
    required this.error,
    required this.onRetry,
  });
  final List<Map<String, dynamic>> items;
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
          _InfoPanel(
            icon: Icons.landscape_rounded,
            title: 'Gunung di Provinsi Anda',
            detail: loading
                ? 'Memuat daftar gunung dari Laravel...'
                : error ??
                      (items.isEmpty
                          ? 'Belum ada data gunung untuk wilayah yang dikenali.'
                          : '${items.length} gunung ditemukan sesuai provinsi alamat.'),
          ),
          if (error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
            ),
          for (final item in items.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _InfoPanel(
                icon: Icons.terrain,
                title: item['nama']?.toString() ?? 'Gunung api',
                detail:
                    '${item['status_aktivitas'] ?? 'Status belum tersedia'} · ${item['kabupaten'] ?? item['provinsi'] ?? 'Wilayah belum tersedia'}',
              ),
            ),
        ],
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
          _InfoPanel(
            icon: Icons.warning_amber_rounded,
            title: 'Potensi Bencana di Lokasi',
            detail: loading
                ? 'Mengirim koordinat ke analisis Laravel...'
                : error ??
                      (result == null
                          ? 'Analisis belum dijalankan.'
                          : 'Hasil analisis server · ${_formatMapTime(result!.analyzedAt)}'),
          ),
          if (error != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onRetry,
                child: const Text('Coba lagi'),
              ),
            ),
          if (result != null)
            for (final item in result!.items)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _InfoPanel(
                  icon: _hazardIcon(item.status),
                  title: item.name,
                  detail:
                      '${_hazardStatusLabel(item.status)}\n${item.explanation}',
                ),
              ),
        ],
      ),
    );
  }
}

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

class _MapSourceNote extends StatelessWidget {
  const _MapSourceNote({
    required this.osm,
    required this.osmLoading,
    required this.osmError,
    required this.onRetry,
  });
  final MapOsmDataset? osm;
  final bool osmLoading;
  final String? osmError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Text(
            osmLoading
                ? 'Memuat data referensi OSM...'
                : osmError ??
                      '${osm?.features.length ?? 0} fitur referensi OSM · sumber: OpenStreetMap contributors (ODbL). Tidak seluruh Kota Padang tercakup.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: const Color(0xFFB9D2E1)),
          ),
          if (osmError != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Coba muat ulang referensi'),
            ),
          const SizedBox(height: 5),
          Text(
            'Simulasi rute bukan arahan evakuasi operasional. Ikuti informasi BPBD dan PVMBG.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: const Color(0xFFB9D2E1)),
          ),
        ],
      ),
    );
  }
}

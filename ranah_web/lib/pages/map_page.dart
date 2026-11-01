import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/gunung_data.dart';
import '../services/administrative_area_lookup.dart';
import '../services/browser_geolocation.dart';
import '../services/hazard_analysis_repository.dart';
import '../services/osm_assembly_point_repository.dart';
import '../services/route_simulation_repository.dart';
import '../services/ranah_api_client.dart';
import '../theme/ranah_theme.dart';
import '../widgets/ranah_full_width_title_background.dart';

typedef BrowserLocationReader = Future<BrowserLocation> Function();
typedef MapOsmReferenceLoader = Future<OsmAssemblyPointDataset> Function();

enum _LocationUseChoice { locationAndRoute, locationOnly, cancel }

const _maximumAutomaticRouteDistanceKm = 10.0;

class MapPage extends StatefulWidget {
  const MapPage({
    required this.onActivityTap,
    required this.currentLocation,
    required this.currentArea,
    required this.onLocationChanged,
    required this.onAreaChanged,
    required this.gunung,
    required this.gunungLoading,
    required this.gunungError,
    required this.onRetryGunung,
    required this.onOpenReport,
    this.onOpenEvacuation,
    this.locationReader = readBrowserLocation,
    this.areaLookup = lookupBrowserAdministrativeArea,
    this.hazardAnalysisRepository,
    this.osmRepository,
    this.osmLoader,
    this.routeSimulationRepository,
    this.tilesEnabled = true,
    super.key,
  });

  final VoidCallback onActivityTap;
  final BrowserLocation? currentLocation;
  final BrowserAdministrativeArea? currentArea;
  final ValueChanged<BrowserLocation?> onLocationChanged;
  final ValueChanged<BrowserAdministrativeArea?> onAreaChanged;
  final List<GunungRecord> gunung;
  final bool gunungLoading;
  final String? gunungError;
  final VoidCallback onRetryGunung;
  final ValueChanged<GunungRecord> onOpenReport;
  final VoidCallback? onOpenEvacuation;
  final BrowserLocationReader locationReader;
  final AdministrativeAreaLookup areaLookup;
  final HazardAnalysisRepository? hazardAnalysisRepository;
  final OsmAssemblyPointRepository? osmRepository;
  final MapOsmReferenceLoader? osmLoader;
  final RouteSimulationRepository? routeSimulationRepository;
  final bool tilesEnabled;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  bool _locationLoading = false;
  bool _locationConsentGranted = false;
  bool _routingConsentGranted = false;
  bool _areaLoading = false;
  String? _areaError;
  bool _analysisLoading = false;
  String? _analysisError;
  HazardAnalysisResult? _analysisResult;
  late final HazardAnalysisRepository _hazardRepository;
  late final bool _ownsHazardRepository;
  OsmAssemblyPointRepository? _ownedOsmRepository;
  bool _ownsOsmRepository = false;
  bool _osmLoading = false;
  String? _osmError;
  OsmAssemblyPointDataset? _osmDataset;
  Future<OsmAssemblyPointDataset?>? _osmLoadFuture;
  OsmAssemblyPoint? _selectedOsmFeature;
  late final RouteSimulationRepository _routeRepository;
  late final bool _ownsRouteRepository;
  RouteSimulationResult? _routeResult;
  String? _routeError;
  bool _routeLoading = false;
  int _routeRequestGeneration = 0;
  int _requestGeneration = 0;
  BrowserLocation? _pendingLocationUpdate;
  String? _areaResolvedKey;
  String? _hazardResolvedKey;

  @override
  void initState() {
    super.initState();
    _ownsHazardRepository = widget.hazardAnalysisRepository == null;
    _hazardRepository =
        widget.hazardAnalysisRepository ?? HazardAnalysisRepository();
    _ownsRouteRepository = widget.routeSimulationRepository == null;
    _routeRepository =
        widget.routeSimulationRepository ?? RouteSimulationRepository();
    _ownsOsmRepository =
        widget.osmRepository == null && widget.osmLoader == null;
    if (_ownsOsmRepository) {
      _ownedOsmRepository = OsmAssemblyPointRepository();
    }
    if (widget.currentLocation != null) {
      unawaited(_loadOsmReferences());
    }
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldLocation = oldWidget.currentLocation;
    final newLocation = widget.currentLocation;
    var locationWasSetByCurrentAction = false;
    if (oldLocation?.latitude != newLocation?.latitude ||
        oldLocation?.longitude != newLocation?.longitude) {
      final expected = _pendingLocationUpdate;
      if (expected != null && _sameCoordinates(expected, newLocation)) {
        locationWasSetByCurrentAction = true;
        _pendingLocationUpdate = null;
      } else {
        _routeRequestGeneration++;
        _routeResult = null;
        _routeError = null;
        _routeLoading = false;
        _pendingLocationUpdate = null;
        _requestGeneration++;
        _areaLoading = false;
        _areaError = null;
        _analysisResult = null;
        _analysisError = null;
        _analysisLoading = false;
        _areaResolvedKey = null;
        _hazardResolvedKey = null;
      }
    }
    if (oldLocation == null &&
        newLocation != null &&
        !locationWasSetByCurrentAction) {
      unawaited(_loadOsmReferences());
    }
  }

  @override
  void dispose() {
    if (_ownsHazardRepository) _hazardRepository.close();
    if (_ownsOsmRepository) _ownedOsmRepository?.close();
    if (_ownsRouteRepository) _routeRepository.close();
    super.dispose();
  }

  void _selectOsmFeature(OsmAssemblyPoint feature) {
    _routeRequestGeneration++;
    setState(() {
      _selectedOsmFeature = feature;
      _routeResult = null;
      _routeError = null;
      _routeLoading = false;
    });
  }

  Future<void> _showOsmFeatureDetail(OsmAssemblyPoint feature) async {
    _selectOsmFeature(feature);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF142B40),
      builder: (sheetContext) => _OsmFeatureQuickDetail(
        feature: feature,
        onShowRoute: feature.geometryType == 'Point'
            ? () {
                Navigator.of(sheetContext).pop();
                _calculateRoute(feature);
              }
            : null,
      ),
    );
  }

  Future<void> _calculateRoute(
    OsmAssemblyPoint feature, {
    bool consentAlreadyGranted = false,
  }) async {
    final origin = widget.currentLocation ?? _pendingLocationUpdate;
    if (origin == null || feature.geometryType != 'Point') return;
    if (!consentAlreadyGranted && !_routingConsentGranted) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Kirim koordinat untuk simulasi rute?'),
          content: const Text(
            'Koordinat lokasi perangkat dan tujuan akan diproses server RANAH '
            'dan diteruskan ke Valhalla demo untuk menghitung jalur. Data ini '
            'tidak menunjukkan jalan aman atau tujuan evakuasi resmi.',
          ),
          actions: [
            TextButton(
              key: const ValueKey('cancel-route-coordinate-sharing'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              key: const ValueKey('confirm-route-coordinate-sharing'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Kirim dan hitung rute'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      _routingConsentGranted = true;
    }
    if (!mounted ||
        !(_sameCoordinates(origin, widget.currentLocation) ||
            _sameCoordinates(origin, _pendingLocationUpdate)) ||
        _selectedOsmFeature?.id != feature.id) {
      return;
    }

    final generation = ++_routeRequestGeneration;
    setState(() {
      _selectedOsmFeature = feature;
      _routeLoading = true;
      _routeError = null;
      _routeResult = null;
    });
    try {
      final result = await _routeRepository.calculate(
        latitude: origin.latitude,
        longitude: origin.longitude,
        destinationId: feature.id,
      );
      if (!_isCurrentRouteRequest(generation, origin, feature.id)) return;
      if (result.destinationId != feature.id) {
        throw const FormatException(
          'Respons routing mengembalikan tujuan berbeda.',
        );
      }
      setState(() {
        _routeResult = result;
        _routeLoading = false;
      });
    } catch (error) {
      if (!_isCurrentRouteRequest(generation, origin, feature.id)) return;
      setState(() {
        _routeError = _routeErrorText(error);
        _routeLoading = false;
        _routeResult = null;
      });
    }
  }

  bool _isCurrentRouteRequest(
    int generation,
    BrowserLocation origin,
    String destinationId,
  ) =>
      mounted &&
      generation == _routeRequestGeneration &&
      (_sameCoordinates(origin, widget.currentLocation) ||
          _sameCoordinates(origin, _pendingLocationUpdate)) &&
      _selectedOsmFeature?.id == destinationId;

  String _routeErrorText(Object error) {
    if (error is RanahApiException) return error.message;
    if (error is FormatException) {
      return 'Respons routing tidak dapat divalidasi.';
    }
    return 'Rute sementara tidak dapat dimuat. Tidak ada garis rute yang ditampilkan.';
  }

  void _closeRoute() {
    _routeRequestGeneration++;
    setState(() {
      _routeResult = null;
      _routeError = null;
      _routeLoading = false;
      _selectedOsmFeature = null;
    });
  }

  String _coordinateKey(BrowserLocation location) =>
      '${location.latitude.toStringAsFixed(5)},${location.longitude.toStringAsFixed(5)}';

  bool _isCurrentRequest(BrowserLocation location, int generation) =>
      mounted &&
      generation == _requestGeneration &&
      (_sameCoordinates(location, widget.currentLocation) ||
          _sameCoordinates(location, _pendingLocationUpdate));

  Future<OsmAssemblyPointDataset?> _loadOsmReferences() {
    if ((widget.currentLocation ?? _pendingLocationUpdate) == null ||
        _osmDataset != null) {
      return Future.value(_osmDataset);
    }
    final pending = _osmLoadFuture;
    if (pending != null) return pending;
    final future = _fetchOsmReferences();
    _osmLoadFuture = future;
    return future;
  }

  Future<OsmAssemblyPointDataset?> _fetchOsmReferences() async {
    setState(() {
      _osmLoading = true;
      _osmError = null;
    });
    try {
      final dataset =
          await (widget.osmLoader?.call() ??
                  (widget.osmRepository ?? _ownedOsmRepository!).load())
              .timeout(const Duration(seconds: 18));
      if (!mounted) return null;
      setState(() {
        _osmDataset = dataset;
        _osmLoading = false;
      });
      return dataset;
    } catch (_) {
      if (!mounted) return null;
      setState(() {
        _osmError = 'Referensi OSM tidak dapat dimuat dari API RANAH.';
        _osmLoading = false;
        _osmLoadFuture = null;
      });
      return null;
    }
  }

  Future<void> _analyzeHazards(
    BrowserLocation location,
    int generation, {
    bool force = false,
  }) async {
    final key = _coordinateKey(location);
    if (_analysisLoading || (!force && _hazardResolvedKey == key)) return;
    setState(() {
      _analysisLoading = true;
      _analysisError = null;
      _analysisResult = null;
    });
    try {
      final result = await _hazardRepository
          .analyze(latitude: location.latitude, longitude: location.longitude)
          .timeout(const Duration(seconds: 40));
      if (!_isCurrentRequest(location, generation)) return;
      setState(() {
        _analysisLoading = false;
        _analysisResult = result;
        _hazardResolvedKey = key;
      });
    } catch (error) {
      if (!_isCurrentRequest(location, generation)) return;
      setState(() {
        _analysisLoading = false;
        _analysisError = error.toString();
      });
    }
  }

  bool _sameCoordinates(BrowserLocation location, BrowserLocation? current) =>
      current != null &&
      current.latitude == location.latitude &&
      current.longitude == location.longitude;

  Future<BrowserAdministrativeArea?> _identifyArea(
    BrowserLocation location,
    int generation, {
    bool force = false,
  }) async {
    final key = _coordinateKey(location);
    if (_areaLoading || (!force && _areaResolvedKey == key)) {
      return widget.currentArea;
    }
    setState(() {
      _areaLoading = true;
      _areaError = null;
    });
    try {
      final area = await widget
          .areaLookup(location)
          .timeout(const Duration(seconds: 18));
      if (!_isCurrentRequest(location, generation)) return null;
      widget.onAreaChanged(area);
      setState(() {
        _areaLoading = false;
        _areaError = area == null ? 'Data alamat belum tersedia.' : null;
        _areaResolvedKey = key;
      });
      return area;
    } catch (_) {
      if (!_isCurrentRequest(location, generation)) return null;
      setState(() {
        _areaLoading = false;
        _areaError =
            'Wilayah belum dapat dimuat. Periksa koneksi lalu coba lagi.';
      });
      return null;
    }
  }

  Future<void> _findLocation() async {
    if (_locationLoading) return;
    var routeAfterLocation = _routingConsentGranted;
    if (!_locationConsentGranted) {
      final choice = await showDialog<_LocationUseChoice>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Pilih penggunaan lokasi'),
          content: const Text(
            'Lokasi perangkat diproses oleh server RANAH untuk alamat, gunung '
            'sekitar, dan analisis bahaya. Jika memilih simulasi jalur, koordinat '
            'juga diteruskan ke Valhalla demo. Pilihan lokasi saja tidak '
            'mengirim koordinat ke penyedia routing.',
          ),
          actions: [
            TextButton(
              key: const ValueKey('cancel-location-use'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(_LocationUseChoice.cancel),
              child: const Text('Batalkan'),
            ),
            OutlinedButton(
              key: const ValueKey('accept-location-only'),
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(_LocationUseChoice.locationOnly),
              child: const Text('Gunakan lokasi saja'),
            ),
            FilledButton(
              key: const ValueKey('accept-location-and-route'),
              onPressed: () =>
                  Navigator.of(dialogContext)
                      .pop(_LocationUseChoice.locationAndRoute),
              child: const Text('Lokasi + simulasi jalur'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null || choice == _LocationUseChoice.cancel) {
        return;
      }
      _locationConsentGranted = true;
      routeAfterLocation = choice == _LocationUseChoice.locationAndRoute;
      _routingConsentGranted = routeAfterLocation;
    }
    setState(() => _locationLoading = true);
    try {
      final location = await widget.locationReader().timeout(
        const Duration(seconds: 22),
      );
      if (!location.isValid) {
        throw const BrowserLocationException(
          BrowserLocationFailure.unavailable,
        );
      }
      if (!mounted) return;
      final generation = ++_requestGeneration;
      final sameLocation = _sameCoordinates(location, widget.currentLocation);
      setState(() {
        _areaLoading = false;
        _analysisLoading = false;
        _areaError = null;
        _analysisError = null;
      });
      if (!sameLocation) {
        _areaResolvedKey = null;
        _hazardResolvedKey = null;
        setState(() {
          _analysisResult = null;
        });
        widget.onAreaChanged(null);
      }
      _pendingLocationUpdate = location;
      widget.onLocationChanged(location);
      setState(() => _locationLoading = false);
      _routeRequestGeneration++;
      _routeResult = null;
      _routeError = null;
      _routeLoading = false;
      _selectedOsmFeature = null;
      final osmFuture = _loadOsmReferences();
      final areaFuture = _identifyArea(location, generation);
      unawaited(osmFuture);
      unawaited(areaFuture);
      unawaited(_analyzeHazards(location, generation));
      if (routeAfterLocation) {
        unawaited(
          _calculateAutomaticNearbyRoute(
            location,
            generation,
            osmFuture,
            areaFuture,
          ),
        );
      }
      if ((location.accuracyMeters ?? 0) > 1000) {
        _showMessage(
          'Lokasi ditemukan, tetapi akurasinya rendah '
          '(±${location.accuracyMeters!.round()} m).',
        );
      }
    } on BrowserLocationException catch (error) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      _showMessage(_locationError(error.failure));
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      _showMessage(_locationError(BrowserLocationFailure.timeout));
    } catch (_) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      _showMessage(
        'Lokasi tidak dapat diperoleh. Pastikan browser mendukung lokasi dan situs dibuka melalui HTTPS atau localhost.',
      );
    }
  }

  void _retryArea() {
    final location = widget.currentLocation;
    if (location != null) {
      unawaited(_identifyArea(location, _requestGeneration, force: true));
    }
  }

  void _retryHazards() {
    final location = widget.currentLocation;
    if (location != null) {
      unawaited(_analyzeHazards(location, _requestGeneration, force: true));
    }
  }

  void _retryOsm() => unawaited(_loadOsmReferences());

  Future<void> _calculateAutomaticNearbyRoute(
    BrowserLocation location,
    int generation,
    Future<OsmAssemblyPointDataset?> osmFuture,
    Future<BrowserAdministrativeArea?> areaFuture,
  ) async {
    final results = await Future.wait<Object?>([osmFuture, areaFuture]);
    if (!_isCurrentRequest(location, generation)) return;
    final dataset = results[0] as OsmAssemblyPointDataset?;
    final area = results[1] as BrowserAdministrativeArea?;
    if (!_isPadangCity(area?.regency)) {
      _showMessage(
        'Wilayah Kota Padang belum terkonfirmasi; simulasi jalur tidak dijalankan.',
      );
      return;
    }
    if (dataset == null) {
      _showMessage(
        'Belum tersedia titik kumpul yang dapat dirutekan di sekitar lokasi Anda.',
      );
      return;
    }

    final origin = LatLng(location.latitude, location.longitude);
    final candidates =
        dataset.features
            .where(
              (feature) =>
                  feature.geometryType == 'Point' &&
                  feature.point != null &&
                  feature.point!.latitude >= -90 &&
                  feature.point!.latitude <= 90 &&
                  feature.point!.longitude >= -180 &&
                  feature.point!.longitude <= 180,
            )
            .map(
              (feature) => (
                feature: feature,
                distanceKm: const Distance().as(
                  LengthUnit.Kilometer,
                  origin,
                  feature.point!,
                ),
              ),
            )
            .where(
              (candidate) =>
                  candidate.distanceKm <= _maximumAutomaticRouteDistanceKm,
            )
            .toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (candidates.isEmpty) {
      _showMessage(
        'Belum tersedia titik kumpul yang dapat dirutekan di sekitar lokasi Anda.',
      );
      return;
    }

    final destination = candidates.first.feature;
    if (!_isCurrentRequest(location, generation)) return;
    _selectOsmFeature(destination);
    await _calculateRoute(destination, consentAlreadyGranted: true);
  }

  bool _isPadangCity(String? regency) {
    final normalized = regency
        ?.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized == 'padang' || normalized == 'kota padang';
  }

  String _locationError(BrowserLocationFailure failure) => switch (failure) {
    BrowserLocationFailure.permissionDenied => 'Izin lokasi ditolak. Izinkan lokasi pada pengaturan browser lalu coba lagi.',
    BrowserLocationFailure.timeout =>
      'Browser tidak memperoleh lokasi sebelum batas waktu. Coba lagi.',
    BrowserLocationFailure.unsupported => 'Browser tidak mendukung geolokasi atau situs perlu dibuka melalui HTTPS/localhost.',
    BrowserLocationFailure.unavailable =>
      'Lokasi perangkat tidak tersedia. Periksa layanan lokasi lalu coba lagi.',
  };

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final mobile = width < 700;
      final contentWidth = width > RanahLayout.maxContentWidth
          ? RanahLayout.maxContentWidth
          : width;
      final horizontalInset = mobile ? 8.0 : 20.0;
      final innerWidth = contentWidth - horizontalInset * 2;
      final viewportHeight = MediaQuery.sizeOf(context).height;
      final mapHeight = mobile
          ? (viewportHeight * .54).clamp(320.0, 500.0)
          : width < 1000
          ? (viewportHeight * .62).clamp(430.0, 650.0)
          : (viewportHeight * .68).clamp(500.0, 760.0);
      final location = widget.currentLocation;

      return RanahPageScrollLayout(
        maxContentWidth: contentWidth,
        horizontalInset: horizontalInset,
        title: _MapTitleBanner(maxContentWidth: innerWidth),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: mobile ? RanahSpacing.sm : RanahSpacing.lg),
            SizedBox(
              height: mapHeight,
              child: _InteractiveMap(
                key: ValueKey(
                  location == null
                      ? 'indonesia-map'
                      : 'user-map-${location.latitude},${location.longitude}',
                ),
                location: location,
                tilesEnabled: widget.tilesEnabled,
                osmFeatures: location == null
                    ? const []
                    : _osmDataset?.features ?? const [],
                selectedFeatureId: _selectedOsmFeature?.id,
                route: _routeResult,
                onFeatureTap: _showOsmFeatureDetail,
              ),
            ),
            if (location != null)
              _OsmMapStatus(
                loading: _osmLoading,
                error: _osmError,
                featureCount: _osmDataset?.features.length ?? 0,
                onRetry: _retryOsm,
              ),
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _RouteSimulationPanel(
                  selectedFeature: _selectedOsmFeature,
                  features: _osmDataset?.features ?? const [],
                  loading: _routeLoading,
                  error: _routeError,
                  route: _routeResult,
                  onSelectFeature: _selectOsmFeature,
                  onShowRoute: _selectedOsmFeature?.geometryType == 'Point'
                      ? () => _calculateRoute(_selectedOsmFeature!)
                      : null,
                  onClose: _closeRoute,
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 5),
              child: Text(
                'Data peta: © OpenStreetMap contributors · ODbL. Fitur lokal berstatus belum diverifikasi.',
                style: TextStyle(fontSize: 10, color: Color(0xFFD1DCE9)),
              ),
            ),
            if (location == null)
              _buildMapActions(mobile)
            else
              _buildLocationDetails(mobile, location),
          ],
        ),
      );
    },
  );

  Widget _buildMapActions(bool mobile) => Padding(
    padding: EdgeInsets.fromLTRB(
      mobile ? RanahSpacing.sm : 0,
      RanahSpacing.lg,
      mobile ? RanahSpacing.sm : 0,
      0,
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final gap = mobile ? RanahSpacing.md : RanahSpacing.xl;
        final actionWidth = mobile
            ? constraints.maxWidth
            : (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: RanahSpacing.lg,
          children: [
            SizedBox(
              width: constraints.maxWidth,
              child: const Text(
                'Tekan tombol untuk menandai lokasi dan memuat perkiraan alamat, data gunung di wilayah, serta informasi bahaya yang tersedia.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFFD1DCE9),
                  height: 1.4,
                ),
              ),
            ),
            _MapAction(
              width: actionWidth,
              buttonKey: const ValueKey('find-device-location'),
              icon: Icons.location_on_rounded,
              label: _locationLoading
                  ? 'Mencari Lokasi...'
                  : 'Temukan Lokasi Saya',
              description: 'Lihat lokasi perangkat dan informasi sekitar.',
              onTap: _locationLoading ? null : _findLocation,
              loading: _locationLoading,
            ),
            _MapAction(
              width: actionWidth,
              icon: Icons.landscape_rounded,
              label: 'Laporan Aktivitas Gunung',
              description: 'Buka data aktivitas gunung dari RANAH.',
              onTap: widget.onActivityTap,
            ),
          ],
        );
      },
    ),
  );

  Widget _buildLocationDetails(
    bool mobile,
    BrowserLocation location,
  ) => Padding(
    padding: EdgeInsets.fromLTRB(
      mobile ? RanahSpacing.xs : 0,
      RanahSpacing.md,
      mobile ? RanahSpacing.xs : 0,
      0,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CurrentLocationCard(
          location: location,
          area: widget.currentArea,
          loading: _areaLoading,
          error: _areaError,
          onRetryArea: _retryArea,
          locationLoading: _locationLoading,
          onRefreshLocation: _findLocation,
        ),
        const SizedBox(height: RanahSpacing.lg),
        const _SectionHeading(
          icon: Icons.alt_route_rounded,
          title: 'Jalur Evakuasi',
          subtitle: 'Referensi OSM pada peta utama',
        ),
        const SizedBox(height: RanahSpacing.sm),
        _UnavailableCard(
          icon: Icons.alt_route_rounded,
          title: 'Referensi OSM ditampilkan pada peta.',
          description: 'Fitur yang terlihat belum diverifikasi sebagai fasilitas evakuasi, tidak menyatakan titik aman untuk tsunami, dan tidak berarti sebagai tujuan terdekat.',
          action: widget.onOpenEvacuation == null
              ? null
              : TextButton.icon(
                  key: const ValueKey('open-osm-evacuation-references'),
                  onPressed: widget.onOpenEvacuation,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Detail sumber OSM'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
        ),
        const SizedBox(height: RanahSpacing.lg),
        _SectionHeading(
          icon: Icons.landscape_outlined,
          title: 'Gunung Aktif Sekitar',
          subtitle: widget.currentArea?.province == null
              ? 'Data ditampilkan setelah wilayah ditemukan'
              : 'Provinsi ${widget.currentArea!.province}',
          trailing: TextButton(
            onPressed: widget.onActivityTap,
            child: const Text(
              'Lihat daftar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: RanahSpacing.sm),
        _NearbyVolcanoList(
          area: widget.currentArea,
          areaLoading: _areaLoading,
          areaError: _areaError,
          location: location,
          records: widget.gunung,
          isLoading: widget.gunungLoading,
          error: widget.gunungError,
          onRetry: widget.onRetryGunung,
          onOpenReport: widget.onOpenReport,
        ),
        const SizedBox(height: RanahSpacing.lg),
        const _SectionHeading(
          icon: Icons.monitor_heart_outlined,
          title: 'Potensi Bencana di Lokasi',
          subtitle: 'Analisis data geospasial tersedia atas permintaan',
        ),
        const SizedBox(height: RanahSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analisis empat kategori dijalankan otomatis setelah lokasi diperoleh. Ini adalah kajian data bahaya wilayah, bukan peringatan kejadian real-time atau pernyataan aman.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFD1DCE9),
                height: 1.35,
              ),
            ),
            if (_analysisError != null) ...[
              const SizedBox(height: 8),
              _UnavailableCard(
                icon: Icons.cloud_off,
                title: 'Analisis belum dapat dimuat.',
                description: _analysisError!,
                action: TextButton.icon(
                  key: const ValueKey('retry-hazard-analysis'),
                  onPressed: _analysisLoading ? null : _retryHazards,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: RanahSpacing.sm),
        LayoutBuilder(
          builder: (context, box) {
            final columns = mobile ? 1 : 2;
            final gap = RanahSpacing.sm;
            final cardWidth = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final hazard in _hazardTypes)
                  SizedBox(
                    width: cardWidth,
                    child: _analysisResult == null
                        ? _UnavailableCard(
                            icon: hazard.$1,
                            title: _analysisLoading
                                ? 'Menganalisis ${hazard.$2}...'
                                : hazard.$2,
                            description: _analysisLoading
                                ? 'Menunggu hasil untuk koordinat lokasi yang dipilih.'
                                : _analysisError != null
                                ? 'Layanan analisis tidak tersedia.'
                                : hazard.$2 == 'Letusan Gunung Api'
                                ? 'Informasi kawasan rawan gunung api belum dapat ditentukan untuk lokasi ini.'
                                : 'Belum dianalisis pada tahap ini.',
                          )
                        : switch (hazard.$2) {
                            'Tsunami' => _RasterHazardCard(
                              icon: hazard.$1,
                              label: hazard.$2,
                              result: _analysisResult!.tsunami,
                              analyzedAt: _analysisResult!.analyzedAt,
                              locationUncertain:
                                  location.accuracyMeters == null ||
                                  location.accuracyMeters! > 1000,
                            ),
                            'Banjir' => _RasterHazardCard(
                              icon: hazard.$1,
                              label: hazard.$2,
                              result: _analysisResult!.flood,
                              analyzedAt: _analysisResult!.analyzedAt,
                              locationUncertain:
                                  location.accuracyMeters == null ||
                                  location.accuracyMeters! > 1000,
                            ),
                            'Gempa Bumi' => _RasterHazardCard(
                              icon: hazard.$1,
                              label: hazard.$2,
                              result: _analysisResult!.earthquake,
                              analyzedAt: _analysisResult!.analyzedAt,
                              locationUncertain:
                                  location.accuracyMeters == null ||
                                  location.accuracyMeters! > 1000,
                            ),
                            'Letusan Gunung Api' => _VolcanoHazardCard(
                              result: _analysisResult!,
                              locationUncertain:
                                  location.accuracyMeters == null ||
                                  location.accuracyMeters! > 1000,
                            ),
                            _ => const SizedBox.shrink(),
                          },
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

const _hazardTypes = <(IconData, String)>[
  (Icons.waves_rounded, 'Tsunami'),
  (Icons.water_rounded, 'Banjir'),
  (Icons.vibration_rounded, 'Gempa Bumi'),
  (Icons.landscape_rounded, 'Letusan Gunung Api'),
];

class _InteractiveMap extends StatelessWidget {
  const _InteractiveMap({
    required this.location,
    required this.tilesEnabled,
    required this.osmFeatures,
    required this.selectedFeatureId,
    required this.route,
    required this.onFeatureTap,
    super.key,
  });

  final BrowserLocation? location;
  final bool tilesEnabled;
  final List<OsmAssemblyPoint> osmFeatures;
  final String? selectedFeatureId;
  final RouteSimulationResult? route;
  final ValueChanged<OsmAssemblyPoint> onFeatureTap;

  @override
  Widget build(BuildContext context) {
    final center = location == null
        ? const LatLng(-2.5, 118)
        : LatLng(location!.latitude, location!.longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: location == null ? 4.2 : 13,
              minZoom: 2,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              if (tilesEnabled)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ranah.web',
                  maxNativeZoom: 19,
                ),
              PolygonLayer(
                polygons: [
                  for (final feature in osmFeatures)
                    if (feature.geometryType == 'Polygon')
                      Polygon(
                        points: feature.rings.first,
                        holePointsList: feature.rings.skip(1).toList(),
                        color: const Color(0x5541C6D7),
                        borderColor: const Color(0xFF67D3E3),
                        borderStrokeWidth: 2,
                      ),
                ],
              ),
              if (route case final currentRoute?)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: currentRoute.coordinates,
                      color: const Color(0xFFFFD166),
                      strokeWidth: 5,
                      borderColor: const Color(0xFF10243A),
                      borderStrokeWidth: 1.5,
                    ),
                  ],
                ),
              if (location != null || osmFeatures.isNotEmpty)
                MarkerLayer(
                  markers: [
                    for (final feature in osmFeatures)
                      Marker(
                        point: feature.displayPosition,
                        width: 54,
                        height: 58,
                        child: Semantics(
                          button: true,
                          label:
                              '${feature.name ?? 'Objek OSM'}, ${feature.geometryType}, belum diverifikasi',
                          child: GestureDetector(
                            onTap: () => onFeatureTap(feature),
                            child: Icon(
                              feature.geometryType == 'Point'
                                  ? Icons.location_on
                                  : Icons.crop_square_rounded,
                              key: ValueKey('map-osm-feature-${feature.id}'),
                              color: feature.id == selectedFeatureId
                                  ? const Color(0xFFFFD166)
                                  : const Color(0xFF62D2E0),
                              size: 40,
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
                    if (location != null)
                      Marker(
                        point: center,
                        width: 48,
                        height: 56,
                        child: IgnorePointer(
                          child: Semantics(
                            label: 'Lokasi perangkat saat ini',
                            child: const Icon(
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
                      ),
                  ],
                ),
              if (tilesEnabled)
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 8,
            right: 9,
            child: _MapTag(
              text: location == null ? 'PETA INTERAKTIF' : 'LOKASI ANDA',
            ),
          ),
          if (!tilesEnabled)
            const IgnorePointer(
              child: Center(
                child: Text(
                  'Latar peta membutuhkan koneksi internet',
                  style: TextStyle(
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OsmFeatureQuickDetail extends StatelessWidget {
  const _OsmFeatureQuickDetail({required this.feature, this.onShowRoute});

  final OsmAssemblyPoint feature;
  final VoidCallback? onShowRoute;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feature.name ?? 'Objek OpenStreetMap',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Geometri: ${feature.geometryType}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Sumber: OpenStreetMap · ${feature.id}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            feature.status,
            style: const TextStyle(color: Color(0xFFFFD37A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Data ini belum diverifikasi sebagai fasilitas evakuasi dan tidak menetapkan keamanan tsunami.',
            style: TextStyle(color: Colors.white),
          ),
          if (feature.geometryType == 'Polygon')
            const Text(
              'Area ditampilkan apa adanya; penanda pilihannya bukan akses masuk.',
              style: TextStyle(color: Colors.white70),
            ),
          if (feature.geometryType == 'Polygon')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Rute tidak tersedia: dataset belum menyediakan titik akses yang valid untuk area ini.',
                style: TextStyle(color: Color(0xFFFFD37A)),
              ),
            ),
          if (onShowRoute != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey('show-route-${feature.id}'),
                onPressed: onShowRoute,
                icon: const Icon(Icons.alt_route_rounded),
                label: const Text('Tampilkan Jalur'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _RouteSimulationPanel extends StatelessWidget {
  const _RouteSimulationPanel({
    required this.selectedFeature,
    required this.features,
    required this.loading,
    required this.error,
    required this.route,
    required this.onSelectFeature,
    required this.onShowRoute,
    required this.onClose,
  });

  final OsmAssemblyPoint? selectedFeature;
  final List<OsmAssemblyPoint> features;
  final bool loading;
  final String? error;
  final RouteSimulationResult? route;
  final ValueChanged<OsmAssemblyPoint> onSelectFeature;
  final VoidCallback? onShowRoute;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final selected = selectedFeature;
    return Container(
      key: const ValueKey('route-simulation-panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF102B43),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF45627B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.alt_route_rounded, color: Color(0xFF7ED5DE)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Simulasi rute pejalan kaki',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Jika Anda menyetujui lokasi dan simulasi jalur, satu titik Point OSM terdekat dalam cakupan Padang dapat diminta otomatis melalui Laravel. Anda juga dapat memilih Point lain. Polygon tidak digunakan sebagai pintu masuk.',
            style: TextStyle(color: Color(0xFFD1DCE9), fontSize: 12),
          ),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 7,
              runSpacing: 4,
              children: [
                for (final feature in features)
                  OutlinedButton.icon(
                    key: ValueKey('select-route-destination-${feature.id}'),
                    onPressed: loading ? null : () => onSelectFeature(feature),
                    icon: Icon(
                      feature.geometryType == 'Point'
                          ? Icons.location_on_outlined
                          : Icons.crop_square_rounded,
                      size: 17,
                    ),
                    label: Text(
                      feature.geometryType == 'Point'
                          ? 'Pilih tujuan: ${feature.name ?? feature.id}'
                          : 'Pilih area: ${feature.name ?? feature.id}',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF71889D)),
                    ),
                  ),
              ],
            ),
          ],
          if (selected != null) ...[
            const SizedBox(height: 8),
            Text(
              'Tujuan: ${selected.name ?? 'Objek OSM tanpa nama'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              selected.status,
              style: const TextStyle(color: Color(0xFFFFD37A), fontSize: 12),
            ),
            if (selected.geometryType == 'Polygon')
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Tidak ada garis rute: area Polygon tidak digunakan sebagai pintu masuk.',
                  style: TextStyle(color: Color(0xFFFFD37A), fontSize: 12),
                ),
              ),
          ],
          if (loading) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
            const SizedBox(height: 5),
            const Text(
              'Meminta rute pejalan kaki ke Laravel...',
              style: TextStyle(color: Color(0xFFD1DCE9), fontSize: 12),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              key: const ValueKey('route-error'),
              style: const TextStyle(color: Color(0xFFFFD37A), fontSize: 12),
            ),
          ],
          if (route case final currentRoute?) ...[
            const SizedBox(height: 8),
            if (currentRoute.durationSeconds != null)
              Text(
                'Perkiraan durasi berjalan kaki: ${_formatRouteDuration(currentRoute.durationSeconds!)}',
                key: const ValueKey('route-estimated-duration'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Text(
              'Jarak jaringan jalan: ${currentRoute.distanceKm.toStringAsFixed(2)} km',
              key: const ValueKey('route-distance'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              currentRoute.warning,
              key: const ValueKey('route-warning'),
              style: const TextStyle(
                color: Color(0xFFFFD37A),
                fontSize: 12,
                height: 1.35,
              ),
            ),
            Text(
              '${currentRoute.method} · ${currentRoute.attribution}',
              style: const TextStyle(color: Color(0xFFD1DCE9), fontSize: 11),
            ),
          ],
          if (selected != null && selected.geometryType == 'Point') ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilledButton.icon(
                  key: const ValueKey('calculate-selected-route'),
                  onPressed: loading ? null : onShowRoute,
                  icon: const Icon(Icons.alt_route_rounded),
                  label: Text(loading ? 'Menghitung...' : 'Tampilkan Jalur'),
                ),
                if (route != null || error != null)
                  TextButton.icon(
                    key: const ValueKey('close-simulated-route'),
                    onPressed: loading ? null : onClose,
                    icon: const Icon(Icons.close),
                    label: const Text('Tutup rute'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                  ),
              ],
            ),
          ],
          if (selected == null)
            const Padding(
              padding: EdgeInsets.only(top: 7),
              child: Text(
                'Belum ada tujuan dipilih. Rute tidak diminta otomatis.',
                style: TextStyle(color: Color(0xFFC7D2E0), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

String _formatRouteDuration(double seconds) {
  final minutes = (seconds / 60).ceil();
  if (minutes < 60) return '$minutes menit';
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  return remainingMinutes == 0
      ? '$hours jam'
      : '$hours jam $remainingMinutes menit';
}

class _MapTitleBanner extends StatelessWidget {
  const _MapTitleBanner({required this.maxContentWidth});

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
      child: Row(
        children: [
          const Icon(Icons.landscape_outlined, size: 28, color: Colors.white),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PETA & ZONA BAHAYA',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Color(0xFF91A8D0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Peta dan Jalur Evakuasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Peta interaktif dan lokasi perangkat',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.width,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.loading = false,
    this.buttonKey,
  });

  final double width;
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback? onTap;
  final bool loading;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            key: buttonKey,
            onPressed: onTap,
            icon: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon, size: 17),
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
          style: const TextStyle(color: Color(0xFFD1DCE9), fontSize: 12),
        ),
      ],
    ),
  );
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({
    required this.location,
    required this.area,
    required this.loading,
    required this.error,
    required this.onRetryArea,
    required this.locationLoading,
    required this.onRefreshLocation,
  });

  final BrowserLocation location;
  final BrowserAdministrativeArea? area;
  final bool loading;
  final String? error;
  final VoidCallback onRetryArea;
  final bool locationLoading;
  final VoidCallback onRefreshLocation;

  @override
  Widget build(BuildContext context) {
    final accuracy = location.accuracyMeters;
    final lowAccuracy = accuracy != null && accuracy > 1000;
    final street = _usableAddress(area?.street);
    final locality = _usableAddress(area?.locality);
    final regency = _usableAddress(area?.regency);
    final province = _usableAddress(area?.province);
    final primaryCandidates = [
      street,
      locality,
      regency,
      province,
    ].whereType<String>().toList(growable: false);
    final primary = primaryCandidates.isEmpty ? null : primaryCandidates.first;
    final candidates = <(String, String?)>[
      ('Wilayah setempat', locality),
      ('Kecamatan', _usableAddress(area?.district)),
      ('Kota/Kabupaten', regency),
      ('Provinsi', province),
    ];
    final seen = <String>{if (primary != null) primary.toLowerCase()};
    final addressDetails = <(String, String)>[];
    for (final candidate in candidates) {
      final value = candidate.$2;
      if (value != null && seen.add(value.toLowerCase())) {
        addressDetails.add((candidate.$1, value));
      }
    }
    return Container(
      key: const ValueKey('current-device-location'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_pin,
                color: Color(0xFFFF3941),
                size: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi Anda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      primary ??
                          (loading
                              ? 'Mengambil perkiraan alamat...'
                              : 'Alamat belum dapat ditampilkan.'),
                      key: const ValueKey('device-location-street'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final detail in addressDetails)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${detail.$1}: ${detail.$2}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE2EAF2),
                          ),
                        ),
                      ),
                    if (loading && primary != null)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Memperbarui alamat...',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD1DCE9),
                          ),
                        ),
                      ),
                    if (error != null)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              error!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFFFC477),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: loading ? null : onRetryArea,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Color(0x557FA4C2), height: 14),
          Text(
            'Koordinat: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            key: const ValueKey('device-location-coordinates'),
            style: const TextStyle(fontSize: 11, color: Color(0xFFD1DCE9)),
          ),
          Text(
            accuracy == null
                ? 'Akurasi perangkat: tidak tersedia'
                : 'Akurasi perangkat: sekitar ±${accuracy.round()} meter${lowAccuracy ? ' · akurasi rendah' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: lowAccuracy
                  ? const Color(0xFFFFC477)
                  : const Color(0xFFD1DCE9),
            ),
          ),
          Text(
            'Lokasi diukur: ${location.measuredAt == null ? 'waktu tidak tersedia' : _formatDate(location.measuredAt!)}',
            style: const TextStyle(fontSize: 10, color: Color(0xFFC7D2E0)),
          ),
          if (area?.source != null && area!.source!.trim().isNotEmpty)
            Text(
              'Sumber alamat: ${area!.source}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFC7D2E0)),
            ),
          if (area?.retrievedAt != null)
            Text(
              'Alamat diperbarui: ${_formatDate(area!.retrievedAt!)}',
              style: const TextStyle(fontSize: 10, color: Color(0xFFC7D2E0)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('refresh-device-location'),
              onPressed: locationLoading ? null : onRefreshLocation,
              icon: locationLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: Text(
                locationLoading ? 'Memperbarui lokasi...' : 'Perbarui Lokasi',
              ),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Alamat adalah perkiraan dari Nominatim, bukan alamat bangunan yang dijamin tepat. © OpenStreetMap contributors · ODbL',
              style: TextStyle(fontSize: 10, color: Color(0xFFD1DCE9)),
            ),
          ),
        ],
      ),
    );
  }
}

String? _usableAddress(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
      final compact = constraints.maxWidth < 460 || largeText;
      final titleContent = Row(
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFC7D2E0),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      if (trailing == null) return titleContent;
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleContent,
            Align(alignment: Alignment.centerRight, child: trailing),
          ],
        );
      }
      return Row(
        children: [
          Expanded(child: titleContent),
          trailing!,
        ],
      );
    },
  );
}

class _NearbyVolcanoList extends StatelessWidget {
  const _NearbyVolcanoList({
    required this.area,
    required this.areaLoading,
    required this.areaError,
    required this.location,
    required this.records,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onOpenReport,
  });

  final BrowserAdministrativeArea? area;
  final bool areaLoading;
  final String? areaError;
  final BrowserLocation location;
  final List<GunungRecord> records;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<GunungRecord> onOpenReport;

  @override
  Widget build(BuildContext context) {
    final province = area?.province;
    if (areaLoading && province == null) {
      return const _UnavailableCard(
        icon: Icons.hourglass_top,
        title: 'Mengidentifikasi provinsi...',
        description: 'Daftar gunung akan difilter setelah wilayah tersedia.',
      );
    }
    if (province == null || province.isEmpty) {
      return _UnavailableCard(
        icon: Icons.landscape_outlined,
        title: 'Provinsi belum diidentifikasi.',
        description: areaError ?? 'Daftar gunung tidak ditampilkan sampai provinsi tersedia dari perkiraan alamat.',
      );
    }
    if (isLoading && records.isEmpty) {
      return const _UnavailableCard(
        icon: Icons.hourglass_top,
        title: 'Memuat daftar gunung dari Laravel...',
        description:
            'Data aktivitas akan ditampilkan setelah respons API tersedia.',
      );
    }
    if (error != null && records.isEmpty) {
      return _UnavailableCard(
        icon: Icons.cloud_off,
        title: 'Daftar gunung belum dapat dimuat.',
        description: error!,
        action: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
        ),
      );
    }
    final items = volcanoesForProvince(
      records: records,
      province: province,
      origin: location,
    );
    if (items.isEmpty) {
      return _UnavailableCard(
        icon: Icons.search_off,
        title: 'Tidak ada gunung pada data API untuk $province.',
        description: 'Ini hanya mencerminkan respons Laravel dan kecocokan nama wilayah yang tersedia; bukan pernyataan bahwa wilayah bebas bahaya.',
        action: error == null
            ? null
            : TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
      );
    }
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _NearbyVolcanoCard(
              item: item,
              onTap: () => onOpenReport(item.record),
            ),
          ),
        if (error != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Perbarui data gunung'),
            ),
          ),
      ],
    );
  }
}

class _NearbyVolcanoCard extends StatelessWidget {
  const _NearbyVolcanoCard({required this.item, required this.onTap});
  final NearbyVolcano item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final record = item.record;
    final region = [
      record.kabupaten,
      record.provinsi,
    ].where((value) => value != null && value.trim().isNotEmpty).join(', ');
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF174A7D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF547999)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: ListTile(
          key: ValueKey('map-volcano-${record.id}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 5,
          ),
          leading: const CircleAvatar(
            backgroundColor: Color(0xFF0F5473),
            child: Icon(Icons.landscape_outlined, color: Colors.white),
          ),
          title: Text(
            record.nama,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (region.isNotEmpty)
                Text(region, style: const TextStyle(color: Colors.white)),
              if (item.distanceKm case final distance?)
                Text(
                  'Jarak garis lurus: ${distance.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.white),
                )
              else
                const Text(
                  'Jarak tidak ditampilkan: koordinat belum terverifikasi.',
                  style: TextStyle(color: Colors.white),
                ),
              if (record.statusAktivitas?.trim().isNotEmpty == true)
                Text(
                  'Status dari API: ${record.statusAktivitas}',
                  style: const TextStyle(color: Colors.white),
                ),
              if (record.waktuPengambilan != null)
                Text(
                  'Diambil server: ${_formatDate(record.waktuPengambilan!)}',
                  style: const TextStyle(color: Colors.white),
                ),
            ],
          ),
          trailing: const Icon(Icons.open_in_new, color: Colors.white70),
          onTap: onTap,
        ),
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _OsmMapStatus extends StatelessWidget {
  const _OsmMapStatus({
    required this.loading,
    required this.error,
    required this.featureCount,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final int featureCount;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Memuat referensi OpenStreetMap...',
                softWrap: true,
                style: TextStyle(color: Color(0xFFD1DCE9), fontSize: 11),
              ),
            ),
          ],
        ),
      );
    }
    if (error != null) {
      return _UnavailableCard(
        icon: Icons.cloud_off,
        title: 'Referensi OSM tidak tersedia.',
        description: error!,
        action: TextButton.icon(
          key: const ValueKey('retry-map-osm'),
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Coba lagi'),
          style: TextButton.styleFrom(foregroundColor: Colors.white),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        featureCount == 0
            ? 'API RANAH belum menyediakan fitur OSM untuk ditampilkan.'
            : '$featureCount fitur referensi OSM ditampilkan; bukan daftar fasilitas evakuasi terverifikasi.',
        style: const TextStyle(fontSize: 11, color: Color(0xFFD1DCE9)),
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  const _UnavailableCard({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF174A7D),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF286D9C)),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF8FC3D6), size: 22),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Color(0xFFC7D2E0)),
              ),
              ?action,
            ],
          ),
        ),
      ],
    ),
  );
}

enum _HazardFinding { indicated, notIndicated, uncertain, unavailable }

extension on _HazardFinding {
  IconData get icon => switch (this) {
    _HazardFinding.indicated => Icons.warning_rounded,
    _HazardFinding.notIndicated => Icons.check_circle_rounded,
    _HazardFinding.uncertain => Icons.help_outline_rounded,
    _HazardFinding.unavailable => Icons.cloud_off_rounded,
  };

  Color get color => switch (this) {
    _HazardFinding.indicated => const Color(0xFFFF6B6B),
    _HazardFinding.notIndicated => const Color(0xFF5BE0A0),
    _HazardFinding.uncertain => const Color(0xFFFFD37A),
    _HazardFinding.unavailable => const Color(0xFFB8C7D4),
  };

  String get label => switch (this) {
    _HazardFinding.indicated => 'TERINDIKASI PADA DATA YANG DIPERIKSA',
    _HazardFinding.notIndicated => 'TIDAK TERINDIKASI PADA DATA YANG DIPERIKSA',
    _HazardFinding.uncertain => 'BELUM DAPAT DIPASTIKAN',
    _HazardFinding.unavailable => 'DATA SEMENTARA TIDAK DAPAT DIMUAT',
  };
}

class _HazardResultCard extends StatelessWidget {
  const _HazardResultCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.finding,
    required this.details,
    required this.detailsKey,
  });

  final IconData icon;
  final String title;
  final String summary;
  final _HazardFinding finding;
  final List<String> details;
  final Key detailsKey;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 72),
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
    decoration: BoxDecoration(
      color: const Color(0xFF174A7D),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: const Color(0xFF286D9C)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: const Color(0xFF8FC3D6), size: 22),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(finding.icon, color: finding.color, size: 16),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      finding.label,
                      style: TextStyle(
                        color: finding.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  summary,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFE0E8F1),
                    height: 1.35,
                  ),
                ),
              ),
              if (details.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: ExpansionTile(
                    key: detailsKey,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 8),
                    minTileHeight: 40,
                    title: const Text(
                      'Detail Sumber',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    collapsedTextColor: Colors.white,
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    collapsedIconColor: Colors.white,
                    children: [
                      for (final detail in details)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: SelectableText(
                              detail,
                              style: const TextStyle(
                                color: Color(0xFFD1DCE9),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _VolcanoHazardCard extends StatelessWidget {
  const _VolcanoHazardCard({
    required this.result,
    required this.locationUncertain,
  });

  final HazardAnalysisResult result;
  final bool locationUncertain;

  @override
  Widget build(BuildContext context) {
    final volcano = result.volcano;
    final finding = volcano.status == 'layanan_gagal'
        ? _HazardFinding.unavailable
        : locationUncertain
        ? _HazardFinding.uncertain
        : volcano.status == 'hasil_tersedia'
        ? _HazardFinding.indicated
        : _HazardFinding.uncertain;
    final summary = switch (volcano.status) {
      'hasil_tersedia' when locationUncertain => 'Koordinat nominal beririsan dengan poligon KRB BIG, tetapi akurasi lokasi rendah atau tidak tersedia.',
      'hasil_tersedia' => 'Titik yang diperiksa beririsan dengan poligon KRB BIG. Ini kajian spasial, bukan peringatan aktif.',
      'di_luar_cakupan_layer' => 'Lokasi di luar cakupan layer yang diperiksa. Ini bukan bukti bahwa lokasi aman.',
      'layanan_gagal' => 'Data KRB sementara tidak dapat dimuat.',
      'no_data' => 'Data KRB untuk lokasi ini belum ditemukan. Ini bukan bukti bahwa lokasi aman.',
      _ => 'Informasi kawasan rawan gunung api belum dapat ditentukan.',
    };
    final lines = <String>[volcano.explanation];
    for (final feature in volcano.features) {
      lines.add(
        '${feature.volcanoName} · ${feature.zone} · Tahun peta ${feature.mapYear ?? 'tidak tersedia'} · ID fitur ${feature.sourceFeatureId}',
      );
    }
    if (volcano.source.isNotEmpty) lines.add('Sumber: ${volcano.source}');
    if (volcano.sourceUrl.isNotEmpty) lines.add(volcano.sourceUrl);
    if (volcano.method.isNotEmpty) lines.add('Metode: ${volcano.method}');
    if (result.analyzedAt != null) {
      lines.add('Waktu analisis: ${_formatDate(result.analyzedAt!)}');
    }
    if (volcano.limitations.isNotEmpty) {
      lines.add('Batasan: ${volcano.limitations}');
    }
    return _HazardResultCard(
      icon: Icons.landscape_rounded,
      title: 'Kawasan Rawan Gunung Api',
      summary: summary,
      finding: finding,
      details: lines,
      detailsKey: const ValueKey('hazard-details-krb'),
    );
  }
}

class _RasterHazardCard extends StatelessWidget {
  const _RasterHazardCard({
    required this.icon,
    required this.label,
    required this.result,
    required this.analyzedAt,
    required this.locationUncertain,
  });

  final IconData icon;
  final String label;
  final RasterHazardResult result;
  final DateTime? analyzedAt;
  final bool locationUncertain;

  @override
  Widget build(BuildContext context) {
    final summary = switch (result.status) {
      'klasifikasi_belum_diverifikasi' => 'Nilai data tersedia, tetapi klasifikasi bahaya tidak tersedia dan tidak disimpulkan.',
      'no_data' =>
        'Data untuk lokasi ini belum tersedia. Ini tidak berarti lokasi aman.',
      'titik_di_luar_cakupan' => 'Lokasi berada di luar cakupan data. Ini bukan penilaian bahwa lokasi aman.',
      'layanan_bermasalah' => 'Layanan data sementara tidak dapat dimuat.',
      'belum_dianalisis' => 'Data belum dianalisis.',
      _ => 'Tingkat bahaya untuk lokasi ini belum dapat ditentukan.',
    };
    final finding = result.status == 'layanan_bermasalah'
        ? _HazardFinding.unavailable
        : _HazardFinding.uncertain;
    final details = <String>[result.explanation];
    if (result.classification != null) {
      details.add('Klasifikasi: ${result.classification}');
    }
    if (result.pixelValue != null) {
      details.add('Nilai piksel raster (mentah): ${result.pixelValue}');
    }
    if (result.dataset != null) details.add('Dataset: ${result.dataset}');
    if (result.valueType != null) {
      details.add('Jenis nilai: ${result.valueType}');
    }
    if (result.dataType != null) {
      details.add('Tipe raster: ${result.dataType}');
    }
    if (result.methodologyUrl != null) {
      details.add('Metodologi: ${result.methodologyUrl}');
    }
    if (result.queryMethod != null) {
      details.add('Metode: ${result.queryMethod}');
    }
    if (result.source != null) details.add('Sumber: ${result.source}');
    if (result.sourceUrl != null) details.add(result.sourceUrl!);
    if (result.year != null) details.add('Tahun data: ${result.year}');
    if (result.pixelSizeMeters != null) {
      details.add('Ukuran piksel: ${result.pixelSizeMeters} m');
    }
    if (result.spatialReference != null) {
      details.add('Sistem koordinat data: ${result.spatialReference}');
    }
    if (analyzedAt != null) {
      details.add('Waktu analisis: ${_formatDate(analyzedAt!)}');
    }
    if (result.limitations != null) {
      details.add('Batasan: ${result.limitations}');
    }
    return _HazardResultCard(
      icon: icon,
      title: label,
      summary: locationUncertain
          ? '$summary Akurasi lokasi rendah atau tidak tersedia; hasil titik tidak dapat dipastikan.'
          : summary,
      finding: finding,
      details: details,
      detailsKey: ValueKey('hazard-details-${_hazardKey(label)}'),
    );
  }
}

String _hazardKey(String label) => switch (label) {
  'Tsunami' => 'tsunami',
  'Banjir' => 'banjir',
  'Gempa Bumi' => 'gempa',
  _ => 'gunung-api',
};

class _MapTag extends StatelessWidget {
  const _MapTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xB80A2140),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: .4,
      ),
    ),
  );
}

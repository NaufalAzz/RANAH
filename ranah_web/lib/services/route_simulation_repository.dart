import 'package:latlong2/latlong.dart';

import 'ranah_api_client.dart';

const routeSimulationDisclaimer =
    'Simulasi Jalur Menuju Titik Kumpul — Bukan Jalur Evakuasi Resmi. Jalur mengikuti data jalan OpenStreetMap; keamanan jalur dan status tujuan belum diverifikasi.';

class RouteSimulationResult {
  const RouteSimulationResult({
    required this.coordinates,
    required this.distanceMeters,
    required this.distanceKm,
    required this.durationSeconds,
    required this.source,
    required this.attribution,
    required this.attributionUrl,
    required this.method,
    required this.warning,
    required this.destinationId,
    required this.destinationName,
    required this.destinationStatus,
  });

  final List<LatLng> coordinates;
  final double distanceMeters;
  final double distanceKm;
  final double? durationSeconds;
  final String source;
  final String attribution;
  final String attributionUrl;
  final String method;
  final String warning;
  final String destinationId;
  final String? destinationName;
  final String destinationStatus;

  factory RouteSimulationResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    if (json['success'] != true || data is! Map) {
      throw const FormatException('Respons rute simulasi tidak valid.');
    }
    final route = Map<String, dynamic>.from(data);
    final geometry = route['geometri'];
    final destination = route['tujuan'];
    final rawCoordinates = geometry is Map ? geometry['coordinates'] : null;
    if (geometry is! Map ||
        geometry['type'] != 'LineString' ||
        rawCoordinates is! List ||
        rawCoordinates.length < 2 ||
        destination is! Map) {
      throw const FormatException('Geometri atau tujuan rute tidak valid.');
    }

    final points = rawCoordinates.map(_parsePosition).toList(growable: false);
    final meters = _number(route['jarak_meter']);
    final kilometers = _number(route['jarak_km']);
    final duration = _number(route['durasi_detik']);
    final destinationMap = Map<String, dynamic>.from(destination);
    final destinationId = _text(destinationMap['id']);
    final destinationStatus = _text(destinationMap['status_verifikasi']);
    final source = _text(route['sumber_jaringan']);
    final attribution = _text(route['atribusi']);
    final attributionUrl = _httpsUrl(route['url_atribusi']);
    final method = _text(route['metode']);
    final warning = _text(route['peringatan']);
    final metadataValid =
        meters != null &&
        meters > 0 &&
        kilometers != null &&
        kilometers > 0 &&
        (duration == null || duration >= 0) &&
        destinationId.isNotEmpty &&
        destinationStatus.isNotEmpty &&
        source.isNotEmpty &&
        attribution.isNotEmpty &&
        attributionUrl != null &&
        method.isNotEmpty &&
        warning == routeSimulationDisclaimer;
    if (!metadataValid) {
      throw FormatException(
        'Metadata rute simulasi tidak lengkap: '
        'meters=${meters != null && meters > 0}, '
        'kilometers=${kilometers != null && kilometers > 0}, '
        'destination=${destinationId.isNotEmpty && destinationStatus.isNotEmpty}, '
        'source=${source.isNotEmpty}, attribution=${attribution.isNotEmpty && attributionUrl != null}, '
        'method=${method.isNotEmpty}, warning=${warning == routeSimulationDisclaimer}.',
      );
    }

    return RouteSimulationResult(
      coordinates: List.unmodifiable(points),
      distanceMeters: meters,
      distanceKm: kilometers,
      durationSeconds: duration,
      source: source,
      attribution: attribution,
      attributionUrl: attributionUrl,
      method: method,
      warning: warning,
      destinationId: destinationId,
      destinationName: _nullableText(destinationMap['nama']),
      destinationStatus: destinationStatus,
    );
  }
}

class RouteSimulationRepository {
  RouteSimulationRepository({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  Future<RouteSimulationResult> calculate({
    required double latitude,
    required double longitude,
    required String destinationId,
  }) async {
    final response = await _client.postJson(
      'peta/rute-simulasi',
      body: {
        'latitude': latitude,
        'longitude': longitude,
        'destination_id': destinationId,
      },
      timeoutOverride: const Duration(seconds: 22),
    );
    return RouteSimulationResult.fromJson(response);
  }

  void close() => _client.close();
}

LatLng _parsePosition(dynamic value) {
  if (value is! List || value.length < 2) {
    throw const FormatException('Posisi LineString tidak valid.');
  }
  final longitude = _number(value[0]);
  final latitude = _number(value[1]);
  if (longitude == null ||
      latitude == null ||
      longitude < -180 ||
      longitude > 180 ||
      latitude < -90 ||
      latitude > 90) {
    throw const FormatException('Posisi LineString di luar rentang.');
  }
  return LatLng(latitude, longitude);
}

double? _number(dynamic value) {
  if (value is num && value.isFinite) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : null;
}

String _text(dynamic value) => value?.toString().trim() ?? '';

String? _nullableText(dynamic value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

String? _httpsUrl(dynamic value) {
  final uri = Uri.tryParse(_text(value));
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return uri.toString();
}

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class DeviceLocationFix {
  const DeviceLocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.measuredAt,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime measuredAt;
  LatLng get point => LatLng(latitude, longitude);

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      accuracyMeters.isFinite &&
      accuracyMeters >= 0;
}

abstract interface class MobileLocationProvider {
  Future<DeviceLocationFix> currentFix();
}

class GeolocatorLocationProvider implements MobileLocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<DeviceLocationFix> currentFix() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const MobileLocationException(
        'Layanan lokasi perangkat sedang nonaktif.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const MobileLocationException('Izin lokasi ditolak.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const MobileLocationException(
        'Izin lokasi ditolak permanen. Aktifkan dari pengaturan aplikasi.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 22),
      ),
    );
    final fix = DeviceLocationFix(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
      measuredAt: position.timestamp,
    );
    if (!fix.isValid) {
      throw const MobileLocationException('Koordinat perangkat tidak valid.');
    }
    return fix;
  }
}

class MobileLocationException implements Exception {
  const MobileLocationException(this.message);
  final String message;
  @override
  String toString() => message;
}

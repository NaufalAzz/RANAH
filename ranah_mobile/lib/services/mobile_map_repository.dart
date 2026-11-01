import 'package:latlong2/latlong.dart';

import '../models/mobile_map_data.dart';
import 'api_service.dart';
import 'mobile_map_api.dart';

abstract interface class MobileMapRepository {
  Future<MapOsmDataset> loadOsm();
  Future<MapAddress> lookupAddress(DeviceCoordinates location);
  Future<MapHazardResult> analyze(DeviceCoordinates location);
  Future<WalkingRoute> route(
    DeviceCoordinates location,
    MapOsmFeature destination,
  );
  void close();
}

class DeviceCoordinates {
  const DeviceCoordinates({required this.latitude, required this.longitude});
  final double latitude;
  final double longitude;
  LatLng get point => LatLng(latitude, longitude);
}

class LaravelMobileMapRepository implements MobileMapRepository {
  LaravelMobileMapRepository({MobileMapApi? api}) : _api = api ?? ApiService();
  final MobileMapApi _api;

  @override
  Future<MapOsmDataset> loadOsm() async =>
      MapOsmDataset.fromEnvelope(await _api.getOsmAssemblyPoints());

  @override
  Future<MapAddress> lookupAddress(DeviceCoordinates location) async =>
      MapAddress.fromEnvelope(
        await _api.reverseGeocode(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );

  @override
  Future<MapHazardResult> analyze(DeviceCoordinates location) async =>
      MapHazardResult.fromEnvelope(
        await _api.analyzeHazards(
          latitude: location.latitude,
          longitude: location.longitude,
        ),
      );

  @override
  Future<WalkingRoute> route(
    DeviceCoordinates location,
    MapOsmFeature destination,
  ) async {
    if (destination.geometryType != 'Point' || destination.point == null) {
      throw const FormatException(
        'Area tanpa titik akses tidak dapat dirutekan.',
      );
    }
    return WalkingRoute.fromEnvelope(
      await _api.calculateWalkingRoute(
        latitude: location.latitude,
        longitude: location.longitude,
        destinationId: destination.id,
      ),
    );
  }

  @override
  void close() {}
}

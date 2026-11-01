abstract interface class MobileMapApi {
  Future<Map<String, dynamic>> getOsmAssemblyPoints();
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  });
  Future<Map<String, dynamic>> analyzeHazards({
    required double latitude,
    required double longitude,
  });
  Future<Map<String, dynamic>> calculateWalkingRoute({
    required double latitude,
    required double longitude,
    required String destinationId,
  });
}

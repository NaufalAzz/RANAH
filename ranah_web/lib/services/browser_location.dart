enum BrowserLocationFailure {
  unsupported,
  permissionDenied,
  unavailable,
  timeout,
}

class BrowserLocationException implements Exception {
  const BrowserLocationException(this.failure);

  final BrowserLocationFailure failure;
}

class BrowserLocation {
  const BrowserLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.measuredAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? measuredAt;

  bool get isValid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      (accuracyMeters == null ||
          (accuracyMeters!.isFinite && accuracyMeters! >= 0));
}

class BrowserAdministrativeArea {
  const BrowserAdministrativeArea({
    this.province,
    this.regency,
    this.locality,
    this.street,
    this.village,
    this.district,
    this.displayName,
    this.source,
    this.retrievedAt,
  });

  final String? province;
  final String? regency;
  final String? locality;
  final String? street;
  final String? village;
  final String? district;
  final String? displayName;
  final String? source;
  final DateTime? retrievedAt;
}

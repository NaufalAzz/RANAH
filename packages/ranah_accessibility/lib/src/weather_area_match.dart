/// Matches a reverse-geocoded location to a configured BMKG ADM4 area.
/// A village and municipality must agree; ambiguous matches are rejected.
bool matchesWeatherArea({
  required String areaVillage,
  required String areaDistrict,
  required String areaCity,
  required String areaProvince,
  required String? locationVillage,
  required String? locationDistrict,
  required String? locationCity,
  required String? locationProvince,
}) {
  String key(String? value) => (value ?? '')
      .toLowerCase()
      .replaceFirst(
        RegExp(r'^(?:kelurahan|desa|kecamatan|kabupaten|kota)\s+'),
        '',
      )
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  final village = key(locationVillage);
  final city = key(locationCity);
  final province = key(locationProvince);
  if (village.isEmpty || city.isEmpty || province.isEmpty) return false;
  if (key(areaVillage) != village ||
      key(areaCity) != city ||
      key(areaProvince) != province) {
    return false;
  }
  final district = key(locationDistrict);
  return district.isEmpty || key(areaDistrict) == district;
}

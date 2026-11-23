import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  test('matches verified village, city and province without guessing', () {
    bool matches(String? village, String? city) => matchesWeatherArea(
      areaVillage: 'Pasar Ambacang',
      areaDistrict: 'Kuranji',
      areaCity: 'Kota Padang',
      areaProvince: 'Sumatera Barat',
      locationVillage: village,
      locationDistrict: 'Kecamatan Kuranji',
      locationCity: city,
      locationProvince: 'Sumatera Barat',
    );
    expect(matches('Kelurahan Pasar Ambacang', 'Padang'), isTrue);
    expect(matches(null, 'Padang'), isFalse);
    expect(matches('Pasar Ambacang', 'Bukittinggi'), isFalse);
  });
}

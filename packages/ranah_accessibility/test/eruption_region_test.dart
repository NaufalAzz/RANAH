import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_accessibility/ranah_accessibility.dart';

void main() {
  test('Padang prioritizes West Sumatra and excludes other islands', () {
    final news = [
      'Gunung Semeru',
      'Gunung Sinabung',
      'Gunung Marapi',
      'Gunung Kerinci',
    ];
    expect(localEruptionNews(news, (e) => e, 'Sumatera Barat'), [
      'Gunung Marapi',
      'Gunung Sinabung',
      'Gunung Kerinci',
    ]);
    expect(localEruptionNews(news, (e) => e, null), news);
    expect(eruptionVolcano('Laporan erupsi Gunung Merapi'), 'Merapi');
    expect(eruptionVolcano('Laporan erupsi Gunung Marapi'), 'Marapi');
    expect(
      eruptionVolcano('Laporan erupsi Gunung Sorik Marapi'),
      'Sorik Marapi',
    );
  });
}

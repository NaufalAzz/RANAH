import 'package:flutter_test/flutter_test.dart';
import 'package:ranah_mobile/services/internet_status_monitor.dart';

void main() {
  test('online indicator follows the independent connectivity probe', () async {
    var online = true;
    final monitor = InternetStatusMonitor(
      probe: () async => online,
      interval: const Duration(days: 1),
    );
    addTearDown(monitor.dispose);

    await monitor.checkNow();
    expect(monitor.isOnline.value, isTrue);

    online = false;
    await monitor.checkNow();
    expect(monitor.isOnline.value, isFalse);
  });
}

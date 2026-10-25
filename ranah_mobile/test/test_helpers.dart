import 'package:ranah_mobile/services/internet_status_monitor.dart';

InternetStatusMonitor createTestInternetStatusMonitor() =>
    InternetStatusMonitor(
      probe: () async => false,
      interval: const Duration(days: 1),
    );

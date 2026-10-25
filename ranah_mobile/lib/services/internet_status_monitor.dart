import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef InternetStatusProbe = Future<bool> Function();

class InternetStatusMonitor {
  InternetStatusMonitor({
    InternetStatusProbe? probe,
    this.interval = const Duration(seconds: 30),
  }) : _probe = probe ?? _probeInternet;

  final InternetStatusProbe _probe;
  final Duration interval;
  final ValueNotifier<bool> isOnline = ValueNotifier(false);
  Timer? _timer;
  bool _checking = false;

  void start() {
    if (_timer != null) return;
    unawaited(checkNow());
    _timer = Timer.periodic(interval, (_) => unawaited(checkNow()));
  }

  Future<void> checkNow() async {
    if (_checking) return;
    _checking = true;
    try {
      isOnline.value = await _probe();
    } catch (_) {
      isOnline.value = false;
    } finally {
      _checking = false;
    }
  }

  void dispose() {
    _timer?.cancel();
    isOnline.dispose();
  }

  static Future<bool> _probeInternet() async {
    final response = await http
        .get(Uri.https('www.google.com', '/generate_204'))
        .timeout(const Duration(seconds: 4));
    return response.statusCode == 204;
  }
}

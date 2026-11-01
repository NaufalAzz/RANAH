// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;

import 'browser_location.dart';

Future<BrowserLocation> readBrowserLocation() async {
  try {
    final position = await html.window.navigator.geolocation.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 20),
      maximumAge: Duration.zero,
    );
    final coordinates = position.coords;
    final latitude = coordinates?.latitude?.toDouble();
    final longitude = coordinates?.longitude?.toDouble();
    final accuracy = coordinates?.accuracy?.toDouble();
    if (latitude == null || longitude == null) {
      throw const BrowserLocationException(BrowserLocationFailure.unavailable);
    }
    final location = BrowserLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracy,
      measuredAt: position.timestamp == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              position.timestamp!,
              isUtc: true,
            ),
    );
    if (!location.isValid) {
      throw const BrowserLocationException(BrowserLocationFailure.unavailable);
    }
    return location;
  } on html.PositionError catch (error) {
    throw BrowserLocationException(switch (error.code) {
      html.PositionError.PERMISSION_DENIED =>
        BrowserLocationFailure.permissionDenied,
      html.PositionError.TIMEOUT => BrowserLocationFailure.timeout,
      _ => BrowserLocationFailure.unavailable,
    });
  } on TimeoutException {
    throw const BrowserLocationException(BrowserLocationFailure.timeout);
  } on BrowserLocationException {
    rethrow;
  } catch (_) {
    throw const BrowserLocationException(BrowserLocationFailure.unsupported);
  }
}

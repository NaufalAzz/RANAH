import 'browser_location.dart';
import 'browser_geolocation_stub.dart'
    if (dart.library.html) 'browser_geolocation_web.dart' as platform;

export 'browser_location.dart';

Future<BrowserLocation> readBrowserLocation() =>
    platform.readBrowserLocation();

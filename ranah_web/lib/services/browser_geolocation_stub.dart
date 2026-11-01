import 'browser_location.dart';

Future<BrowserLocation> readBrowserLocation() =>
    Future.error(
      const BrowserLocationException(BrowserLocationFailure.unsupported),
    );

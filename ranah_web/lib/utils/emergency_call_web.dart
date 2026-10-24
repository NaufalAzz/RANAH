import 'dart:js_interop';

@JS('window.location.assign')
external void _navigateTo(JSString url);

void callEmergencyNumber(String number) {
  _navigateTo('tel:$number'.toJS);
}

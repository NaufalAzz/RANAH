import 'emergency_call_stub.dart'
    if (dart.library.html) 'emergency_call_web.dart'
    as platform;

void callEmergencyNumber(String number) => platform.callEmergencyNumber(number);

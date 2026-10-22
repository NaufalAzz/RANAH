import 'package:flutter/services.dart';

class PhoneDialer {
  static const _channel = MethodChannel('ranah/phone_dialer');

  Future<void> openDialer(String number) async {
    if (!RegExp(r'^\d{3,5}$').hasMatch(number)) {
      throw ArgumentError.value(number, 'number', 'Nomor tidak valid.');
    }
    await _channel.invokeMethod<void>('openDialer', {'number': number});
  }
}

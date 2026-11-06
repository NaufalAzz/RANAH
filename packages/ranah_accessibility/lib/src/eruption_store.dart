import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores only a voluntarily selected volcano, public source snapshot, checklist,
/// and training results. No GPS history, health profile, or emergency dispatch.
class EruptionStore {
  static const key = 'ranah.eruption.preparedness.v1';
  Future<Map<String, dynamic>> read() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final value = jsonDecode(prefs.getString(key) ?? '{}');
      return value is Map ? Map<String, dynamic>.from(value) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, dynamic> state) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, jsonEncode(state))) {
      throw StateError('Penyimpanan lokal gagal.');
    }
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://192.168.1.15:8000/api';

  /// Mengambil daftar gunung dari Laravel.
  Future<List<dynamic>> getGunung() async {
    final response = await http.get(
      Uri.parse('$baseUrl/gunung'),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengambil data gunung: ${response.statusCode}',
      );
    }

    final hasil = jsonDecode(response.body);

    if (hasil is! Map<String, dynamic> ||
        hasil['success'] != true) {
      throw Exception('Respons API daftar gunung tidak valid.');
    }

    final data = hasil['data'];

    if (data is! List) {
      throw Exception('Format daftar gunung tidak sesuai.');
    }

    return data;
  }

  /// Mengambil detail gunung dan laporan pengamatannya.
  Future<Map<String, dynamic>> getDetailGunung(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/gunung/$id'),
    );

    dynamic hasil;

    try {
      hasil = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Respons API detail gunung tidak valid.');
    }

    if (response.statusCode != 200) {
      final pesan = hasil is Map<String, dynamic>
          ? hasil['message']?.toString()
          : null;

      throw Exception(
        pesan ?? 'Gagal mengambil detail gunung: ${response.statusCode}',
      );
    }

    if (hasil is! Map<String, dynamic> ||
        hasil['success'] != true) {
      throw Exception('Respons API detail gunung tidak valid.');
    }

    final data = hasil['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Format detail gunung tidak sesuai.');
    }

    return data;
  }
}

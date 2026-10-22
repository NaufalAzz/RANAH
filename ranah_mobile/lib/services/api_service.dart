import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'http://192.168.202.88:8000/api';

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

    if (hasil['success'] != true) {
      throw Exception(
        'API gagal mengembalikan data gunung.',
      );
    }

    return hasil['data'] as List<dynamic>;
  }
}

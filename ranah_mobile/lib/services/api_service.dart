import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'gunung_api.dart';
import 'news_api.dart';

class ApiService implements GunungApi, NewsApi {
  static const String baseUrl = String.fromEnvironment('RANAH_API_BASE_URL');
  static const Duration requestTimeout = Duration(seconds: 15);

  Uri _endpoint(String path) {
    final configuredUrl = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final parsed = Uri.tryParse(configuredUrl);
    if (parsed == null ||
        !parsed.hasScheme ||
        parsed.host.isEmpty ||
        (parsed.scheme != 'http' && parsed.scheme != 'https')) {
      throw Exception(
        'Base URL API belum valid. Atur RANAH_API_BASE_URL saat menjalankan aplikasi.',
      );
    }
    return Uri.parse('$configuredUrl/$path');
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await http.get(uri).timeout(requestTimeout);
    } on TimeoutException {
      throw Exception('Permintaan API melewati batas waktu.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server API.');
    } on http.ClientException {
      throw Exception('Terjadi masalah jaringan saat menghubungi API.');
    }
  }

  /// Mengambil daftar gunung dari Laravel.
  @override
  Future<List<dynamic>> getGunung() async {
    final response = await _get(_endpoint('gunung'));

    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil data gunung: ${response.statusCode}');
    }

    dynamic hasil;
    try {
      hasil = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Respons API daftar gunung tidak valid.');
    }

    if (hasil is! Map<String, dynamic> || hasil['success'] != true) {
      throw Exception('Respons API daftar gunung tidak valid.');
    }

    final data = hasil['data'];

    if (data is! List) {
      throw Exception('Format daftar gunung tidak sesuai.');
    }

    return data;
  }

  /// Mengambil detail gunung dan laporan pengamatannya.
  @override
  Future<Map<String, dynamic>> getDetailGunung(int id) async {
    final response = await _get(_endpoint('gunung/$id'));

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

    if (hasil is! Map<String, dynamic> || hasil['success'] != true) {
      throw Exception('Respons API detail gunung tidak valid.');
    }

    final data = hasil['data'];

    if (data is! Map<String, dynamic>) {
      throw Exception('Format detail gunung tidak sesuai.');
    }

    return data;
  }

  @override
  Future<List<dynamic>> getBerita() async {
    final response = await _get(_endpoint('berita'));
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil daftar berita: ${response.statusCode}');
    }

    dynamic result;
    try {
      result = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Respons API daftar berita tidak valid.');
    }

    if (result is! Map<String, dynamic> || result['success'] != true) {
      throw Exception('Respons API daftar berita tidak valid.');
    }
    final data = result['data'];
    if (data is! List) {
      throw Exception('Format daftar berita tidak sesuai.');
    }
    return data;
  }
}

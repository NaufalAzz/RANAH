import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'complaint_api.dart';
import 'gunung_api.dart';
import 'news_api.dart';

class ApiService implements GunungApi, NewsApi, ComplaintApi {
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

  Future<http.Response> _postComplaint(
    Uri uri,
    Map<String, String> fields,
    List<XFile> attachments,
  ) async {
    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..fields.addAll(fields);
      for (final file in attachments) {
        request.files.add(
          await http.MultipartFile.fromPath('media[]', file.path),
        );
      }
      final streamedResponse = await request.send().timeout(requestTimeout);
      return await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw const ComplaintApiException(
        'Pengiriman melewati batas waktu. Periksa status laporan sebelum mengirim ulang.',
      );
    } on SocketException {
      throw const ComplaintApiException(
        'Server tidak dapat dijangkau. Data tetap di formulir; coba lagi.',
      );
    } on http.ClientException {
      throw const ComplaintApiException(
        'Terjadi masalah jaringan. Data tetap di formulir; coba lagi.',
      );
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

  @override
  Future<ComplaintSubmissionReceipt> submitComplaint({
    required String reporterName,
    required String phoneNumber,
    required String category,
    required String location,
    required String description,
    required bool consented,
    List<XFile> attachments = const [],
  }) async {
    final response = await _postComplaint(_endpoint('pengaduan'), {
      'nama_pelapor': reporterName,
      'nomor_telepon': phoneNumber,
      'kategori': category,
      'lokasi_kejadian': location,
      'deskripsi': description,
      'persetujuan': consented.toString(),
    }, attachments);

    if (response.statusCode == 422) {
      throw const ComplaintApiException(
        'Data pengaduan ditolak server. Periksa kembali isian.',
      );
    }
    if (response.statusCode == 429) {
      throw const ComplaintApiException(
        'Pengiriman terlalu sering. Tunggu sebentar lalu coba lagi.',
      );
    }
    if (response.statusCode != 201) {
      throw const ComplaintApiException(
        'Pengaduan gagal dikirim. Data tetap di formulir; coba lagi.',
      );
    }

    dynamic result;
    try {
      result = jsonDecode(response.body);
    } on FormatException {
      throw const ComplaintApiException(
        'Respons server tidak valid. Pastikan status pengaduan sebelum mencoba ulang.',
      );
    }

    final data = result is Map<String, dynamic> ? result['data'] : null;
    final idValue = data is Map ? data['id'] : null;
    final id = idValue is int
        ? idValue
        : int.tryParse(idValue?.toString() ?? '');
    final receivedAt = data is Map
        ? DateTime.tryParse(data['waktu_pengaduan']?.toString() ?? '')
        : null;
    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        id == null ||
        receivedAt == null) {
      throw const ComplaintApiException(
        'Respons server tidak valid. Pastikan status pengaduan sebelum mencoba ulang.',
      );
    }

    return ComplaintSubmissionReceipt(id: id, receivedAt: receivedAt);
  }
}

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'complaint_api.dart';
import 'gunung_api.dart';
import 'news_api.dart';
import 'notification_api.dart';
import 'mobile_map_api.dart';

class ApiService
    implements
        GunungApi,
        NewsApi,
        NotificationApi,
        WeatherForecastApi,
        ComplaintApi,
        MobileMapApi {
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

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _get(_endpoint(path));
    return _decodeMapResponse(response, 'Permintaan API gagal');
  }

  Future<Map<String, dynamic>> _postMap(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            _endpoint(path),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(requestTimeout + const Duration(seconds: 20));
      return _decodeMapResponse(response, 'Permintaan API gagal');
    } on TimeoutException {
      throw Exception('Permintaan API melewati batas waktu.');
    } on SocketException {
      throw Exception('Tidak dapat terhubung ke server API.');
    } on http.ClientException {
      throw Exception('Terjadi masalah jaringan saat menghubungi API.');
    }
  }

  Map<String, dynamic> _decodeMapResponse(
    http.Response response,
    String fallback,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Respons API bukan JSON yang valid.');
    }
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Format respons API tidak sesuai.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message']?.toString().trim();
      if (response.statusCode == 429) {
        throw Exception(
          'Permintaan terlalu sering. Tunggu sebentar lalu coba lagi.',
        );
      }
      throw Exception(
        message == null || message.isEmpty
            ? '$fallback (${response.statusCode}).'
            : message,
      );
    }
    return decoded;
  }

  @override
  Future<Map<String, dynamic>> getOsmAssemblyPoints() =>
      _getMap('peta/titik-kumpul-osm');

  @override
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) => _getMap(
    Uri(
      path: 'peta/alamat',
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      },
    ).toString(),
  );

  @override
  Future<Map<String, dynamic>> analyzeHazards({
    required double latitude,
    required double longitude,
  }) => _postMap('peta/analisis-bahaya', {
    'latitude': latitude,
    'longitude': longitude,
  });

  @override
  Future<Map<String, dynamic>> calculateWalkingRoute({
    required double latitude,
    required double longitude,
    required String destinationId,
  }) => _postMap('peta/rute-simulasi', {
    'latitude': latitude,
    'longitude': longitude,
    'destination_id': destinationId,
  });

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
  Future<NotificationApiFeed> getNotifications() async {
    final response = await _get(_endpoint('notifikasi?per_page=100'));
    if (response.statusCode != 200) {
      throw Exception('Gagal mengambil notifikasi: ${response.statusCode}');
    }
    dynamic result;
    try {
      result = jsonDecode(response.body);
    } on FormatException {
      throw Exception('Respons API notifikasi tidak valid.');
    }
    if (result is! Map<String, dynamic> ||
        result['success'] != true ||
        result['data'] is! List) {
      throw Exception('Format API notifikasi tidak sesuai.');
    }
    final meta = result['meta'];
    final sourceUpdatedAt = meta is Map<String, dynamic>
        ? DateTime.tryParse(
            meta['waktu_pembaruan_terakhir_bmkg']?.toString() ?? '',
          )
        : null;
    return NotificationApiFeed(
      items: result['data'] as List<dynamic>,
      sourceUpdatedAt: sourceUpdatedAt,
    );
  }

  @override
  Future<List<dynamic>> getWeatherAreas() async {
    final result = await _getMap('prakiraan-cuaca/wilayah');
    if (result['success'] != true || result['data'] is! List) {
      throw Exception('Daftar wilayah prakiraan BMKG tidak sesuai.');
    }
    return result['data'] as List<dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getWeatherForecast(String adm4) =>
      _getMap('prakiraan-cuaca/$adm4');

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

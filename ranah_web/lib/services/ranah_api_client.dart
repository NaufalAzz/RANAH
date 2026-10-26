import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const ranahApiBaseUrl = String.fromEnvironment('RANAH_API_BASE_URL');

class RanahApiException implements Exception {
  const RanahApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Small shared HTTP layer for the public Laravel API.
class RanahApiClient {
  RanahApiClient({
    http.Client? client,
    String? baseUrl,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ranahApiBaseUrl).trim();

  final http.Client _client;
  final String _baseUrl;
  final Duration timeout;

  Uri _endpoint(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.tryParse(_baseUrl);
    if (base == null ||
        !base.hasScheme ||
        base.host.isEmpty ||
        (base.scheme != 'http' && base.scheme != 'https') ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const RanahApiException(
        'Base URL API belum valid. Atur RANAH_API_BASE_URL.',
      );
    }
    final basePath = base.path.replaceFirst(RegExp(r'/+$'), '');
    final endpointPath = path.replaceFirst(RegExp(r'^/+'), '');
    return base.replace(
      path: '$basePath/$endpointPath',
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _endpoint(path, queryParameters);
    late final http.Response response;
    try {
      response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);
    } on TimeoutException {
      throw const RanahApiException('Permintaan API melewati batas waktu.');
    } on http.ClientException {
      throw const RanahApiException(
        'Tidak dapat terhubung ke server API. Periksa jaringan dan alamat API.',
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw RanahApiException(
          'Server API merespons HTTP ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }
      throw const RanahApiException('Respons JSON dari API tidak valid.');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['message']?.toString()
          : null;
      throw RanahApiException(
        message == null || message.isEmpty
            ? 'Server API merespons HTTP ${response.statusCode}.'
            : message,
        statusCode: response.statusCode,
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const RanahApiException('Format respons API tidak sesuai.');
    }
    return decoded;
  }

  void close() => _client.close();
}

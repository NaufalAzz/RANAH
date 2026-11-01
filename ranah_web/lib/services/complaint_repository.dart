import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'ranah_api_client.dart';

class ComplaintAttachment {
  const ComplaintAttachment({
    required this.name,
    required this.bytes,
    required this.contentType,
  });

  final String name;
  final Uint8List bytes;
  final String contentType;
}

class ComplaintReceipt {
  const ComplaintReceipt({required this.id, required this.receivedAt});

  final int id;
  final DateTime receivedAt;
}

class ComplaintSubmissionException implements Exception {
  const ComplaintSubmissionException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  @override
  String toString() => message;
}

class ComplaintRepository {
  ComplaintRepository({RanahApiClient? client})
    : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  Future<ComplaintReceipt> submit({
    required String reporterName,
    required String phoneNumber,
    required String category,
    required String location,
    required String description,
    required bool consented,
    List<ComplaintAttachment> attachments = const [],
  }) async {
    if (attachments.length > 3) {
      throw const ComplaintSubmissionException('Pilih maksimal tiga foto.');
    }
    for (final attachment in attachments) {
      if (attachment.bytes.isEmpty || attachment.bytes.length > 5 * 1024 * 1024) {
        throw const ComplaintSubmissionException(
          'Foto harus berukuran lebih dari 0 dan maksimal 5 MB.',
        );
      }
      if (!_isAllowedImageType(attachment.contentType)) {
        throw const ComplaintSubmissionException(
          'Lampiran hanya boleh berupa JPG, PNG, atau WebP.',
        );
      }
    }

    late final http.Response response;
    try {
      response = await _client.postMultipart(
        'pengaduan',
        fields: {
          'nama_pelapor': reporterName,
          'nomor_telepon': phoneNumber,
          'kategori': category,
          'lokasi_kejadian': location,
          'deskripsi': description,
          'persetujuan': consented.toString(),
        },
        files: [
          for (final attachment in attachments)
            http.MultipartFile.fromBytes(
              'media[]',
              attachment.bytes,
              filename: attachment.name,
              contentType: _mediaType(attachment.contentType),
            ),
        ],
      );
    } on RanahApiException catch (error) {
      throw ComplaintSubmissionException(
        error.message,
        statusCode: error.statusCode,
      );
    }

    final body = _decode(response.body);
    if (response.statusCode == 422) {
      final errors = <String, String>{};
      final rawErrors = body?['errors'];
      if (rawErrors is Map) {
        for (final entry in rawErrors.entries) {
          final messages = entry.value;
          if (messages is List && messages.isNotEmpty) {
            errors[entry.key.toString()] = messages.first.toString();
          }
        }
      }
      throw ComplaintSubmissionException(
        'Data pengaduan ditolak. Periksa kembali isian dan lampiran.',
        statusCode: 422,
        fieldErrors: errors,
      );
    }
    if (response.statusCode == 429) {
      throw const ComplaintSubmissionException(
        'Pengiriman terlalu sering. Tunggu sebentar sebelum mencoba lagi.',
        statusCode: 429,
      );
    }
    if (response.statusCode != 201) {
      throw ComplaintSubmissionException(
        'Server merespons HTTP ${response.statusCode}, tetapi belum mengonfirmasi penyimpanan. Periksa status sebelum mengirim ulang.',
        statusCode: response.statusCode,
      );
    }

    final data = body?['data'];
    final idRaw = data is Map ? data['id'] : null;
    final id = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
    final receivedAt = data is Map
        ? DateTime.tryParse(data['waktu_pengaduan']?.toString() ?? '')
        : null;
    if (body?['success'] != true || id == null || receivedAt == null) {
      throw const ComplaintSubmissionException(
        'Respons server tidak dapat dikonfirmasi. Periksa status pengaduan sebelum mengirim ulang.',
        statusCode: 201,
      );
    }
    return ComplaintReceipt(id: id, receivedAt: receivedAt);
  }

  void close() => _client.close();

  Map<String, dynamic>? _decode(String text) {
    try {
      final value = jsonDecode(text);
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  MediaType? _mediaType(String value) {
    final parts = value.split('/');
    if (parts.length != 2 || parts.any((part) => part.trim().isEmpty)) {
      return null;
    }
    return MediaType(parts[0].trim(), parts[1].trim());
  }

  bool _isAllowedImageType(String value) =>
      const {'image/jpeg', 'image/png', 'image/webp'}.contains(value.toLowerCase());
}

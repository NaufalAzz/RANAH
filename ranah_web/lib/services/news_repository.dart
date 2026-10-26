import '../data/home_stories.dart';
import 'ranah_api_client.dart';

class NewsRepository {
  NewsRepository({RanahApiClient? client}) : _client = client ?? RanahApiClient();

  final RanahApiClient _client;

  Future<List<HomeStory>> load() async {
    final response = await _client.getJson('berita');
    if (response['success'] != true || response['data'] is! List) {
      throw const RanahApiException('Format daftar berita dari API tidak sesuai.');
    }

    // Laravel orders by publication time. Keep the first record for an ID if
    // a malformed upstream result contains duplicates.
    final byId = <String, HomeStory>{};
    for (final raw in response['data'] as List) {
      if (raw is! Map) {
        throw const FormatException('Item berita dari API bukan objek JSON.');
      }
      final story = _mapStory(Map<String, dynamic>.from(raw));
      final deduplicationKey = story.sourceId == null
          ? 'id:${story.id}'
          : 'source:${story.sourceId}';
      byId.putIfAbsent(deduplicationKey, () => story);
    }
    final stories = byId.values.toList()
      ..sort((a, b) => (b.publishedAt ?? DateTime(0))
          .compareTo(a.publishedAt ?? DateTime(0)));
    return List.unmodifiable(stories);
  }

  void close() => _client.close();

  HomeStory _mapStory(Map<String, dynamic> json) {
    final id = _text(json['id']);
    final title = _text(json['judul']);
    final category = _text(json['kategori']);
    final body = _text(json['isi']);
    final publishedAt = DateTime.tryParse(_text(json['waktu_publikasi']) ?? '');
    if (id == null || title == null || category == null || body == null || publishedAt == null) {
      throw const FormatException('Field wajib berita dari API tidak valid.');
    }

    final categoryKey = category.toLowerCase();
    final accent = categoryKey.contains('erupsi') || categoryKey.contains('gunung')
        ? 0xFFE92C2D
        : categoryKey.contains('pengungsian') || categoryKey.contains('bantuan')
            ? 0xFFF39A00
            : 0xFF74839A;
    final summary = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    final source = _text(json['sumber']);
    return HomeStory(
      id: id,
      category: category,
      title: title,
      date: _formatDate(publishedAt),
      image: '',
      color: accent,
      summary: summary.length <= 180 ? summary : '${summary.substring(0, 177)}\u2026',
      content: body,
      source: source,
      imageUrl: _safeUrl(json['gambar'], requireHttps: false),
      sourceUrl: _safeUrl(json['url_sumber'], requireHttps: true),
      region: _text(json['wilayah']),
      sourceId: _text(json['sumber_id']),
      contentType: _text(json['jenis_konten']),
      publishedAt: publishedAt,
      eventAt: DateTime.tryParse(_text(json['waktu_kejadian']) ?? ''),
      expiresAt: DateTime.tryParse(_text(json['waktu_berakhir']) ?? ''),
      retrievedAt: DateTime.tryParse(_text(json['waktu_pengambilan']) ?? ''),
      importance: _text(json['tingkat_kepentingan']),
      publicationStatus: _text(json['status_publikasi']),
      isApiRecord: true,
    );
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String? _safeUrl(dynamic value, {required bool requireHttps}) {
    final uri = Uri.tryParse(_text(value) ?? '');
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty || uri.userInfo.isNotEmpty) return null;
    if (requireHttps ? uri.scheme != 'https' : !{'http', 'https'}.contains(uri.scheme)) return null;
    return uri.toString();
  }

  String _formatDate(DateTime value) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]} ${local.year}';
  }
}

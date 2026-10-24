import 'package:flutter/material.dart';

class NewsFeedNotice extends StatelessWidget {
  const NewsFeedNotice({
    required this.isUsingFallback,
    required this.isLoading,
    this.isFromCache = false,
    this.cacheWriteFailed = false,
    this.lastSyncedAt,
    super.key,
  });

  final bool isUsingFallback;
  final bool isLoading;
  final bool isFromCache;
  final bool cacheWriteFailed;
  final DateTime? lastSyncedAt;

  @override
  Widget build(BuildContext context) {
    if (!isUsingFallback && !isFromCache && !cacheWriteFailed) {
      return const SizedBox.shrink();
    }

    final syncTime = lastSyncedAt;
    final syncLabel = syncTime == null
        ? 'Waktu sinkronisasi tidak tersedia.'
        : 'Sinkronisasi terakhir: '
              '${syncTime.day.toString().padLeft(2, '0')}/'
              '${syncTime.month.toString().padLeft(2, '0')}/'
              '${syncTime.year} '
              '${syncTime.hour.toString().padLeft(2, '0')}:'
              '${syncTime.minute.toString().padLeft(2, '0')}.';

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4D6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLoading
            ? 'Menampilkan konten contoh lokal sambil memuat berita server.'
            : cacheWriteFailed
            ? 'Berita berhasil dimuat dari server, tetapi gagal disimpan '
                  'untuk akses offline.'
            : isFromCache
            ? 'Menampilkan berita server tersimpan secara offline. '
                  '$syncLabel Data mungkin sudah usang.'
            : 'Berita server tidak tersedia. Konten berlabel Contoh adalah '
                  'data demonstrasi, bukan informasi bencana aktual.',
        style: const TextStyle(color: Color(0xFF664A13), fontSize: 13),
      ),
    );
  }
}

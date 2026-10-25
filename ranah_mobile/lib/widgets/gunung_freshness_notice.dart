import 'package:flutter/material.dart';

class GunungFreshnessNotice extends StatelessWidget {
  const GunungFreshnessNotice({
    super.key,
    required this.isFromCache,
    required this.lastCheckedAt,
    this.sourceRetrievedAt,
    this.hasError = false,
    this.apiReturnedEmpty = false,
  });

  final bool isFromCache;
  final DateTime? lastCheckedAt;
  final String? sourceRetrievedAt;
  final bool hasError;
  final bool apiReturnedEmpty;

  @override
  Widget build(BuildContext context) {
    final source = hasError || isFromCache || apiReturnedEmpty
        ? 'Pemeriksaan API belum berhasil diperbarui'
        : 'Pemeriksaan API selesai';
    final checkedAt = lastCheckedAt == null
        ? 'Waktu pemeriksaan perangkat: belum tersedia'
        : 'Waktu pemeriksaan perangkat: ${_formatDate(lastCheckedAt!)}';
    final sourceTime = DateTime.tryParse(sourceRetrievedAt ?? '');
    final fetchedText = sourceTime == null
        ? 'Waktu pengambilan data sumber: belum tersedia'
        : 'Data sumber diambil: ${_formatDate(sourceTime)}${DateTime.now().difference(sourceTime.toLocal()).abs() > const Duration(hours: 24) ? ' · mungkin sudah usang' : ''}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE8163854),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF5883A1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasError ? Icons.cloud_off_outlined : Icons.info_outline_rounded,
            color: const Color(0xFFFFD278),
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$source\n$checkedAt\n$fetchedText',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    final local = value.toLocal();
    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }
}

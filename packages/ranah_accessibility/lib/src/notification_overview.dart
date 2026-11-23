import 'package:flutter/material.dart';

class NotificationOverview extends StatelessWidget {
  const NotificationOverview({
    required this.earthquakes,
    required this.warnings,
    required this.updatedLabel,
    super.key,
  });

  final int earthquakes;
  final int warnings;
  final String updatedLabel;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF174B75), Color(0xFF153753)],
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF5C92AF)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan informasi',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          updatedLabel,
          style: const TextStyle(color: Color(0xFFCFDFEC), fontSize: 12),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            _metric(Icons.vibration_rounded, '$earthquakes', 'Gempa terbaru'),
            _metric(
              Icons.warning_amber_rounded,
              '$warnings',
              'Peringatan aktif',
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Angka pada lonceng menunjukkan jumlah informasi gempa dalam feed, bukan pesan yang belum dibaca.',
          style: TextStyle(color: Color(0xFFCFDFEC), fontSize: 11),
        ),
      ],
    ),
  );

  Widget _metric(IconData icon, String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFF235B81),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFFBCE8F7), size: 20),
        const SizedBox(width: 9),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(color: Color(0xFFE2EFF7), fontSize: 12),
        ),
      ],
    ),
  );
}

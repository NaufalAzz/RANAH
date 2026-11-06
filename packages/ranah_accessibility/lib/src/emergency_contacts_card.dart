import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickEmergencyContact {
  const QuickEmergencyContact({
    required this.name,
    required this.numbers,
    required this.source,
    required this.verified,
    this.icon = Icons.phone_in_talk_rounded,
  });
  final String name;
  final List<String> numbers;
  final String source;
  final bool verified;
  final IconData icon;
}

class EmergencyContactsCard extends StatelessWidget {
  const EmergencyContactsCard({
    required this.contacts,
    this.onOpenAll,
    this.openDialer,
    super.key,
  });
  final List<QuickEmergencyContact> contacts;
  final VoidCallback? onOpenAll;
  final Future<void> Function(String)? openDialer;

  Future<void> _call(
    BuildContext context,
    QuickEmergencyContact contact,
  ) async {
    final number = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hubungi ${contact.name}?'),
        content: SingleChildScrollView(
          child: Text(
            'Aplikasi telepon akan dibuka. Anda menentukan kapan panggilan dimulai.\n\n${contact.source}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          for (final number in contact.numbers)
            if (RegExp(r'^\d{3,5}$').hasMatch(number))
              FilledButton(
                onPressed: () => Navigator.pop(context, number),
                child: Text('Buka Telepon $number'),
              ),
        ],
      ),
    );
    if (number == null || !context.mounted) return;
    try {
      if (openDialer != null) {
        await openDialer!(number);
      } else if (!await launchUrl(Uri(scheme: 'tel', path: number))) {
        throw StateError('Dialer unavailable');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Telepon tidak dapat dibuka. Hubungi ${contact.name} di $number melalui perangkat telepon.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: Theme.of(context).colorScheme.onSurface,
        displayColor: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    child: Builder(builder: _buildCard),
  );

  Widget _buildCard(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(
              Icons.phone_in_talk_rounded,
              color: Color(0xFFFF8E98),
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Kontak Darurat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Akses cepat layanan bantuan',
          style: TextStyle(color: Color(0xFFC5D4E2), fontSize: 14),
        ),
        const SizedBox(height: 14),
        for (final contact in contacts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF552435), Color(0xFF49213A)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFB03C4A)),
                ),
                child: Semantics(
                  label:
                      '${contact.name}, ${contact.numbers.join(' atau ')}. Buka pilihan telepon',
                  button: true,
                  enabled: contact.verified && contact.numbers.isNotEmpty,
                  excludeSemantics: true,
                  child: InkWell(
                    key: ValueKey('home-emergency-${contact.name}'),
                    onTap: contact.verified && contact.numbers.isNotEmpty
                        ? () => _call(context, contact)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9363D),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              contact.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contact.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  contact.verified
                                      ? 'Layanan bantuan'
                                      : 'Nomor belum terverifikasi',
                                  style: const TextStyle(
                                    color: Color(0xFFE3C4CC),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            fit: FlexFit.tight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  contact.numbers.join(' / '),
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    color: Color(0xFFFFABB2),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Telepon',
                                  style: TextStyle(
                                    color: Color(0xFFFFD0D5),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const Text(
          'Ketersediaan layanan bergantung wilayah dan jaringan telepon.',
          style: TextStyle(color: Color(0xFFC5D4E2), fontSize: 13),
        ),
        if (onOpenAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFABB2),
              ),
              label: const Text('Lihat semua kontak'),
            ),
          ),
      ],
    ),
  );
}

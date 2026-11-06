import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickEmergencyContact {
  const QuickEmergencyContact({
    required this.name,
    required this.numbers,
    required this.source,
    required this.verified,
  });
  final String name;
  final List<String> numbers;
  final String source;
  final bool verified;
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

  Widget _buildCard(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Kontak Darurat', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Nomor layanan umum. Ketersediaan respons bergantung wilayah dan jaringan telepon.',
          ),
          const SizedBox(height: 12),
          for (final contact in contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                onPressed: contact.verified && contact.numbers.isNotEmpty
                    ? () => _call(context, contact)
                    : null,
                icon: const Icon(Icons.phone),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    '${contact.name} · ${contact.numbers.join(' / ')}\nTelepon',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          if (onOpenAll != null)
            TextButton(
              onPressed: onOpenAll,
              child: const Text('Lihat semua kontak'),
            ),
        ],
      ),
    ),
  );
}

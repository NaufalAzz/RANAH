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

  Widget _buildCard(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF451523), Color(0xFF280E1F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: const Color(0xFFB03C4A).withValues(alpha: 0.45),
        width: 1.2,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x3D000000),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFD9363D).withValues(alpha: 0.22),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFF8E98).withValues(alpha: 0.5),
                ),
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: Color(0xFFFF8E98),
                size: 17,
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kontak Darurat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                  Text(
                    'Akses cepat layanan bantuan',
                    style: TextStyle(
                      color: Color(0xFFD1BAC2),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final contact in contacts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5A2033), Color(0xFF45192D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFB03C4A).withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
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
                    borderRadius: BorderRadius.circular(14),
                    splashColor: Colors.white.withValues(alpha: 0.12),
                    highlightColor: Colors.white.withValues(alpha: 0.06),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final compact =
                              box.maxWidth <
                              MediaQuery.textScalerOf(context).scale(360);
                          final label = Row(
                            children: [
                              Icon(
                                contact.icon,
                                color: const Color(0xFFFFB9B4),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.3,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      contact.verified
                                          ? 'Layanan bantuan'
                                          : 'Nomor belum terverifikasi',
                                      style: const TextStyle(
                                        color: Color(0xFFE7C5CD),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                          final number = Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Icon(
                                Icons.call_outlined,
                                size: 16,
                                color: Color(0xFFFFBCC2),
                              ),
                              Text(
                                contact.numbers.join(' / '),
                                style: const TextStyle(
                                  color: Color(0xFFFFE3E6),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          );
                          if (compact)
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                label,
                                const SizedBox(height: 7),
                                Padding(
                                  padding: const EdgeInsets.only(left: 32),
                                  child: number,
                                ),
                              ],
                            );
                          return Row(
                            children: [
                              Expanded(child: label),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: number,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        const Text(
          'Ketersediaan layanan bergantung wilayah dan jaringan telepon.',
          style: TextStyle(color: Color(0xFFC5D4E2), fontSize: 12),
        ),
        if (onOpenAll != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onOpenAll,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFABB2),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              label: const Text(
                'Lihat semua kontak',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
      ],
    ),
  );
}

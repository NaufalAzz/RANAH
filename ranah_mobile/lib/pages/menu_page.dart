import 'package:flutter/material.dart';

import '../pages/contact_complaint_page.dart';
import '../pages/mitigation_page.dart';
import '../theme/app_theme.dart';

enum _MenuSection { home, mitigation, contacts }

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  _MenuSection _section = _MenuSection.home;

  void _openSection(_MenuSection section) {
    setState(() => _section = section);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_section) {
      _MenuSection.home => _MenuHub(onOpen: _openSection),
      _MenuSection.mitigation => MitigationPage(
        onBackToHome: () => _openSection(_MenuSection.home),
      ),
      _MenuSection.contacts => ContactComplaintPage(
        onBack: () => _openSection(_MenuSection.home),
      ),
    };
  }
}

class _MenuHub extends StatelessWidget {
  const _MenuHub({required this.onOpen});

  final ValueChanged<_MenuSection> onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF123858), Color(0xFF0B2D49)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        children: [
          const Text(
            'Layanan RANAH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih panduan atau layanan yang Anda perlukan.',
            style: TextStyle(color: Color(0xFFD0D9E1), fontSize: 13),
          ),
          const SizedBox(height: 18),
          _MenuHubCard(
            icon: Icons.health_and_safety_outlined,
            title: 'Panduan Mitigasi',
            description: 'Langkah sebelum, saat, dan setelah erupsi.',
            onTap: () => onOpen(_MenuSection.mitigation),
          ),
          const SizedBox(height: 12),
          _MenuHubCard(
            icon: Icons.phone_in_talk_rounded,
            title: 'Kontak Darurat & Pengaduan',
            description: 'Daftar kontak dan formulir laporan kejadian.',
            onTap: () => onOpen(_MenuSection.contacts),
          ),
        ],
      ),
    );
  }
}

class _MenuHubCard extends StatelessWidget {
  const _MenuHubCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE6F7),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primary, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

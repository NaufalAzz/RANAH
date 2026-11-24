import 'package:flutter/material.dart';

import '../pages/contact_complaint_page.dart';
import '../pages/mitigation_page.dart';
import '../pages/volcanic_activity_page.dart';
import '../services/complaint_api.dart';
import '../services/complaint_media_picker.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/page_motion.dart';

enum _MenuSection { home, mitigation, contacts, volcanicActivity }

class MenuPage extends StatefulWidget {
  const MenuPage({this.complaintApi, this.mediaPicker, super.key});

  final ComplaintApi? complaintApi;
  final ComplaintMediaPicker? mediaPicker;

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
    final page = switch (_section) {
      _MenuSection.home => _MenuHub(onOpen: _openSection),
      _MenuSection.mitigation => MitigationPage(
        onBackToHome: () => _openSection(_MenuSection.home),
      ),
      _MenuSection.contacts => ContactComplaintPage(
        onBack: () => _openSection(_MenuSection.home),
        complaintApi: widget.complaintApi,
        mediaPicker: widget.mediaPicker,
      ),
      _MenuSection.volcanicActivity => VolcanicActivityPage(
        onBack: () => _openSection(_MenuSection.home),
      ),
    };

    return RanahPageSwitcher(
      rootPageKey: const ValueKey(_MenuSection.home),
      child: KeyedSubtree(key: ValueKey(_section), child: page),
    );
  }
}

class _MenuHub extends StatelessWidget {
  const _MenuHub({required this.onOpen});

  final ValueChanged<_MenuSection> onOpen;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppBackground.decoration,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
        children: [
          Text(
            'Layanan RANAH',
            style: AppTypography.pageTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 5),
          Text(
            'Pilih panduan atau layanan yang Anda perlukan.',
            style: AppTypography.bodyCompact.copyWith(
              color: AppColors.mutedOnDark,
            ),
          ),
          const SizedBox(height: 18),
          _MenuHubCard(
            icon: Icons.landscape_rounded,
            title: 'Aktivitas Gunung Api',
            description:
                'Lihat daftar gunung dan laporan aktivitas yang tersedia.',
            gradient: const LinearGradient(
              colors: [Color(0xFF366476), Color(0xFF243E5E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: const Color(0x2008192C),
            onTap: () => onOpen(_MenuSection.volcanicActivity),
          ),
          const SizedBox(height: 14),
          _MenuHubCard(
            icon: Icons.health_and_safety_rounded,
            title: 'Panduan Mitigasi',
            description: 'Langkah sebelum, saat, dan setelah erupsi.',
            gradient: const LinearGradient(
              colors: [Color(0xFF397677), Color(0xFF245568)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: const Color(0x2008192C),
            onTap: () => onOpen(_MenuSection.mitigation),
          ),
          const SizedBox(height: 14),
          _MenuHubCard(
            icon: Icons.phone_in_talk_rounded,
            title: 'Kontak Darurat & Pengaduan',
            description: 'Daftar kontak dan formulir laporan kejadian.',
            gradient: const LinearGradient(
              colors: [Color(0xFF884659), Color(0xFF623748)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: const Color(0x2008192C),
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
    required this.gradient,
    required this.shadowColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      variant: AppCardVariant.menu,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: shadowColor,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: AppTypography.bodyCompact.copyWith(
                    color: AppColors.muted,
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.primary,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../pages/contact_complaint_page.dart';
import '../pages/mitigation_page.dart';
import '../pages/volcanic_activity_page.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';

enum _MenuSection { home, mitigation, contacts, volcanicActivity }

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
    final page = switch (_section) {
      _MenuSection.home => _MenuHub(onOpen: _openSection),
      _MenuSection.mitigation => MitigationPage(
        onBackToHome: () => _openSection(_MenuSection.home),
      ),
      _MenuSection.contacts => ContactComplaintPage(
        onBack: () => _openSection(_MenuSection.home),
      ),
      _MenuSection.volcanicActivity => VolcanicActivityPage(
        onBack: () => _openSection(_MenuSection.home),
      ),
    };

    return AnimatedSwitcher(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 240),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.025, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
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
            icon: Icons.landscape_outlined,
            title: 'Aktivitas Gunung Api',
            description:
                'Lihat daftar gunung dan laporan aktivitas yang tersedia.',
            onTap: () => onOpen(_MenuSection.volcanicActivity),
          ),
          const SizedBox(height: 12),
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
    return AppCardSurface(
      variant: AppCardVariant.menu,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: AppSizes.minimumTapTarget,
            height: AppSizes.minimumTapTarget,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            child: Icon(icon, color: AppColors.primary, size: 25),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  description,
                  style: AppTypography.bodyCompact.copyWith(
                    color: AppColors.muted,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ],
      ),
    );
  }
}

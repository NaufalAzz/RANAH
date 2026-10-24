import 'package:flutter/material.dart';

import '../data/mitigation_guides.dart';
import '../models/mitigation_guide.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card_surface.dart';
import '../widgets/app_page_banner.dart';

class MitigationPage extends StatefulWidget {
  const MitigationPage({required this.onBackToHome, super.key});

  final VoidCallback onBackToHome;

  @override
  State<MitigationPage> createState() => _MitigationPageState();
}

class _MitigationPageState extends State<MitigationPage> {
  String? _selectedGuideId;

  MitigationGuide? get _selectedGuide {
    for (final guide in mitigationGuides) {
      if (guide.id == _selectedGuideId) return guide;
    }
    return null;
  }

  void _openGuide(MitigationGuide guide) {
    setState(() => _selectedGuideId = guide.id);
  }

  void _closeGuide() {
    setState(() => _selectedGuideId = null);
  }

  @override
  Widget build(BuildContext context) {
    final guide = _selectedGuide;

    return DecoratedBox(
      decoration: AppBackground.decoration,
      child: Stack(
        children: [
          const Positioned(
            right: -130,
            bottom: 18,
            child: _MitigationBackgroundRing(),
          ),
          ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _MitigationBanner(guideTitle: guide?.title),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 22),
                child: _BackButton(
                  onPressed: guide == null ? widget.onBackToHome : _closeGuide,
                ),
              ),
              AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 240),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: guide == null
                    ? _GuideCategoryGrid(
                        key: const ValueKey('mitigation-categories'),
                        onSelect: _openGuide,
                      )
                    : _GuideSteps(
                        key: ValueKey('mitigation-${guide.id}'),
                        guide: guide,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MitigationBanner extends StatelessWidget {
  const _MitigationBanner({this.guideTitle});

  final String? guideTitle;

  @override
  Widget build(BuildContext context) => AppPageBanner(
    icon: Icons.shield_outlined,
    eyebrow: 'PANDUAN MITIGASI',
    title: 'Panduan Mitigasi',
    subtitle: guideTitle ?? 'Jalur Evakuasi & Langkah Keselamatan',
    minHeight: AppSizes.pageBannerMinHeight,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.sm,
    ),
    iconSize: 42,
    iconGap: AppSpacing.lg,
    eyebrowStyle: AppTypography.bannerEyebrow.copyWith(fontSize: 13),
    subtitleStyle: AppTypography.bannerSubtitle.copyWith(fontSize: 13),
  );
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_rounded, size: 17),
        label: const Text('Kembali'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          backgroundColor: Colors.white,
          minimumSize: const Size(0, AppSizes.minimumTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.control),
          ),
          textStyle: AppTypography.label.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _GuideCategoryGrid extends StatelessWidget {
  const _GuideCategoryGrid({required this.onSelect, super.key});

  final ValueChanged<MitigationGuide> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 28,
        mainAxisSpacing: 22,
        childAspectRatio: 1.95,
        children: [
          for (final guide in mitigationGuides)
            _GuideCategoryCard(guide: guide, onTap: () => onSelect(guide)),
        ],
      ),
    );
  }
}

class _GuideCategoryCard extends StatelessWidget {
  const _GuideCategoryCard({required this.guide, required this.onTap});

  final MitigationGuide guide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: guide.color,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              guide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideSteps extends StatelessWidget {
  const _GuideSteps({required this.guide, super.key});

  final MitigationGuide guide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (var index = 0; index < guide.steps.length; index++) ...[
            _GuideStepCard(
              number: index + 1,
              text: guide.steps[index],
              color: guide.color,
            ),
            if (index < guide.steps.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sumber: ${guide.sourceTitle} — ${guide.sourceOrganization}. '
              'Diakses ${guide.sourceAccessedAt}. ${guide.sourceUrl}\n'
              'Ringkasan edukasi umum; ikuti arahan terbaru PVMBG dan BPBD.',
              style: const TextStyle(
                color: Color(0xFFD0D9E1),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.number,
    required this.text,
    required this.color,
  });

  final int number;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCardSurface(
      variant: AppCardVariant.mitigationStep,
      accent: color,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.xl,
            height: AppSpacing.xl,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MitigationBackgroundRing extends StatelessWidget {
  const _MitigationBackgroundRing();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 280,
        height: 280,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.035),
            width: 25,
          ),
        ),
      ),
    );
  }
}

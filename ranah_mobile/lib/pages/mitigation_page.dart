import 'package:flutter/material.dart';

import '../data/mitigation_guides.dart';
import '../models/mitigation_guide.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

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
              if (guide == null)
                _GuideCategoryGrid(onSelect: _openGuide)
              else
                _GuideSteps(guide: guide),
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
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF21085F), Color(0xFF100525)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 42),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PANDUAN MITIGASI',
                  style: TextStyle(
                    color: Color(0xFF82C7FF),
                    fontSize: 13,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Text(
                  'Panduan Mitigasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  guideTitle ?? 'Jalur Evakuasi & Langkah Keselamatan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFC8C0D5),
                    fontSize: 13,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          minimumSize: const Size(0, 34),
          padding: const EdgeInsets.symmetric(horizontal: 11),
          side: const BorderSide(color: Color(0xFFE1E5EA)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _GuideCategoryGrid extends StatelessWidget {
  const _GuideCategoryGrid({required this.onSelect});

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
      borderRadius: BorderRadius.circular(12),
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
                fontSize: 15,
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
  const _GuideSteps({required this.guide});

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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

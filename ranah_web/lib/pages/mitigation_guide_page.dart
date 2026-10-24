import 'package:flutter/material.dart';

import '../data/mitigation_guides.dart';
import '../theme/ranah_theme.dart';

class MitigationGuidePage extends StatefulWidget {
  const MitigationGuidePage({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<MitigationGuidePage> createState() => _MitigationGuidePageState();
}

class _MitigationGuidePageState extends State<MitigationGuidePage> {
  MitigationStage _selectedStage = MitigationStage.before;

  @override
  Widget build(BuildContext context) {
    final guide = mitigationGuides.firstWhere(
      (item) => item.stage == _selectedStage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth > 1000
            ? 1000.0
            : constraints.maxWidth;
        final listInset = (width * .07).clamp(12.0, 48.0);
        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _MitigationBanner(onBack: widget.onBack),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _StageSelector(
                      selected: _selectedStage,
                      onSelected: (stage) =>
                          setState(() => _selectedStage = stage),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(listInset, 7, listInset, 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          guide.placeholder
                              ? Icons.info_outline_rounded
                              : Icons.verified_user_outlined,
                          size: 13,
                          color: const Color(0xFFFFC85A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            guide.notice,
                            style: const TextStyle(
                              color: Color(0xFFFFD788),
                              fontSize: 9,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: listInset),
                    child: Column(
                      children: [
                        for (var index = 0; index < guide.steps.length; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: index == guide.steps.length - 1 ? 0 : 14,
                            ),
                            child: _GuideStepCard(
                              number: index + 1,
                              text: guide.steps[index],
                              guide: guide,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MitigationBanner extends StatelessWidget {
  const _MitigationBanner({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    padding: const EdgeInsets.only(left: 12, right: 6),
    color: RanahColors.banner,
    child: Row(
      children: [
        const Icon(Icons.shield_outlined, size: 28, color: Colors.white),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DISASTER EVACUATION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFF91A8D0),
                  fontSize: 8,
                  letterSpacing: .45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Panduan Mitigasi',
                maxLines: 1,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                'Jalur Evakuasi & Langkah Keselamatan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Color(0xFFC1C8D7), fontSize: 8),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onBack,
          tooltip: 'Kembali',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 34, height: 38),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.arrow_back, size: 17, color: Colors.white),
        ),
      ],
    ),
  );
}

class _StageSelector extends StatelessWidget {
  const _StageSelector({required this.selected, required this.onSelected});

  final MitigationStage selected;
  final ValueChanged<MitigationStage> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const spacing = 10.0;
      final buttonWidth = ((constraints.maxWidth - spacing * 3) / 4).clamp(
        0.0,
        170.0,
      );
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < mitigationGuides.length; index++) ...[
            if (index > 0) const SizedBox(width: spacing),
            SizedBox(
              width: buttonWidth,
              height: 42,
              child: _StageButton(
                guide: mitigationGuides[index],
                selected: selected == mitigationGuides[index].stage,
                onTap: () => onSelected(mitigationGuides[index].stage),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _StageButton extends StatelessWidget {
  const _StageButton({
    required this.guide,
    required this.selected,
    required this.onTap,
  });

  final MitigationGuide guide;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: guide.accent.withValues(alpha: selected ? 1 : .62),
    borderRadius: BorderRadius.circular(9),
    elevation: selected ? 3 : 1,
    shadowColor: Colors.black54,
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: onTap,
      child: Center(
        child: Text(
          guide.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: .68),
            fontSize: 11,
            height: 1.05,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _GuideStepCard extends StatelessWidget {
  const _GuideStepCard({
    required this.number,
    required this.text,
    required this.guide,
  });

  final int number;
  final String text;
  final MitigationGuide guide;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey('mitigation-step-${guide.stage.name}-$number'),
    constraints: const BoxConstraints(minHeight: 55),
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: guide.cardColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
        color: guide.accent.withValues(alpha: guide.placeholder ? .4 : .12),
      ),
    ),
    child: Row(
      children: [
        Container(
          width: 21,
          height: 21,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: guide.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              height: 1.15,
            ),
          ),
        ),
      ],
    ),
  );
}

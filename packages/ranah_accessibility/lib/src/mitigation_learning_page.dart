import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'guide_illustration.dart';
import 'mitigation_content.dart';

class MitigationLearningPage extends StatefulWidget {
  const MitigationLearningPage({required this.onBack, super.key});
  final VoidCallback onBack;
  @override
  State<MitigationLearningPage> createState() => _MitigationLearningPageState();
}

class _MitigationLearningPageState extends State<MitigationLearningPage> {
  final _scroll = ScrollController();
  MitigationLesson? _lesson;
  int _step = 0;
  bool _summary = false;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _top() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });
  void _choose(MitigationLesson? lesson) {
    setState(() {
      _lesson = lesson;
      _step = 0;
      _summary = false;
    });
    _top();
  }

  void _move(int delta) {
    setState(() {
      _step += delta;
      _summary = false;
    });
    _top();
  }

  Future<void> _source(GuideSource source) async {
    try {
      if (!await launchUrl(
        Uri.parse(source.url),
        mode: LaunchMode.externalApplication,
      ))
        throw StateError('Tidak tersedia');
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tautan belum dapat dibuka. Alamat sumber: ${source.url}',
            ),
          ),
        );
    }
  }

  Widget _text(
    String value, {
    double size = 16,
    Color color = const Color(0xFFCBDEEB),
    FontWeight weight = FontWeight.normal,
  }) => Text(
    value,
    style: TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      height: 1.5,
    ),
  );

  Widget _sources(Iterable<GuideSource> values) {
    final sources = {for (final source in values) source.id: source}.values;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF102F49),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF315674)),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ExpansionTile(
          key: ValueKey('guide-sources-${sources.map((s) => s.id).join('-')}'),
          iconColor: const Color(0xFFA3DAE6),
          collapsedIconColor: const Color(0xFFA3DAE6),
          title: _text(
            'Sumber materi',
            color: Colors.white,
            weight: FontWeight.w700,
          ),
          subtitle: _text(
            'Ringkasan RANAH dari ${sources.map((s) => s.organization).toSet().join(' & ')}',
            size: 13,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            for (final source in sources)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _text(
                      '${source.organization} · ${source.title}',
                      color: Colors.white,
                      weight: FontWeight.w700,
                    ),
                    _text(source.locator, size: 14),
                    _text('Diakses ${GuideSource.checkedAt}', size: 13),
                    SelectableText(
                      source.url,
                      style: const TextStyle(
                        color: Color(0xFFA3DAE6),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _source(source),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFA3DAE6),
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Buka sumber resmi'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _category(MitigationLesson lesson, int index, double width) =>
      SizedBox(
        width: width,
        child: Material(
          color: const Color(0xFF133D5C),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('guide-category-${lesson.id}'),
            onTap: () => _choose(lesson),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lesson.accent.withValues(alpha: .38)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: lesson.accent.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          lesson.icon,
                          color: lesson.accent,
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      _text(
                        '0${index + 1}',
                        color: lesson.accent,
                        size: 20,
                        weight: FontWeight.w800,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _text(
                    lesson.title,
                    color: Colors.white,
                    size: 22,
                    weight: FontWeight.w800,
                  ),
                  const SizedBox(height: 5),
                  _text(lesson.subtitle),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _text(
                          '${lesson.steps.length} langkah bergambar',
                          color: lesson.accent,
                          size: 14,
                          weight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded, color: lesson.accent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  List<Widget> _overview() => [
    _text(
      'Kenali langkahnya, pahami alasannya.',
      size: 28,
      color: Colors.white,
      weight: FontWeight.w800,
    ),
    const SizedBox(height: 10),
    _text(
      'Pilih tahap yang ingin dipelajari. Baca satu tindakan, lihat ilustrasinya, lalu lanjut sesuai kebutuhan.',
    ),
    const SizedBox(height: 22),
    LayoutBuilder(
      builder: (context, box) {
        final columns = box.maxWidth >= 700 ? 2 : 1;
        final width = (box.maxWidth - (columns - 1) * 16) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var i = 0; i < mitigationLessons.length; i++)
              _category(mitigationLessons[i], i, width),
          ],
        );
      },
    ),
    const SizedBox(height: 22),
    _text(
      'Ilustrasi dan materi tersimpan di aplikasi. Membuka tautan sumber memerlukan internet.',
      size: 14,
    ),
    const SizedBox(height: 18),
    _sources([bnpbPreparation, healthGuide, bnpbMessages, bpbdRecovery]),
  ];

  Widget _action(MitigationLesson lesson, IllustratedGuideStep step) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _text(step.title, color: Colors.white, size: 26, weight: FontWeight.w800),
      const SizedBox(height: 14),
      _text(step.action, size: 20, color: Colors.white),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF173D59),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: lesson.accent,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _text(
                    'Kenapa penting?',
                    color: lesson.accent,
                    weight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _text(step.reason),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF4B283B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF815060)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _text(
              'Hindari',
              color: const Color(0xFFFFBDC7),
              weight: FontWeight.w800,
            ),
            const SizedBox(height: 6),
            _text(step.avoid, color: const Color(0xFFFFE2E7)),
          ],
        ),
      ),
    ],
  );

  List<Widget> _detail(MitigationLesson lesson) {
    final step = lesson.steps[_step];
    return [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in mitigationLessons)
            ChoiceChip(
              label: Text(item.title),
              selected: item.id == lesson.id,
              selectedColor: item.accent,
              backgroundColor: const Color(0xFF163C59),
              labelStyle: TextStyle(
                color: item.id == lesson.id
                    ? const Color(0xFF102F49)
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              checkmarkColor: const Color(0xFF102F49),
              onSelected: (_) {
                if (item.id != lesson.id) _choose(item);
              },
            ),
        ],
      ),
      const SizedBox(height: 22),
      _text(
        lesson.title,
        color: lesson.accent,
        weight: FontWeight.w700,
        size: 18,
      ),
      const SizedBox(height: 8),
      _text(
        _summary
            ? 'Ringkasan tahap'
            : 'Langkah ${_step + 1} dari ${lesson.steps.length}',
        size: 14,
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value: _summary ? 1 : (_step + 1) / lesson.steps.length,
          minHeight: 6,
          color: lesson.accent,
          backgroundColor: const Color(0xFF244C66),
        ),
      ),
      const SizedBox(height: 22),
      if (_summary) ...[
        _text(
          lesson.takeaway,
          color: Colors.white,
          size: 25,
          weight: FontWeight.w800,
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < lesson.steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _text(
              '${i + 1}. ${lesson.steps[i].action}',
              color: Colors.white,
              size: 18,
            ),
          ),
        _text(
          'Membaca ringkasan bukan penilaian kesiapan atau izin beraktivitas di kawasan bahaya.',
          size: 14,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          key: const ValueKey('guide-choose-another'),
          onPressed: () => _choose(null),
          icon: const Icon(Icons.grid_view_rounded),
          label: const Padding(
            padding: EdgeInsets.all(14),
            child: Text('Pilih panduan lain'),
          ),
        ),
      ] else ...[
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          child: LayoutBuilder(
            key: ValueKey('guide-step-${lesson.id}-$_step'),
            builder: (context, box) {
              final illustration = GuideIllustration(
                key: ValueKey('guide-illustration-${lesson.id}-$_step'),
                step: step,
                accent: lesson.accent,
              );
              if (box.maxWidth >= 760)
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: illustration),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _action(lesson, step)),
                  ],
                );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  illustration,
                  const SizedBox(height: 22),
                  _action(lesson, step),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('guide-step-previous'),
              onPressed: _step > 0 ? () => _move(-1) : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size(48, 52),
                side: const BorderSide(color: Color(0xFF7193AB)),
              ),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Sebelumnya'),
            ),
            FilledButton.icon(
              key: const ValueKey('guide-step-next'),
              onPressed: () {
                if (_step == lesson.steps.length - 1) {
                  setState(() => _summary = true);
                  _top();
                } else {
                  _move(1);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: lesson.accent,
                foregroundColor: const Color(0xFF102F49),
                minimumSize: const Size(48, 52),
              ),
              icon: Icon(
                _step == lesson.steps.length - 1
                    ? Icons.summarize_outlined
                    : Icons.arrow_forward_rounded,
              ),
              label: Text(
                _step == lesson.steps.length - 1
                    ? 'Lihat ringkasan'
                    : 'Langkah berikutnya',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF102F49),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: ExpansionTile(
              key: ValueKey('guide-all-steps-${lesson.id}'),
              iconColor: lesson.accent,
              collapsedIconColor: lesson.accent,
              title: _text(
                'Lihat semua langkah',
                color: Colors.white,
                weight: FontWeight.w700,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (var i = 0; i < lesson.steps.length; i++)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: _text(
                      '${i + 1}. ${lesson.steps[i].title}',
                      color: lesson.accent,
                      weight: FontWeight.w700,
                    ),
                    subtitle: _text(lesson.steps[i].action),
                    onTap: () {
                      setState(() {
                        _step = i;
                        _summary = false;
                      });
                      _top();
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
      const SizedBox(height: 18),
      _sources(
        _summary ? lesson.steps.map((item) => item.source) : [step.source],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: _lesson == null,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && _lesson != null) _choose(null);
    },
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2846), Color(0xFF103C56)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth > 1100 ? 1100 : constraints.maxWidth,
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.all(constraints.maxWidth < 600 ? 18 : 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFA3DAE6),
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _text(
                          'Panduan Mitigasi',
                          color: Colors.white,
                          size: 23,
                          weight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _text(
                    'Materi edukasi umum. Saat darurat, ikuti arahan PVMBG dan BPBD setempat.',
                    size: 14,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('guide-back'),
                      onPressed: _lesson == null
                          ? widget.onBack
                          : () => _choose(null),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFA3DAE6),
                        minimumSize: const Size(48, 48),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 20),
                      label: const Text('Kembali'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...(_lesson == null ? _overview() : _detail(_lesson!)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

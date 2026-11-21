import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'emergency_contacts_card.dart';
import 'official_krb_map_button.dart';
import 'siaga_guide.dart';
import 'voice_engine.dart';
import 'volcano_reference.dart';

class SiagaLocationPage extends StatefulWidget {
  const SiagaLocationPage({
    required this.loadGuide,
    required this.readLocation,
    required this.contacts,
    required this.onOpenReport,
    this.initialLocation,
    this.autoLocate = false,
    this.store,
    this.voiceEngine,
    super.key,
  });
  final Future<SiagaGuide> Function(String name) loadGuide;
  final Future<SiagaLocation> Function() readLocation;
  final List<QuickEmergencyContact> contacts;
  final ValueChanged<SiagaGuide> onOpenReport;
  final SiagaLocation? initialLocation;
  final bool autoLocate;
  final SiagaGuideStore? store;
  final VoiceEngine? voiceEngine;
  @override
  State<SiagaLocationPage> createState() => _SiagaLocationPageState();
}

class _SiagaLocationPageState extends State<SiagaLocationPage> {
  late final SiagaGuideStore _store = widget.store ?? SiagaGuideStore();
  VoiceEngine get _voice => widget.voiceEngine ?? DeviceVoiceEngine();
  SiagaLocation? _location;
  SiagaGuide? _guide, _saved;
  String? _selected, _error;
  bool _loading = false,
      _locating = false,
      _speaking = false,
      _usedVoice = false;
  final _scroll = ScrollController();
  void _showTop() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
  });

  int _generation = 0;
  int _speechGeneration = 0;
  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation?.isValid == true
        ? widget.initialLocation
        : null;
    _selected = _location?.nearest.name;
    _restore();
    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_location == null) {
          _locate();
        } else {
          _load();
        }
      });
    }
  }

  Future<void> _restore() async {
    try {
      final saved = await _store.read();
      if (!mounted) return;
      setState(() {
        _saved = saved;
        if (_selected == null && _guide == null && !_loading) {
          _selected = saved?.name;
          _guide = saved;
        }
      });
    } catch (_) {
      /* Device storage can be unavailable in private browsing. */
    }
  }

  Future<void> _locate() async {
    setState(() {
      _locating = true;
      _error = null;
    });
    try {
      final location = await widget.readLocation();
      if (!location.isValid) throw const FormatException('Lokasi tidak valid.');
      if (!mounted) return;
      setState(() {
        _location = location;
        _selected = location.nearest.name;
        _guide = null;
      });
      await _load();
    } catch (_) {
      if (mounted)
        setState(
          () =>
              _error = 'Lokasi belum dapat dibaca. Pilih gunung secara manual.',
        );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _load() async {
    final name = _selected;
    if (name == null || _loading) return;
    final generation = ++_generation;
    _speechGeneration++;
    setState(() {
      _loading = true;
      _guide = null;
      _error = null;
      _speaking = false;
    });
    try {
      if (_usedVoice) await _stopSpeech();
      if (!mounted || generation != _generation) return;
      final guide = await widget.loadGuide(name);
      if (normalizeVolcanoName(guide.name) != normalizeVolcanoName(name) ||
          guide.id <= 0) {
        throw const FormatException('Nama laporan tidak cocok.');
      }
      if (mounted && generation == _generation) {
        setState(() => _guide = guide);
        _showTop();
      }
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _guide =
            normalizeVolcanoName(_saved?.name ?? '') ==
                normalizeVolcanoName(name)
            ? _saved
            : null;
        _error = _guide == null
            ? 'Laporan belum dapat dimuat. Periksa koneksi atau pilih gunung lain.'
            : 'Pembaruan gagal. Menampilkan panduan yang pernah disimpan.';
      });
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  Future<void> _stopSpeech() async {
    try {
      await _voice.stopSpeaking();
    } catch (_) {
      /* The text remains available when speech is unsupported. */
    }
  }

  Future<void> _speak() async {
    final guide = _guide;
    if (guide?.recommendation?.trim().isNotEmpty != true) return;
    _usedVoice = true;
    final generation = ++_speechGeneration;
    if (_speaking) {
      await _stopSpeech();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    setState(() => _speaking = true);
    try {
      await _voice.speak(
        '${guide!.fromCache ? 'Panduan tersimpan. Kondisi terbaru belum dipastikan. ' : ''}'
        'Rekomendasi untuk Gunung ${guide.name}. '
        'Periode ${guide.displayPeriod}. ${guide.recommendation}',
      );
    } catch (_) {
      if (mounted)
        _message('Suara belum tersedia. Rekomendasi tetap dapat dibaca.');
    } finally {
      if (mounted && generation == _speechGeneration)
        setState(() => _speaking = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _save() async {
    final guide = _guide;
    if (guide == null) return;
    try {
      await _store.save(guide);
      final saved = await _store.read();
      if (mounted) {
        setState(() => _saved = saved);
        _message('Panduan disimpan di perangkat ini.');
      }
    } catch (_) {
      if (mounted)
        _message(
          'Penyimpanan gagal. Ruang penyimpanan perangkat mungkin tidak tersedia.',
        );
    }
  }

  @override
  void dispose() {
    _generation++;
    _speechGeneration++;
    if (_usedVoice) _stopSpeech();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guide = _guide;
    final reference = volcanoReference(_selected ?? '');
    final names = volcanoReferences.values.map((r) => r.name).toList()..sort();
    return Scaffold(
      backgroundColor: const Color(0xFF102F49),
      appBar: AppBar(
        backgroundColor: const Color(0xFF17003E),
        foregroundColor: Colors.white,
        toolbarHeight: MediaQuery.textScalerOf(
          context,
        ).scale(56).clamp(76.0, 120.0).toDouble(),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIAGA ERUPSI',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFB7B9DD),
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              'Siaga di Lokasi Saya',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Kontak bantuan',
            icon: const Icon(Icons.phone_in_talk),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: const Color(0xFF102F49),
              builder: (_) => SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: EmergencyContactsCard(contacts: widget.contacts),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                if (guide != null)
                  _section(
                    'Rekomendasi · ${guide.name}',
                    [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor(
                              guide.status,
                            ).withValues(alpha: .13),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _statusColor(guide.status),
                            ),
                          ),
                          child: Text(
                            guide.status,
                            style: TextStyle(
                              color: _statusColor(guide.status),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _metadata(
                        Icons.event_outlined,
                        'Periode pengamatan: ${guide.displayPeriod}',
                      ),
                      _metadata(
                        Icons.update,
                        'Data diambil: ${guide.displayRetrievedAt}',
                      ),
                      _metadata(
                        Icons.verified_outlined,
                        'Sumber: ${guide.source}',
                      ),
                      if (guide.fromCache)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0D4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Salinan tersimpan; belum memastikan kondisi terbaru.',
                            style: TextStyle(color: Color(0xFF855000)),
                          ),
                        ),
                      const Divider(),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed:
                                guide.recommendation?.trim().isNotEmpty == true
                                ? _speak
                                : null,
                            icon: Icon(
                              _speaking ? Icons.stop : Icons.volume_up,
                            ),
                            label: Text(
                              _speaking
                                  ? 'Hentikan Suara'
                                  : 'Dengarkan Rekomendasi',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Simpan Panduan Offline'),
                          ),
                          OutlinedButton(
                            onPressed: () => widget.onOpenReport(guide),
                            child: const Text('Buka Laporan Gunung'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (guide.recommendationParagraphs.isEmpty)
                        const Text(
                          'Rekomendasi belum tersedia pada laporan ini. Buka laporan gunung atau hubungi pihak berwenang.',
                        )
                      else
                        for (final paragraph in guide.recommendationParagraphs)
                          _recommendationItem(paragraph),
                      OfficialKrbMapButton(name: guide.name),
                      const Text(
                        'Penyimpanan offline berisi teks laporan. Peta KRB resmi memerlukan internet.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                    icon: Icons.landscape_rounded,
                    subtitle: 'Rekomendasi dari laporan gunung pilihan',
                  ),
                _section('Panduan erupsi untuk gunung pilihan', [
                  const Text(
                    'Gunakan lokasi untuk memilih gunung terdekat atau pilih manual. '
                    'Jarak tidak menyatakan wilayah terdampak, aman, atau perintah evakuasi.',
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _locating || _loading ? null : _locate,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      _locating ? 'Membaca lokasi…' : 'Gunakan Lokasi Saya',
                    ),
                  ),
                  const Text(
                    'Lokasi dipakai di perangkat untuk menghitung jarak ke gunung.',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (_location case final location?) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)} · ${location.accuracyLabel}',
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(
                            text:
                                '${location.latitude}, ${location.longitude}; ${location.accuracyLabel}',
                          ),
                        );
                        if (mounted)
                          _message(
                            'Koordinat disalin. Bagikan lewat aplikasi komunikasi pilihan Anda.',
                          );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Salin Lokasi untuk Bantuan'),
                    ),
                    if (reference != null)
                      Text(
                        'Jarak ke ${reference.name}: sekitar ${location.distanceKm(reference).toStringAsFixed(1)} km.',
                      ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selected,
                    key: ValueKey(_selected),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Gunung yang dipantau',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final name in names)
                        DropdownMenuItem(
                          value: name,
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: _locating || _loading
                        ? null
                        : (name) {
                            _generation++;
                            _speechGeneration++;
                            if (_usedVoice) _stopSpeech();
                            setState(() {
                              _selected = name;
                              _guide = null;
                              _error = null;
                              _speaking = false;
                            });
                          },
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _selected == null || _loading || _locating
                        ? null
                        : _load,
                    child: Text(
                      _loading ? 'Memuat laporan…' : 'Tampilkan Panduan',
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ]),
                if (_saved != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _loading || _locating
                          ? null
                          : () {
                              _speechGeneration++;
                              if (_usedVoice) _stopSpeech();
                              setState(() {
                                _speaking = false;
                                _selected = _saved!.name;
                                _guide = _saved;
                                _error = null;
                              });
                              _showTop();
                            },
                      icon: const Icon(Icons.offline_pin),
                      label: Text('Buka Panduan Tersimpan · ${_saved!.name}'),
                    ),
                  ),
                EmergencyContactsCard(contacts: widget.contacts),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String value) {
    final level = RegExp(
      r'Level\s+(IV|III|II|I)\b',
      caseSensitive: false,
    ).firstMatch(value)?.group(1)?.toUpperCase();
    return switch (level) {
      'I' => const Color(0xFF12694D),
      'II' => const Color(0xFF855600),
      'III' => const Color(0xFFAD470B),
      'IV' => const Color(0xFFB42336),
      _ => const Color(0xFF52687C),
    };
  }

  Widget _metadata(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF59728A)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF52677E),
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _recommendationItem(String paragraph) {
    final badgeSize = MediaQuery.textScalerOf(context).scale(28);
    final match = RegExp(r'^(\d{1,2})[.)]\s+').firstMatch(paragraph);
    final text = match == null ? paragraph : paragraph.substring(match.end);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF0F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E3EF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: badgeSize,
            height: badgeSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF21005E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: match == null
                ? const Icon(Icons.info_outline, size: 17, color: Colors.white)
                : Text(
                    match.group(1)!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.65,
                color: Color(0xFF172742),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    List<Widget> children, {
    IconData icon = Icons.my_location,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    const ink = Color(0xFF172742);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(bodyColor: ink, displayColor: ink),
        colorScheme: theme.colorScheme.copyWith(onSurface: ink),
      ),
      child: DefaultTextStyle(
        style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: ink,
          height: 1.5,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC6D8E8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF21005E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 24, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF60758B),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

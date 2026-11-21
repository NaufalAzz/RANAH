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
    this.store,
    this.voiceEngine,
    super.key,
  });
  final Future<SiagaGuide> Function(String name) loadGuide;
  final Future<SiagaLocation> Function() readLocation;
  final List<QuickEmergencyContact> contacts;
  final ValueChanged<SiagaGuide> onOpenReport;
  final SiagaLocation? initialLocation;
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
        'Periode ${guide.period}. ${guide.recommendation}',
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
        title: const Text('Siaga di Lokasi Saya'),
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                if (guide != null)
                  _section('Rekomendasi · ${guide.name}', [
                    Text(
                      guide.status,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Periode pengamatan: ${guide.period.isEmpty ? 'belum tersedia' : guide.period}',
                    ),
                    Text(
                      'Data diambil: ${guide.retrievedAt?.toLocal().toString() ?? 'waktu belum tersedia'}',
                    ),
                    Text('Sumber: ${guide.source}'),
                    if (guide.fromCache)
                      const Text(
                        'Salinan tersimpan; belum memastikan kondisi terbaru.',
                        style: TextStyle(color: Colors.deepOrange),
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
                          icon: Icon(_speaking ? Icons.stop : Icons.volume_up),
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
                    SelectableText(
                      guide.recommendation?.trim().isNotEmpty == true
                          ? guide.recommendation!
                          : 'Rekomendasi belum tersedia pada laporan ini. Buka laporan gunung atau hubungi pihak berwenang.',
                    ),
                    OfficialKrbMapButton(name: guide.name),
                    const Text(
                      'Penyimpanan offline berisi teks laporan. Peta KRB resmi memerlukan internet.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ]),
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
                        DropdownMenuItem(value: name, child: Text(name)),
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

  Widget _section(String title, List<Widget> children) {
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
        ),
        child: Card(
          color: const Color(0xFFF3F6FC),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

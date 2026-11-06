import 'dart:async';
import 'package:flutter/material.dart';
import 'eruption_content.dart';
import 'eruption_store.dart';
import 'voice_engine.dart';

// App adapters preserve the existing API client and its configured base URL.
typedef VolcanoListLoader = Future<List<Map<String, dynamic>>> Function();
typedef VolcanoDetailLoader = Future<Map<String, dynamic>> Function(int id);

enum EruptionSection {
  actions('Tindakan Sekarang', Icons.health_and_safety),
  local('Arahan Wilayah Saya', Icons.location_on_outlined),
  offline('Paket Siaga Offline', Icons.download_for_offline_outlined),
  follow('Gunung yang Saya Ikuti', Icons.landscape_outlined),
  training('Latihan Erupsi', Icons.school_outlined);

  const EruptionSection(this.title, this.icon);
  final String title;
  final IconData icon;
}

class EruptionDashboard extends StatelessWidget {
  const EruptionDashboard({required this.onOpen, super.key});
  final void Function(EruptionSection) onOpen;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Siaga Erupsi',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            'Panduan singkat dan persiapan sebelum dibutuhkan.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          for (final section in EruptionSection.values)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FilledButton.icon(
                onPressed: () => onOpen(section),
                icon: Icon(section.icon),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(section.title),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class EruptionCenterPage extends StatefulWidget {
  const EruptionCenterPage({
    required this.section,
    required this.loadVolcanoes,
    required this.loadDetail,
    required this.onContacts,
    this.store,
    this.voiceEngine,
    super.key,
  });
  final EruptionSection section;
  final VolcanoListLoader loadVolcanoes;
  final VolcanoDetailLoader loadDetail;
  final VoidCallback onContacts;
  final EruptionStore? store;
  final VoiceEngine? voiceEngine;
  @override
  State<EruptionCenterPage> createState() => _EruptionCenterPageState();
}

class _EruptionCenterPageState extends State<EruptionCenterPage>
    with WidgetsBindingObserver {
  late final EruptionStore _store = widget.store ?? EruptionStore();
  late final VoiceEngine _voice = widget.voiceEngine ?? DeviceVoiceEngine();
  Map<String, dynamic> _state = {};
  List<Map<String, dynamic>> _volcanoes = [];
  bool _ready = false, _busy = false, _speaking = false;
  String? _error;
  ActionGuide? _guide;
  int _step = 0, _question = 0, _score = 0;
  int? _answer;
  bool _finished = false;
  int _speechSession = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _read();
  }

  Future<void> _read() async {
    try {
      final value = await _store.read();
      if (mounted)
        setState(() {
          _state = value;
          _ready = true;
        });
    } catch (_) {
      if (mounted)
        setState(() {
          _ready = true;
          _error = 'Penyimpanan lokal belum tersedia.';
        });
    }
  }

  Future<void> _persist(Map<String, dynamic> next) async {
    if (!mounted) return;
    setState(() => _state = next);
    try {
      await _store.save(next);
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Data belum tersimpan. Periksa ruang penyimpanan dan coba lagi.',
        );
    }
  }

  Future<void> _loadList() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final values = await widget.loadVolcanoes();
      if (mounted)
        setState(() {
          _volcanoes = values;
          if (values.isEmpty) _error = 'Belum ada data gunung dari server.';
        });
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Daftar gunung belum dapat dimuat. Periksa koneksi dan konfigurasi API. Paket tersimpan tetap tersedia.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _select(Map<String, dynamic> item) async {
    await _persist({
      ..._state,
      'selected': item,
      'detail': null,
      'savedAt': null,
    });
  }

  Future<void> _download() async {
    final selected = _state['selected'];
    if (selected is! Map) return;
    final id = int.tryParse('${selected['id']}');
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final detail = await widget.loadDetail(id);
      if ('${(detail['gunung'] as Map?)?['id']}' != '$id')
        throw const FormatException('Gunung berbeda');
      if (!mounted) return;
      await _persist({
        ..._state,
        'detail': detail,
        'savedAt': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      if (mounted)
        setState(
          () => _error =
              'Pembaruan gagal. Data tersimpan tidak dihapus dan bukan kondisi terkini.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopSpeech() async {
    _speechSession++;
    try {
      await _voice.stopSpeaking();
    } catch (_) {}
    if (mounted) setState(() => _speaking = false);
  }

  Future<void> _readStep() async {
    final session = ++_speechSession;
    setState(() => _speaking = true);
    try {
      await _voice
          .speak(_guide!.steps[_step])
          .timeout(const Duration(seconds: 40));
    } catch (_) {
      if (mounted && session == _speechSession)
        setState(
          () => _error =
              'Pembacaan suara belum tersedia. Panduan tetap dapat dibaca.',
        );
    } finally {
      if (mounted && session == _speechSession) await _stopSpeech();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_stopSpeech());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechSession++;
    unawaited(_voice.stopSpeaking().catchError((Object _) {}));
    super.dispose();
  }

  Widget _text(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 18)),
  );
  Widget _button(String label, VoidCallback? onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: FilledButton(
      onPressed: onTap,
      child: Padding(padding: const EdgeInsets.all(14), child: Text(label)),
    ),
  );

  List<Widget> _actions() {
    if (_guide == null)
      return [
        _text(
          'Pilih kondisi Anda. Panduan edukasi umum; ikuti arahan petugas. Jangan menunda menjauh dari bahaya untuk membuka aplikasi.',
        ),
        for (final guide in eruptionGuides)
          _button(
            guide.title,
            () => setState(() {
              _guide = guide;
              _step = 0;
            }),
          ),
        _button('Kontak bantuan', widget.onContacts),
      ];
    return [
      _text(_guide!.title),
      _text('Langkah ${_step + 1} dari ${_guide!.steps.length}'),
      Semantics(liveRegion: true, child: _text(_guide!.steps[_step])),
      _button(
        _speaking ? 'Hentikan pembacaan' : 'Dengarkan langkah ini',
        _speaking ? _stopSpeech : _readStep,
      ),
      if (_step > 0)
        _button('Langkah sebelumnya', () {
          unawaited(_stopSpeech());
          setState(() => _step--);
        }),
      if (_step < _guide!.steps.length - 1)
        _button('Langkah berikutnya', () {
          unawaited(_stopSpeech());
          setState(() => _step++);
        }),
      _button('Pilih kondisi lain', () {
        unawaited(_stopSpeech());
        setState(() => _guide = null);
      }),
      _button('Kontak bantuan', widget.onContacts),
      _text(
        'Sumber ringkasan: Buku Saku Menghadapi Bencana, BNPB. Materi bersifat umum, bukan perintah evakuasi setempat.\nhttps://bnpb.go.id/storage/app/media/Buku%20BNPB/Buku%20Saku%20Bencana%20BNPB.pdf',
      ),
    ];
  }

  List<Widget> _follow() {
    final selected = _state['selected'];
    final detail = _state['detail'];
    final gunung = detail is Map ? detail['gunung'] : selected;
    final reports = detail is Map && detail['laporan'] is List
        ? detail['laporan'] as List
        : [];
    return [
      _text(
        selected is Map
            ? 'Gunung pilihan: ${selected['nama']}'
            : 'Pilih gunung yang ingin Anda ikuti. Tidak memakai pelacakan lokasi.',
      ),
      if (gunung is Map) ...[
        _text(
          'Wilayah gunung: ${gunung['kabupaten'] ?? '-'}, ${gunung['provinsi'] ?? '-'}',
        ),
        _text(
          'Status dari sumber: ${gunung['status_aktivitas'] ?? 'Belum tersedia'}',
        ),
        _text(
          'Sumber: ${gunung['sumber_data'] ?? 'Belum tersedia'}\nWaktu data sumber: ${gunung['waktu_pengambilan'] ?? 'Tidak diketahui'}',
        ),
        _text(
          'Snapshot di perangkat: ${_state['savedAt'] ?? 'Belum diunduh'}. Data tersimpan bukan pemantauan langsung dan dapat berubah.',
        ),
      ],
      if (reports.isNotEmpty && reports.first is Map) ...[
        _text(
          'Rekomendasi pada laporan tersimpan: ${(reports.first as Map)['rekomendasi'] ?? 'Tidak tersedia'}',
        ),
        _text(
          'Sumber laporan: ${(reports.first as Map)['sumber'] ?? '-'}\n${(reports.first as Map)['url_sumber'] ?? '-'}\nWaktu publikasi: ${(reports.first as Map)['waktu_publikasi'] ?? '-'}',
        ),
      ],
      _button('Muat daftar gunung', _busy ? null : _loadList),
      if (selected is Map)
        _button(
          'Perbarui dan simpan laporan offline',
          _busy ? null : _download,
        ),
      for (final item in _volcanoes)
        ListTile(
          title: Text('${item['nama']}'),
          subtitle: Text('${item['provinsi'] ?? ''}'),
          selected: selected is Map && '${selected['id']}' == '${item['id']}',
          trailing: selected is Map && '${selected['id']}' == '${item['id']}'
              ? const Icon(Icons.check_circle)
              : null,
          onTap: _busy ? null : () => _select(item),
        ),
    ];
  }

  List<Widget> _offline() => [
    _text(
      'Panduan tindakan dan nomor kontak sudah disertakan dalam aplikasi mobile. Tidak perlu internet untuk membacanya. Di web, akses offline memerlukan halaman yang sudah dimuat dan penyimpanan browser; tidak dijamin saat membuka ulang browser tanpa koneksi.',
    ),
    _text(
      'Laporan gunung yang diunduh dapat dibaca kembali di perangkat. Peta dasar, panggilan telepon, dan pembaruan resmi memerlukan layanan masing-masing. Tidak ada paket peta offline dalam versi ini.',
    ),
    ..._follow(),
    _text('Daftar kesiapan pribadi (tersimpan di perangkat):'),
    for (var i = 0; i < preparednessChecklist.length; i++)
      CheckboxListTile(
        title: Text(preparednessChecklist[i]),
        value: (_state['checklist'] as List? ?? []).contains(i),
        onChanged: (value) {
          final checks = List<int>.from(_state['checklist'] as List? ?? []);
          if (value == true) {
            checks.add(i);
          } else {
            checks.remove(i);
          }
          _persist({..._state, 'checklist': checks.toSet().toList()});
        },
      ),
  ];
  List<Widget> _local() => [
    _text('Arahan Wilayah Saya'),
    _text(
      'Rekomendasi gunung di bawah berasal dari laporan sumber. RANAH belum memiliki pengumuman desa, posko, titik penjemputan, atau jalur evakuasi yang ditetapkan petugas untuk wilayah Anda.',
    ),
    _text(
      'Status gunung dan posisi terhadap KRB tidak otomatis menjadi perintah mengungsi. Pastikan arahan wilayah melalui BPBD atau petugas setempat.',
    ),
    _button('Hubungi petugas / layanan bantuan', widget.onContacts),
    ..._follow(),
  ];
  List<Widget> _training() {
    if (_finished)
      return [
        _text(
          'Latihan selesai: $_score dari ${eruptionTraining.length} keputusan sesuai panduan.',
        ),
        _text(
          'Hasil ini mengukur pemahaman latihan, bukan jaminan kesiapan atau keselamatan pada kejadian nyata.',
        ),
        _text(
          'Hasil terakhir disimpan di perangkat: ${_state['trainingScore'] ?? _score}.',
        ),
        _button(
          'Ulangi latihan',
          () => setState(() {
            _question = 0;
            _score = 0;
            _answer = null;
            _finished = false;
          }),
        ),
      ];
    final question = eruptionTraining[_question];
    return [
      _text(
        'LATIHAN — bukan kejadian atau peringatan nyata. Tanpa batas waktu.',
      ),
      if (_state['trainingAt'] != null)
        _text(
          'Latihan sebelumnya: ${_state['trainingScore']} dari ${eruptionTraining.length}, ${_state['trainingAt']}.',
        ),
      _text('Skenario ${_question + 1} dari ${eruptionTraining.length}'),
      _text(question.question),
      for (var i = 0; i < question.options.length; i++)
        _button(
          question.options[i],
          _answer == null
              ? () => setState(() {
                  _answer = i;
                  if (i == question.correct) _score++;
                })
              : null,
        ),
      if (_answer != null) ...[
        _text(
          _answer == question.correct
              ? 'Pilihan sesuai panduan.'
              : 'Pilihan perlu diperbaiki.',
        ),
        _text(question.explanation),
        _button('Lanjutkan', () {
          if (_question == eruptionTraining.length - 1) {
            setState(() => _finished = true);
            _persist({
              ..._state,
              'trainingScore': _score,
              'trainingAt': DateTime.now().toUtc().toIso8601String(),
            });
          } else {
            setState(() {
              _question++;
              _answer = null;
            });
          }
        }),
      ],
      _text(
        'Materi latihan mengacu pada ringkasan panduan BNPB yang juga tersedia di Tindakan Sekarang.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: theme.colorScheme.onSurface,
          displayColor: theme.colorScheme.onSurface,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.section.title)),
        backgroundColor: theme.colorScheme.surface,
        body: !_ready
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null)
                    Semantics(liveRegion: true, child: _text(_error!)),
                  ...switch (widget.section) {
                    EruptionSection.actions => _actions(),
                    EruptionSection.follow => _follow(),
                    EruptionSection.offline => _offline(),
                    EruptionSection.local => _local(),
                    EruptionSection.training => _training(),
                  },
                ],
              ),
      ),
    );
  }
}

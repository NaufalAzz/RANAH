import 'dart:async';

import 'package:flutter/material.dart';

import 'voice_command.dart';
import 'voice_engine.dart';

Future<VoiceDestination?> showVoiceNavigation(
  BuildContext context, {
  VoiceEngine? engine,
}) => showModalBottomSheet<VoiceDestination>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme.apply(
        bodyColor: Theme.of(context).colorScheme.onSurface,
        displayColor: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    child: VoiceNavigationSheet(engine: engine ?? DeviceVoiceEngine()),
  ),
);

class VoiceNavigationSheet extends StatefulWidget {
  const VoiceNavigationSheet({required this.engine, super.key});
  final VoiceEngine engine;

  @override
  State<VoiceNavigationSheet> createState() => _VoiceNavigationSheetState();
}

class _VoiceNavigationSheetState extends State<VoiceNavigationSheet>
    with WidgetsBindingObserver {
  bool _busy = false;
  bool _listening = false;
  bool _opening = false;
  String _words = '';
  String _message =
      'Ucapkan nama fitur, misalnya “panduan” atau “kontak darurat”.';
  List<VoiceDestination> _choices = [];
  int _session = 0;
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _silence() async {
    // Cancellation is best effort on unsupported browsers/platforms.
    try {
      await widget.engine.cancel();
    } catch (_) {}
    try {
      await widget.engine.stopSpeaking();
    } catch (_) {}
  }

  void _cancel() {
    _session++;
    _timeout?.cancel();
    unawaited(_silence());
    if (mounted)
      setState(() {
        _busy = false;
        _listening = false;
        _opening = false;
        _message = 'Suara dihentikan. Anda bisa mencoba lagi atau memilih tombol fitur.';
      });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached ||
        (state == AppLifecycleState.inactive && _listening))
      _cancel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session++;
    _timeout?.cancel();
    unawaited(_silence());
    super.dispose();
  }

  Future<void> _listen() async {
    if (_busy) return;
    final session = ++_session;
    setState(() {
      _busy = true;
      _words = '';
      _choices = [];
      _message = 'Menyiapkan mikrofon. Izinkan akses jika diminta perangkat.';
    });
    await _silence();
    if (!mounted || session != _session) return;
    _timeout = Timer(const Duration(seconds: 20), () {
      if (mounted && session == _session && !_opening) {
        _cancel();
      }
    });
    try {
      await widget.engine.listen(
        onText: (words, isFinal) {
          if (!mounted || session != _session || _opening) return;
          setState(() => _words = words);
          if (isFinal) {
            _timeout?.cancel();
            final choices = resolveVoiceCommand(words);
            if (choices.length == 1) {
              unawaited(_open(choices.single));
            } else {
              unawaited(widget.engine.cancel().catchError((Object _) {}));
              setState(() {
                _busy = false;
                _listening = false;
                _choices = choices;
                _message = choices.isEmpty
                    ? 'Perintah belum dikenali. Coba “buka panduan” atau pilih tombol fitur.'
                    : 'Pilih fitur evakuasi yang Anda maksud.';
              });
            }
          }
        },
        onError: (message) {
          if (!mounted || session != _session || _opening) return;
          _cancel();
          setState(() => _message = message);
        },
        onDone: () {
          if (!mounted || session != _session || _opening) return;
          setState(() {
            _listening = false;
            _busy = false;
            _message = 'Sesi selesai. Jika belum terbuka, coba lagi atau pilih tombol fitur.';
          });
        },
      );
      if (!mounted || session != _session || !_busy || _opening) return;
      setState(() {
        _listening = true;
        _message = 'Sedang mendengarkan. Silakan sebutkan nama fitur.';
      });
    } catch (error) {
      if (!mounted || session != _session) return;
      _cancel();
      setState(
        () => _message = error is UnsupportedError
            ? error.message ?? 'Pengenalan suara tidak tersedia.'
            : 'Mikrofon belum dapat digunakan. Periksa izin dan koneksi, atau pilih tombol fitur.',
      );
    }
  }

  Future<void> _open(VoiceDestination destination) async {
    if (_opening) return;
    final session = ++_session;
    _timeout?.cancel();
    setState(() {
      _opening = true;
      _busy = true;
      _listening = false;
      _message = '${destination.label} dibuka.';
    });
    await _silence();
    if (!mounted || session != _session) return;
    try {
      await widget.engine.speak(_message).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Text and navigation remain usable when Indonesian TTS is unavailable.
    }
    if (!mounted || session != _session) return;
    Navigator.of(context).pop(destination);
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .85,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Bicara ke RANAH',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                tooltip: 'Tutup suara',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Icon(
            _listening ? Icons.mic : Icons.mic_none,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            child: Text(
              _message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
          if (_words.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text('Terdengar: $_words', textAlign: TextAlign.center),
            ),
          const SizedBox(height: 16),
          const Text(
            'Mikrofon digunakan hanya saat sesi suara. Perangkat atau browser dapat memproses ucapan melalui layanan daring. Ketersediaan Bahasa Indonesia dan koneksi bergantung perangkat.',
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _listen,
            icon: const Icon(Icons.mic),
            label: const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Mulai bicara'),
            ),
          ),
          if (_busy)
            TextButton(onPressed: _cancel, child: const Text('Hentikan suara')),
          const SizedBox(height: 16),
          const Text(
            'Atau pilih fitur:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final choice
              in _choices.isEmpty ? VoiceDestination.values : _choices)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: _opening ? null : () => _open(choice),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(choice.label),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

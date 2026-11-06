import 'dart:async';
import 'dart:math' as math;

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
  backgroundColor: const Color(0xFF0C2B45),
  barrierColor: const Color(0xAA030919),
  constraints: const BoxConstraints(maxWidth: 600),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  clipBehavior: Clip.antiAlias,
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
  String _message = 'Tekan mikrofon, lalu sebutkan fitur yang ingin dicari.';
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
        _choices = [];
        _message = 'Sesi dihentikan. Tekan mikrofon untuk mencoba lagi.';
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
              _session++;
              unawaited(_silence());
              setState(() {
                _busy = false;
                _listening = false;
                _choices = choices;
                _message = choices.isEmpty
                    ? 'Perintah belum dikenali. Coba ucapkan “panduan” atau “gunung” lagi.'
                    : 'Ada beberapa fitur yang cocok. Pilih yang Anda maksud.';
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
            _message = 'Sesi selesai. Tekan mikrofon untuk mencoba lagi.';
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
            : 'Mikrofon belum dapat digunakan. Periksa izin dan koneksi, atau kembali ke navigasi aplikasi.',
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

  IconData _icon(VoiceDestination destination) => switch (destination) {
    VoiceDestination.home => Icons.home_outlined,
    VoiceDestination.guide => Icons.health_and_safety_outlined,
    VoiceDestination.map => Icons.map_outlined,
    VoiceDestination.activity => Icons.landscape_outlined,
    VoiceDestination.contacts => Icons.phone_in_talk_outlined,
    VoiceDestination.news => Icons.newspaper_outlined,
    VoiceDestination.notifications => Icons.notifications_outlined,
    VoiceDestination.menu => Icons.grid_view_outlined,
  };

  @override
  Widget build(BuildContext context) => SizedBox(
    height: math.min(MediaQuery.sizeOf(context).height * .88, 740.0),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B104A), Color(0xFF0C2B45), Color(0xFF123D5B)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x558EABC6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NAVIGASI SUARA',
                        style: TextStyle(
                          color: Color(0xFF9FDCE6),
                          fontSize: 12,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Bicara ke RANAH',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup suara',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0x223CA2B5),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x1133C5D3),
                  border: Border.all(
                    color: _listening
                        ? const Color(0xFF8DE5EC)
                        : const Color(0x554F899F),
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF442280), Color(0xFF21005E)],
                    ),
                  ),
                  child: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Semantics(
              liveRegion: true,
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_words.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF123D5B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF37617F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ucapan Anda',
                      style: TextStyle(color: Color(0xFFA8CADB), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '“$_words”',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const ValueKey('voice-start'),
              onPressed: _busy ? null : _listen,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8DE5EC),
                foregroundColor: const Color(0xFF0C2B45),
                disabledBackgroundColor: const Color(0xFF274D66),
                disabledForegroundColor: const Color(0xFFC4D9E5),
                minimumSize: const Size(48, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.mic_rounded),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _listening ? 'Sedang mendengarkan' : 'Mulai bicara',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            if (_busy)
              TextButton(
                onPressed: _cancel,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFFBAC2),
                ),
                child: const Text('Hentikan suara'),
              ),
            if (_choices.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '${_choices.length} fitur sesuai kata kunci',
                style: const TextStyle(
                  color: Color(0xFF9FDCE6),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              for (final choice in _choices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: const Color(0xFF163F60),
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      key: ValueKey('voice-result-${choice.name}'),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      leading: Icon(
                        _icon(choice),
                        color: const Color(0xFF9FDCE6),
                      ),
                      title: Text(
                        choice.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          choice.description,
                          style: const TextStyle(
                            color: Color(0xFFC5D6E4),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF9FDCE6),
                      ),
                      onTap: _opening ? null : () => _open(choice),
                    ),
                  ),
                ),
            ] else if (!_busy && _words.isEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Misalnya: “panduan” atau “gunung”.\nPilihan fitur muncul setelah ucapan dikenali.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFC5D6E4),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 22),
            const Text(
              'Mikrofon hanya aktif selama sesi suara. Pengenalan ucapan dapat memakai layanan daring perangkat atau browser.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFB0CBDD),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF9FDCE6),
              ),
              child: const Text('Kembali ke aplikasi'),
            ),
          ],
        ),
      ),
    ),
  );
}

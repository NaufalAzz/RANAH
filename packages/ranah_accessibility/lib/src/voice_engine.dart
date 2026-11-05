import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

abstract class VoiceEngine {
  Future<void> listen({
    required void Function(String words, bool isFinal) onText,
    required void Function(String message) onError,
    required void Function() onDone,
  });
  Future<void> cancel();
  Future<void> speak(String text);
  Future<void> stopSpeaking();
}

/// SpeechToText initializes once per process. Forward callbacks to the current
/// sheet so subsequent openings do not retain callbacks into disposed widgets.
class DeviceVoiceEngine implements VoiceEngine {
  DeviceVoiceEngine._();
  static final DeviceVoiceEngine _instance = DeviceVoiceEngine._();
  factory DeviceVoiceEngine() => _instance;

  final _speech = SpeechToText();
  FlutterTts? _tts;
  int _ttsGeneration = 0;
  void Function(String, bool)? _onText;
  void Function(String)? _onError;
  void Function()? _onDone;

  @override
  Future<void> listen({
    required void Function(String, bool) onText,
    required void Function(String) onError,
    required void Function() onDone,
  }) async {
    _onText = onText;
    _onError = onError;
    _onDone = onDone;
    final available = await _speech.initialize(
      options: [SpeechToText.androidNoBluetooth],
      onError: (error) => _onError?.call(
        error.errorMsg.contains('permission') ||
                error.errorMsg.contains('not_allowed')
            ? 'Izin mikrofon atau pengenalan suara belum diberikan. Periksa pengaturan perangkat atau browser, atau pilih tombol fitur.'
            : 'Ucapan belum dapat dikenali. Coba lagi di tempat lebih tenang atau pilih tombol fitur.',
      ),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') _onDone?.call();
      },
    );
    // The sheet can be closed while the OS permission prompt is open.
    if (_onText != onText) return;
    if (!available) {
      throw UnsupportedError(
        'Suara tidak tersedia atau izin belum diberikan. Periksa pengaturan mikrofon dan pengenalan suara. Anda tetap bisa memilih tombol fitur.',
      );
    }
    // Web Speech cannot enumerate installed recognition languages. Request
    // id-ID explicitly there; native platforms can check installed locales.
    var localeId = 'id-ID';
    if (!kIsWeb) {
      final locales = await _speech.locales();
      if (_onText != onText) return;
      final indonesian = locales.where(
        (locale) =>
            locale.localeId.toLowerCase().replaceAll('_', '-').startsWith('id'),
      );
      if (indonesian.isEmpty) {
        throw UnsupportedError(
          'Pengenalan Bahasa Indonesia belum tersedia pada perangkat ini. Pilih tombol fitur di bawah.',
        );
      }
      localeId = indonesian.first.localeId;
    }
    await _speech.listen(
      onResult: (result) =>
          _onText?.call(result.recognizedWords, result.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  @override
  Future<void> cancel() async {
    _onText = null;
    _onError = null;
    _onDone = null;
    await _speech.cancel();
  }

  @override
  Future<void> speak(String text) async {
    final generation = ++_ttsGeneration;
    final tts = _tts ??= FlutterTts();
    final available = await tts.isLanguageAvailable('id-ID');
    if (available != true && available != 1) {
      throw UnsupportedError('Suara Bahasa Indonesia belum tersedia.');
    }
    await tts.setLanguage('id-ID');
    await tts.setSpeechRate(0.45);
    await tts.awaitSpeakCompletion(true);
    if (generation != _ttsGeneration) return;
    await tts.speak(text);
  }

  @override
  Future<void> stopSpeaking() async {
    _ttsGeneration++;
    await _tts?.stop();
  }
}

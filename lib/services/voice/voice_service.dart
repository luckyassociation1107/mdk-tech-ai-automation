import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Speech input (mic) and spoken output (speaker) for the chat screen.
/// Everything runs on-device through the platform speech engines.
class VoiceService extends ChangeNotifier {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _sttReady = false;
  bool _listening = false;
  bool _speaking = false;

  bool get isListening => _listening;
  bool get isSpeaking => _speaking;

  /// Returns false when the device has no speech recognizer or mic permission
  /// was refused.
  Future<bool> _ensureStt() async {
    if (_sttReady) return true;
    _sttReady = await _stt.initialize(
      onStatus: (String status) {
        if (status == 'done' || status == 'notListening') {
          _listening = false;
          notifyListeners();
        }
      },
      onError: (_) {
        _listening = false;
        notifyListeners();
      },
    );
    return _sttReady;
  }

  /// Starts listening. [onText] gets the running transcript.
  Future<bool> startListening(void Function(String text) onText) async {
    if (!await _ensureStt()) return false;
    _listening = true;
    notifyListeners();
    await _stt.listen(
      onResult: (result) => onText(result.recognizedWords),
      listenOptions: SpeechListenOptions(partialResults: true),
    );
    return true;
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _listening = false;
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    _speaking = true;
    notifyListeners();
    _tts.setCompletionHandler(() {
      _speaking = false;
      notifyListeners();
    });
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    _speaking = false;
    notifyListeners();
  }
}

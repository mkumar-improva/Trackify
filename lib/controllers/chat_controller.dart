import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:trackify/types/chat_message.dart';
import '../services/chat_service.dart';

class ChatController extends ChangeNotifier {
  final ChatService _service;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isListening = false;
  String _partialTranscript = '';

  ChatController(this._service);

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;
  String get partialTranscript => _partialTranscript;

  void addSystem(String text) {
    _messages.insert(
      0,
      ChatMessage(
        id: UniqueKey().toString(),
        sender: ChatSender.system,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Future<void> sendUser(String text, {bool speakReply = false}) async {
    if (text.trim().isEmpty) return;
    final userMsg = ChatMessage(
      id: UniqueKey().toString(),
      sender: ChatSender.user,
      text: text.trim(),
      timestamp: DateTime.now(),
    );
    _messages.insert(0, userMsg);
    _isTyping = true;
    notifyListeners();

    // STREAMING reply -> updates one bot bubble progressively
    final botId = UniqueKey().toString();
    _messages.insert(
      0,
      ChatMessage(
        id: botId,
        sender: ChatSender.bot,
        text: '',
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();

    final buffer = StringBuffer();
    try {
      await for (final chunk in _service.streamPrompt(userMsg.text)) {
        buffer.write(chunk);
        final i = _messages.indexWhere((m) => m.id == botId);
        if (i >= 0) {
          _messages[i] = ChatMessage(
            id: botId,
            sender: ChatSender.bot,
            text: buffer.toString(),
            timestamp: DateTime.now(),
          );
          notifyListeners();
        }
      }

      if (speakReply && buffer.isNotEmpty) {
        await _tts.stop();
        await _tts.setSpeechRate(0.95);
        await _tts.speak(buffer.toString());
      }
    } catch (e) {
      _messages.insert(
        0,
        ChatMessage(
          id: UniqueKey().toString(),
          sender: ChatSender.system,
          text: '⚠️ $e',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // ---------- Voice (Speech-to-Text) ----------
  Future<bool> initSpeech() async {
    final available = await _speech.initialize();
    return available;
  }

  Future<void> startListening() async {
    if (_isListening) return;
    final ok = await initSpeech();
    if (!ok) return;

    _partialTranscript = '';
    _isListening = true;
    notifyListeners();

    await _speech.listen(
      onResult: (r) {
        _partialTranscript = r.recognizedWords;
        notifyListeners();
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: true,
      pauseFor: const Duration(seconds: 2),
    );
  }

  Future<void> stopListening({bool autoSend = true}) async {
    if (!_isListening) return;
    await _speech.stop();
    _isListening = false;
    notifyListeners();

    final finalText = _partialTranscript.trim();
    _partialTranscript = '';
    if (finalText.isNotEmpty && autoSend) {
      await sendUser(finalText, speakReply: true);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }
}

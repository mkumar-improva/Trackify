// lib/services/chat_service.dart
import 'dart:async';
import 'package:firebase_ai/firebase_ai.dart';

class ChatTurn {
  final String role; // optional for your own tracking: 'user' | 'model' | 'system'
  final String content;
  ChatTurn(this.role, this.content);
}

class ChatService {
  static const String _modelName = 'gemini-2.5-flash-lite';

  GenerativeModel _model() {
    return FirebaseAI.googleAI().generativeModel(model: _modelName);
  }

  /// One-shot reply
  Future<String> sendPrompt(String prompt, {List<ChatTurn>? history}) async {
    final input = <Content>[
      if (history != null && history.isNotEmpty)
        ...history.map((t) => Content.text(t.content)), // ✅ use Content.text
      Content.text(prompt),                                // ✅ use Content.text
    ];

    final res = await _model().generateContent(input);
    final text = res.text?.trim();
    return (text != null && text.isNotEmpty) ? text : 'I couldn’t find an answer.';
  }

  /// Streaming reply (for typing effect)
  Stream<String> streamPrompt(String prompt, {List<ChatTurn>? history}) async* {
    final input = <Content>[
      if (history != null && history.isNotEmpty)
        ...history.map((t) => Content.text(t.content)), // ✅ use Content.text
      Content.text(prompt),                                // ✅ use Content.text
    ];

    final stream = _model().generateContentStream(input);
    await for (final chunk in stream) {
      final text = chunk.text;
      if (text != null && text.isNotEmpty) yield text;
    }
  }
}

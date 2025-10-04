import 'package:flutter/material.dart';
import 'package:trackify/components/chat/chat_bubble.dart';
import 'package:trackify/components/chat/chat_input_bar.dart';
import 'package:trackify/components/chat/typing_indicator.dart';
import '../controllers/chat_controller.dart';
import '../services/chat_service.dart';

class TalkToKuboPage extends StatefulWidget {
  const TalkToKuboPage({super.key});

  @override
  State<TalkToKuboPage> createState() => _TalkToKuboPageState();
}

class _TalkToKuboPageState extends State<TalkToKuboPage> {
  late final ChatController _controller;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(ChatService());
    // Optional greeting
    _controller.addSystem('Welcome to Kubo! Ask about your spending, budgets, or trends.');
    _controller.addListener(_autoScrollToBottom);
  }

  void _autoScrollToBottom() {
    // Because we insert at index 0 but render reversed,
    // jump to min scroll extent to keep view at bottom.
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.minScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
    // Rebuild
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_autoScrollToBottom);
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = _controller.messages;

    return Scaffold(

      body: Column(
        children: [
          // Chat list
          Expanded(
            child: ListView.separated(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              reverse: true, // newest at bottom visually
              itemCount: messages.length + (_controller.isTyping ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                if (_controller.isTyping && index == 0) {
                  return const TypingIndicator();
                }
                final msg = messages[_controller.isTyping ? index - 1 : index];
                return Align(
                  alignment:
                  msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: ChatBubble(message: msg),
                );
              },
            ),
          ),

          // Input
          ChatInputBar(
            isListening: _controller.isListening,
            partialTranscript: _controller.partialTranscript,
            onSend: (text) => _controller.sendUser(text, speakReply: true),
            onMicStart: _controller.startListening,
            onMicStop: _controller.stopListening,
          ),
        ],
      ),
    );
  }
}

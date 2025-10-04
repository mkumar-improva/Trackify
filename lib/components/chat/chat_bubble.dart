import 'package:flutter/material.dart';
import 'package:trackify/types/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final align = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final radius = BorderRadius.circular(16);
    final color = message.bubbleColor(context);
    final textColor = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 640),
          margin: EdgeInsets.only(
            left: isUser ? 64 : 12,
            right: isUser ? 12 : 64,
            top: 6,
            bottom: 6,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: isUser
                ? BorderRadius.only(
              topLeft: radius.topLeft,
              topRight: radius.topRight,
              bottomLeft: radius.bottomLeft,
              bottomRight: const Radius.circular(4),
            )
                : BorderRadius.only(
              topLeft: radius.topLeft,
              topRight: radius.topRight,
              bottomRight: radius.bottomRight,
              bottomLeft: const Radius.circular(4),
            ),
          ),
          child: Text(message.text, style: TextStyle(fontSize: 15, color: textColor)),
        ),
      ],
    );
  }
}

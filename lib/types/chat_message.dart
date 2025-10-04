import 'package:flutter/material.dart';

enum ChatSender { user, bot, system }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  bool get isUser => sender == ChatSender.user;
  bool get isBot => sender == ChatSender.bot;
  Color bubbleColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (isUser) return cs.primary;
    if (isBot) return cs.surfaceVariant;
    return cs.surfaceContainerHighest;
  }
}

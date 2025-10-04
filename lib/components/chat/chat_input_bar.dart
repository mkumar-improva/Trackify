import 'package:flutter/material.dart';
import 'package:trackify/theme/app_theme.dart';

class ChatInputBar extends StatefulWidget {
  final bool isListening;
  final String partialTranscript;
  final Future<void> Function(String text) onSend;
  final Future<void> Function() onMicStart;
  final Future<void> Function() onMicStop;

  const ChatInputBar({
    super.key,
    required this.isListening,
    required this.partialTranscript,
    required this.onSend,
    required this.onMicStart,
    required this.onMicStop,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  bool _sending = false;

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.onSend(text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void didUpdateWidget(covariant ChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // When listening, show transcript live in the field (read-only feel)
    if (widget.isListening && widget.partialTranscript.isNotEmpty) {
      _controller.text = widget.partialTranscript;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          // border: Border(top: BorderSide(color: AppTheme.neonLime)),
        ),
        child: Row(
          children: [
            // Mic
            IconButton.filledTonal(
              onPressed: widget.isListening ? widget.onMicStop : widget.onMicStart,
              icon: Icon(widget.isListening ? Icons.mic : Icons.mic_none),
              tooltip: widget.isListening ? 'Stop' : 'Speak',
              color: AppTheme.neonLime,
            ),
            const SizedBox(width: 8),
            // Text box
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: widget.isListening ? 'Listening…' : 'Message Kubo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: _sending ? null : _handleSend,
              icon: _sending
                  ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              color: AppTheme.neonLime,
            ),
            // Send
          ],
        ),
      ),
    );
  }
}

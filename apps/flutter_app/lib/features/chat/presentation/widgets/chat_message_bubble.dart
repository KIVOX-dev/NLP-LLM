import 'package:flutter/material.dart';

import '../../domain/chat_message.dart';
import 'error_card.dart';
import 'loading_indicator.dart';
import 'translation_card.dart';

/// Renders one turn in the conversation: a right-aligned user bubble with
/// the raw Sanskrit input, or an assistant turn (loading / translation
/// result / error).
class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({required this.message, this.onRegenerate, super.key});

  final ChatMessage message;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    if (message.role == ChatRole.user) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: switch (message.status) {
            ChatMessageStatus.sending => const LoadingIndicator(),
            ChatMessageStatus.error => ErrorCard(
                message: message.errorMessage ?? 'Translation failed.',
                onRetry: onRegenerate,
              ),
            ChatMessageStatus.sent when message.translation != null =>
              TranslationCard(response: message.translation!, onRegenerate: onRegenerate),
            ChatMessageStatus.sent => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }
}

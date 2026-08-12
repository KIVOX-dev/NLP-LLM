import 'package:shared_models/shared_models.dart';

enum ChatRole { user, assistant }

enum ChatMessageStatus { sending, sent, error }

/// UI-side chat turn. Distinct from `shared_models.ConversationMessage`
/// (the persisted server shape) because the UI also needs to track
/// in-flight/error state for the "assistant is translating…" bubble.
class ChatMessage {
  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.translation,
    this.status = ChatMessageStatus.sent,
    this.errorMessage,
  });

  final String id;
  final ChatRole role;
  final String text;
  final TranslationResponse? translation;
  final ChatMessageStatus status;
  final String? errorMessage;

  ChatMessage copyWith({
    TranslationResponse? translation,
    ChatMessageStatus? status,
    String? errorMessage,
  }) {
    return ChatMessage(
      id: id,
      role: role,
      text: text,
      translation: translation ?? this.translation,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

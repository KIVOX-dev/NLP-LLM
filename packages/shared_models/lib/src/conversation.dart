class Conversation {
  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

enum MessageRole { user, assistant, system }

MessageRole messageRoleFromString(String value) => MessageRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => MessageRole.user,
    );

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
    this.translationMetadata,
    this.modelVersion,
  });

  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final DateTime createdAt;

  /// Raw translation response JSON, when this message is a translation result.
  final Map<String, dynamic>? translationMetadata;
  final String? modelVersion;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) => ConversationMessage(
        id: json['id'] as String,
        conversationId: json['conversation_id'] as String,
        role: messageRoleFromString(json['role'] as String),
        content: json['content'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        translationMetadata: json['translation_metadata'] as Map<String, dynamic>?,
        modelVersion: json['model_version'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'role': role.name,
        'content': content,
        'created_at': createdAt.toIso8601String(),
        if (translationMetadata != null) 'translation_metadata': translationMetadata,
        if (modelVersion != null) 'model_version': modelVersion,
      };
}

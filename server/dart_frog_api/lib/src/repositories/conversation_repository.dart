import 'package:shared_models/shared_models.dart';

abstract class ConversationRepository {
  Future<Conversation> create({required String userId, required String title});

  Future<List<Conversation>> listForUser(String userId, {int limit = 50, int offset = 0});

  Future<Conversation?> findById(String id);

  Future<void> delete(String id);

  Future<void> touch(String id);

  Future<ConversationMessage> addMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    Map<String, dynamic>? translationMetadata,
    String? modelVersion,
  });

  Future<List<ConversationMessage>> listMessages(String conversationId, {int limit = 100});
}

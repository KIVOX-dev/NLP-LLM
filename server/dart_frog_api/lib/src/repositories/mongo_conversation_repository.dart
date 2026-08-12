import 'package:mongo_dart/mongo_dart.dart';
import 'package:shared_models/shared_models.dart';
import 'package:uuid/uuid.dart';

import '../db/mongo_client.dart';
import 'conversation_repository.dart';

const _uuid = Uuid();

class MongoConversationRepository implements ConversationRepository {
  MongoConversationRepository(this._mongo);

  final MongoClientService _mongo;

  DbCollection get _conversations => _mongo.collection(Collections.conversations);
  DbCollection get _messages => _mongo.collection(Collections.messages);

  @override
  Future<Conversation> create({required String userId, required String title}) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _conversations.insertOne({
      '_id': id,
      'user_id': userId,
      'title': title,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    return Conversation(id: id, userId: userId, title: title, createdAt: now, updatedAt: now);
  }

  @override
  Future<void> delete(String id) async {
    await _conversations.deleteOne(where.eq('_id', id));
    await _messages.deleteMany(where.eq('conversation_id', id));
  }

  @override
  Future<Conversation?> findById(String id) async {
    final doc = await _conversations.findOne(where.eq('_id', id));
    return doc == null ? null : _toConversation(doc);
  }

  @override
  Future<List<Conversation>> listForUser(String userId, {int limit = 50, int offset = 0}) async {
    final docs = await _conversations
        .find(where.eq('user_id', userId).sortBy('updated_at', descending: true).skip(offset).limit(limit))
        .toList();
    return docs.map(_toConversation).toList();
  }

  @override
  Future<void> touch(String id) async {
    await _conversations.updateOne(
      where.eq('_id', id),
      modify.set('updated_at', DateTime.now().toUtc().toIso8601String()),
    );
  }

  @override
  Future<ConversationMessage> addMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    Map<String, dynamic>? translationMetadata,
    String? modelVersion,
  }) async {
    final now = DateTime.now().toUtc();
    final id = _uuid.v4();
    await _messages.insertOne({
      '_id': id,
      'conversation_id': conversationId,
      'role': role.name,
      'content': content,
      'translation_metadata': translationMetadata,
      'model_version': modelVersion,
      'created_at': now.toIso8601String(),
    });
    await touch(conversationId);
    return ConversationMessage(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: now,
      translationMetadata: translationMetadata,
      modelVersion: modelVersion,
    );
  }

  @override
  Future<List<ConversationMessage>> listMessages(String conversationId, {int limit = 100}) async {
    final docs = await _messages
        .find(where.eq('conversation_id', conversationId).sortBy('created_at').limit(limit))
        .toList();
    return docs
        .map(
          (m) => ConversationMessage(
            id: m['_id'].toString(),
            conversationId: m['conversation_id'] as String,
            role: messageRoleFromString(m['role'] as String),
            content: m['content'] as String,
            createdAt: DateTime.parse(m['created_at'] as String),
            translationMetadata: m['translation_metadata'] as Map<String, dynamic>?,
            modelVersion: m['model_version'] as String?,
          ),
        )
        .toList();
  }

  Conversation _toConversation(Map<String, dynamic> doc) => Conversation(
        id: doc['_id'].toString(),
        userId: doc['user_id'] as String,
        title: doc['title'] as String,
        createdAt: DateTime.parse(doc['created_at'] as String),
        updatedAt: DateTime.parse(doc['updated_at'] as String),
      );
}

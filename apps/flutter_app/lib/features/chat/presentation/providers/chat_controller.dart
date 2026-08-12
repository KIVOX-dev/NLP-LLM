import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../domain/chat_message.dart';

class ChatState {
  const ChatState({this.messages = const [], this.isSending = false});

  final List<ChatMessage> messages;
  final bool isSending;

  ChatState copyWith({List<ChatMessage>? messages, bool? isSending}) => ChatState(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
      );
}

/// Drives the chat screen: sends Sanskrit input to `POST /translate` and
/// renders the structured response (spec §9/§60). One provider per
/// conversation-in-progress; multi-conversation history switching is a
/// follow-up (see docs/BUILD_PHASES.md) — today this always starts fresh.
class ChatController extends StateNotifier<ChatState> {
  ChatController(this._apiClient) : super(const ChatState());

  final ApiClient _apiClient;
  int _idCounter = 0;

  String _nextId() => 'msg-${_idCounter++}-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> sendSanskrit(
    String text, {
    List<TargetLanguage> targets = const [TargetLanguage.english, TargetLanguage.tamil],
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isSending) return;

    final userMessage = ChatMessage(id: _nextId(), role: ChatRole.user, text: trimmed);
    final pendingId = _nextId();
    final pendingMessage = ChatMessage(
      id: pendingId,
      role: ChatRole.assistant,
      text: '',
      status: ChatMessageStatus.sending,
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage, pendingMessage],
      isSending: true,
    );

    try {
      final response = await _apiClient.translate(
        TranslationRequest(text: trimmed, targets: targets),
      );
      _updateMessage(pendingId, (m) => m.copyWith(translation: response, status: ChatMessageStatus.sent));
    } on ApiException catch (e) {
      _updateMessage(pendingId, (m) => m.copyWith(status: ChatMessageStatus.error, errorMessage: e.message));
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  Future<void> regenerate(String assistantMessageId, TranslationRequest originalRequest) async {
    _updateMessage(assistantMessageId, (m) => m.copyWith(status: ChatMessageStatus.sending));
    state = state.copyWith(isSending: true);
    try {
      final response = await _apiClient.translate(originalRequest);
      _updateMessage(
        assistantMessageId,
        (m) => m.copyWith(translation: response, status: ChatMessageStatus.sent),
      );
    } on ApiException catch (e) {
      _updateMessage(
        assistantMessageId,
        (m) => m.copyWith(status: ChatMessageStatus.error, errorMessage: e.message),
      );
    } finally {
      state = state.copyWith(isSending: false);
    }
  }

  void clear() => state = const ChatState();

  void _updateMessage(String id, ChatMessage Function(ChatMessage) update) {
    state = state.copyWith(
      messages: [
        for (final message in state.messages)
          if (message.id == id) update(message) else message,
      ],
    );
  }
}

final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  return ChatController(ref.watch(apiClientProvider));
});

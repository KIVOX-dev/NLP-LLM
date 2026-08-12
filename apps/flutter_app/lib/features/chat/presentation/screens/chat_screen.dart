import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';

import '../../../../core/config/app_config.dart';
import '../../domain/chat_message.dart';
import '../providers/chat_controller.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/sanskrit_input.dart';

/// The main screen: doubles as the landing/home screen (spec §8) when the
/// conversation is empty, and the chat screen (spec §9) once translations
/// start coming in. Desktop keeps the sidebar visible inline (§42); mobile
/// collapses it into a Drawer (§7, §42).
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  static const double _desktopBreakpoint = 900;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= ChatScreen._desktopBreakpoint;

    ref.listen(chatControllerProvider, (previous, next) {
      if (previous == null || next.messages.length != previous.messages.length) {
        _scrollToBottom();
      }
    });

    final content = state.messages.isEmpty ? _EmptyState(onQuickAction: _sendSanskrit) : _MessageList(
            messages: state.messages,
            scrollController: _scrollController,
            onRegenerate: (id, text) => _sendSanskrit(text),
          );

    final body = Column(
      children: [
        Expanded(child: content),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: SanskritInput(enabled: !state.isSending, onSubmit: _sendSanskrit),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(onNewConversation: () => ref.read(chatControllerProvider.notifier).clear()),
            Expanded(
              child: Column(
                children: [
                  _TopBar(showMenuButton: false),
                  Expanded(child: Center(child: SizedBox(width: double.infinity, child: body))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppConfig.appName)),
      drawer: Drawer(
        child: AppSidebar(
          onNewConversation: () {
            ref.read(chatControllerProvider.notifier).clear();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: body,
    );
  }

  void _sendSanskrit(String text) {
    ref.read(chatControllerProvider.notifier).sendSanskrit(
          text,
          targets: const [TargetLanguage.english, TargetLanguage.tamil],
        );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showMenuButton});

  final bool showMenuButton;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (showMenuButton)
            IconButton(icon: const Icon(Icons.menu_rounded), onPressed: () => Scaffold.of(context).openDrawer()),
          Expanded(
            child: Text(AppConfig.appName, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.scrollController, required this.onRegenerate});

  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final void Function(String messageId, String originalText) onRegenerate;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final userText = index > 0 ? messages[index - 1].text : message.text;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ChatMessageBubble(
              message: message,
              onRegenerate: () => onRegenerate(message.id, userText),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onQuickAction});

  final ValueChanged<String> onQuickAction;

  static const _quickActions = <(IconData, String, String)>[
    (Icons.translate_rounded, 'Translate Sanskrit', 'रामः वनं गच्छति।'),
    (Icons.menu_book_outlined, 'Dictionary', 'धर्म'),
    (Icons.account_tree_outlined, 'Grammar Analysis', 'बालकः पुस्तकं पठति।'),
    (Icons.merge_type_rounded, 'Sandhi Analysis', 'रामोऽस्ति'),
    (Icons.record_voice_over_outlined, 'Pronunciation', 'गच्छति'),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Text(AppConfig.appName, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                AppConfig.appTagline,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  for (final action in _quickActions)
                    ActionChip(
                      avatar: Icon(action.$1, size: 18),
                      label: Text(action.$2),
                      onPressed: () => onQuickAction(action.$3),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

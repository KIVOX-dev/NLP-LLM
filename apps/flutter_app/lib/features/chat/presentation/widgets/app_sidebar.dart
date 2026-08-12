import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

/// Conversation history + "new conversation" + search (spec §7). On desktop
/// this is shown inline (§42); on mobile it's wrapped in a Drawer by the
/// caller (§7 "sidebar becomes a drawer").
class AppSidebar extends StatelessWidget {
  const AppSidebar({required this.onNewConversation, this.width = 280, super.key});

  final VoidCallback onNewConversation;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                AppConfig.appName,
                style: Theme.of(context).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton.icon(
                onPressed: onNewConversation,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('New conversation'),
                style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: _SearchField(),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: const [
                  _EmptyHistoryNotice(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
        hintText: 'Search conversations',
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

class _EmptyHistoryNotice extends StatelessWidget {
  const _EmptyHistoryNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Text(
        'Sign in to save and revisit conversation history.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

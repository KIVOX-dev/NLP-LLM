import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/config/app_config.dart';
import 'package:flutter_app/features/chat/presentation/screens/chat_screen.dart';

void main() {
  testWidgets('ChatScreen shows the landing/empty state with quick actions', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ChatScreen()),
      ),
    );

    expect(find.text(AppConfig.appName), findsWidgets);
    expect(find.text(AppConfig.appTagline), findsOneWidget);
    expect(find.text('Translate Sanskrit'), findsOneWidget);
    expect(find.text('Dictionary'), findsOneWidget);
    expect(find.text('Sandhi Analysis'), findsOneWidget);
  });
}

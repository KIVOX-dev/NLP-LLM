import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/screens/chat_screen.dart';

/// Single route today; named routes for dictionary/settings/saved
/// translations are the natural next additions as those screens are built
/// (see docs/BUILD_PHASES.md) — go_router is wired in now so that growth
/// doesn't require a routing migration later.
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ChatScreen()),
  ],
);

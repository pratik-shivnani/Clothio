import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/shell/shell_screen.dart';
import '../../features/wardrobe/presentation/wardrobe_screen.dart';
import '../../features/tryon/presentation/tryon_screen.dart';
import '../../features/suggestions/presentation/suggestions_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/wardrobe/presentation/add_clothing_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/wardrobe',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/wardrobe',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WardrobeScreen(),
            ),
          ),
          GoRoute(
            path: '/tryon',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TryOnScreen(),
            ),
          ),
          GoRoute(
            path: '/suggestions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SuggestionsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/wardrobe/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddClothingScreen(),
      ),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'screens/album_detail_screen.dart';
import 'screens/category_screen.dart';
import 'screens/help_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/main_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/search_screen.dart';
import 'screens/server_gate.dart';
import 'screens/server_selection_screen.dart';
import 'models/reader_initial_data.dart';

CustomTransitionPage<void> _buildPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final disableAnimations = MediaQuery.of(context).disableAnimations;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (disableAnimations) return child;
      final curve = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutQuad,
      );
      final fade = FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
        child: child,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(curve),
        child: fade,
      );
    },
  );
}

final router = GoRouter(
  initialLocation: '/gate',
  routes: [
    GoRoute(
      path: '/gate',
      pageBuilder: (context, state) =>
          _buildPage(context: context, state: state, child: const ServerGate()),
    ),
    GoRoute(
      path: '/server',
      redirect: (context, state) => kIsWeb ? '/gate' : null,
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: const ServerSelectionScreen(),
      ),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        final subTab = state.uri.queryParameters['subTab'];
        var libraryTab = 0;
        final initialIndex = switch (tab) {
          'home' => 0,
          'rankings' => 1,
          'library' => () {
            if (subTab == 'recent') {
              libraryTab = 1;
            }
            return 2;
          }(),
          'settings' => 3,
          _ => 0,
        };
        return _buildPage(
          context: context,
          state: state,
          child: MainScreen(initialIndex: initialIndex, libraryTab: libraryTab),
        );
      },
    ),
    GoRoute(
      path: '/search',
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: SearchScreen(initialQuery: state.uri.queryParameters['q']),
      ),
    ),
    GoRoute(
      path: '/album/:albumId',
      pageBuilder: (context, state) {
        final albumId = state.pathParameters['albumId']!;
        return _buildPage(
          context: context,
          state: state,
          child: AlbumDetailScreen(albumId: albumId),
        );
      },
    ),
    GoRoute(
      path: '/category/:category',
      pageBuilder: (context, state) {
        final category = state.pathParameters['category']!;
        return _buildPage(
          context: context,
          state: state,
          child: CategoryScreen(category: category),
        );
      },
    ),
    GoRoute(
      path: '/reader/:photoId',
      pageBuilder: (context, state) {
        final photoId = state.pathParameters['photoId']!;
        final initialData = state.extra is ReaderInitialData
            ? state.extra as ReaderInitialData
            : null;
        return _buildPage(
          context: context,
          state: state,
          child: ReaderScreen(photoId: photoId, initialData: initialData),
        );
      },
    ),
    GoRoute(
      path: '/logs',
      redirect: (context, state) => kIsWeb ? '/' : null,
      pageBuilder: (context, state) =>
          _buildPage(context: context, state: state, child: const LogsScreen()),
    ),
    GoRoute(
      path: '/help',
      pageBuilder: (context, state) =>
          _buildPage(context: context, state: state, child: const HelpScreen()),
    ),
  ],
);

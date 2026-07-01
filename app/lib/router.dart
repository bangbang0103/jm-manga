import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/album_detail_screen.dart';
import 'screens/cache_screen.dart';
import 'screens/category_screen.dart';
import 'screens/custom_domain_settings_screen.dart';
import 'screens/excluded_tags_settings_screen.dart';
import 'screens/faq_screen.dart';
import 'screens/logs_screen.dart';
import 'screens/main_screen.dart';
import 'screens/proxy_settings_screen.dart';
import 'screens/reader_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_advanced_screen.dart';
import 'models/reader_initial_data.dart';

CustomTransitionPage<void> _buildPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  final disableAnimations = MediaQuery.of(context).disableAnimations;
  final theme = Theme.of(context);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (disableAnimations) return child;
      return FadeThroughTransition(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        fillColor: theme.colorScheme.surface,
        child: child,
      );
    },
  );
}

final router = GoRouter(
  initialLocation: '/',
  routes: [
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
      pageBuilder: (context, state) =>
          _buildPage(context: context, state: state, child: const LogsScreen()),
    ),
    GoRoute(
      path: '/cache',
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: const CacheScreen(),
      ),
    ),
    GoRoute(
      path: '/proxy',
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: const ProxySettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/custom-domain',
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: const CustomDomainSettingsScreen(),
      ),
    ),
    GoRoute(
      path: '/faq',
      pageBuilder: (context, state) =>
          _buildPage(context: context, state: state, child: const FaqScreen()),
    ),
    GoRoute(
      path: '/settings/advanced',
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: const SettingsAdvancedScreen(),
      ),
    ),
    GoRoute(
      path: '/settings/excluded-tags',
      pageBuilder: (context, state) => _buildPage(
        context: context,
        state: state,
        child: const ExcludedTagsSettingsScreen(),
      ),
    ),
  ],
);

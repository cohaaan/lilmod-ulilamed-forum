import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/chavrusa_listing.dart';
import '../models/seforim.dart';
import '../screens/account_screen.dart';
import '../screens/article_detail_screen.dart';
import '../screens/articles_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/chavrusas/chavrusa_form_screen.dart';
import '../screens/chavrusas/chavrusas_screen.dart';
import '../screens/category_screen.dart';
import '../screens/forums_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/seforim/seforim_book_screen.dart';
import '../screens/seforim/seforim_browse_screen.dart';
import '../screens/seforim/seforim_category_screen.dart';
import '../screens/seforim/seforim_reader_screen.dart';
import '../screens/seforim/seforim_search_screen.dart';
import '../screens/subforum_screen.dart';
import '../screens/theme_preview_screen.dart';
import '../screens/thread_detail_screen.dart';
import '../widgets/scaffold_with_nav_bar.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: AppConfig.defaultSignedInRoute,
  navigatorKey: _rootKey,
  refreshListenable:
      _GoRouterRefreshStream(Supabase.instance.client.auth.onAuthStateChange),
  redirect: (context, state) {
    final signedIn = Supabase.instance.client.auth.currentUser != null;
    final atLogin = state.matchedLocation == '/login';
    final home = AppConfig.defaultSignedInRoute;
    if (!signedIn) return atLogin ? null : '/login';
    if (atLogin) return home;
    if (AppConfig.isChavrusasSite && state.matchedLocation == '/') {
      return '/chavrusas';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    // Source links inside posts open the reader full-screen over whatever tab
    // the reader is on (root navigator), so it works from a thread in the
    // Forums branch as well as from within Seforim.
    GoRoute(
      path: '/source/:ref',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => SeforimReaderScreen(
        reference: state.pathParameters['ref']!,
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          ScaffoldWithNavBar(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/forums',
              builder: (context, state) => const ForumsScreen(),
              routes: [
                GoRoute(
                  path: 'c/:catId',
                  builder: (context, state) => CategoryScreen(
                    categoryId: state.pathParameters['catId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 's/:subId',
                      builder: (context, state) => SubforumScreen(
                        categoryId: state.pathParameters['catId']!,
                        subforumId: state.pathParameters['subId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Thread detail lives in the Forums branch (not a root modal) so the
            // bottom bar stays visible and the live reply survives a tab switch
            // to Seforim and back.
            GoRoute(
              path: '/threads/:id',
              builder: (context, state) =>
                  ThreadDetailScreen(threadId: state.pathParameters['id']!),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/seforim',
              builder: (context, state) => const SeforimBrowseScreen(),
              routes: [
                GoRoute(
                  path: 'c/:name',
                  builder: (context, state) => SeforimCategoryScreen(
                    label: state.pathParameters['name']!,
                    node: state.extra as SeforimNode?,
                  ),
                ),
                GoRoute(
                  path: 'book/:title',
                  builder: (context, state) => SeforimBookScreen(
                    title: state.pathParameters['title']!,
                    node: state.extra as SeforimNode?,
                  ),
                ),
                GoRoute(
                  path: 'read/:ref',
                  builder: (context, state) => SeforimReaderScreen(
                    reference: state.pathParameters['ref']!,
                  ),
                ),
                GoRoute(
                  path: 'search',
                  builder: (context, state) => const SeforimSearchScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/articles',
              builder: (context, state) => const ArticlesScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/articles/:slug',
      parentNavigatorKey: _rootKey,
      builder: (context, state) =>
          ArticleDetailScreen(slug: state.pathParameters['slug']!),
    ),
    GoRoute(
      path: '/account',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/theme-preview',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const ThemePreviewScreen(),
    ),
    GoRoute(
      path: '/chavrusas',
      parentNavigatorKey: _rootKey,
      builder: (context, state) => const ChavrusasScreen(),
      routes: [
        GoRoute(
          path: 'edit',
          parentNavigatorKey: _rootKey,
          builder: (context, state) => ChavrusaFormScreen(
            existing: state.extra as ChavrusaListing?,
          ),
        ),
      ],
    ),
  ],
);

/// Bridges a Stream into a Listenable so GoRouter re-evaluates redirects
/// whenever auth state changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

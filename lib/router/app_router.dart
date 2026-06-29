import 'package:go_router/go_router.dart';

import '../screens/article_detail_screen.dart';
import '../screens/articles_screen.dart';
import '../screens/forums_screen.dart';
import '../screens/home_screen.dart';
import '../screens/search_screen.dart';
import '../screens/thread_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/forums', builder: (context, state) => const ForumsScreen()),
    GoRoute(
      path: '/articles',
      builder: (context, state) => const ArticlesScreen(),
    ),
    GoRoute(path: '/search', builder: (context, state) => const SearchScreen()),
    GoRoute(
      path: '/threads/:id',
      builder: (context, state) =>
          ThreadDetailScreen(threadId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/articles/:slug',
      builder: (context, state) =>
          ArticleDetailScreen(slug: state.pathParameters['slug']!),
    ),
  ],
);

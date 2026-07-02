// Throwaway visual-QA entrypoint: just the Seforim flow against the live
// Sefaria API, with no Supabase/auth. Not part of the app.
//   flutter run -d web-server --target=lib/preview_seforim_main.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/seforim.dart';
import 'screens/seforim/seforim_book_screen.dart';
import 'screens/seforim/seforim_browse_screen.dart';
import 'screens/seforim/seforim_category_screen.dart';
import 'screens/seforim/seforim_reader_screen.dart';
import 'screens/seforim/seforim_search_screen.dart';

void main() {
  final router = GoRouter(
    initialLocation: '/seforim',
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
  );
  runApp(MaterialApp.router(
    debugShowCheckedModeBanner: false,
    routerConfig: router,
  ));
}

import 'package:flutter/material.dart';

import 'data/mock_data.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LilmodUlilamedApp());
}

class LilmodUlilamedApp extends StatelessWidget {
  const LilmodUlilamedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: MockData.siteName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/design_direction_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  await designDirectionController.load();
  runApp(const LilmodUlilamedApp());
}

class LilmodUlilamedApp extends StatefulWidget {
  const LilmodUlilamedApp({super.key});

  @override
  State<LilmodUlilamedApp> createState() => _LilmodUlilamedAppState();
}

class _LilmodUlilamedAppState extends State<LilmodUlilamedApp> {
  @override
  void initState() {
    super.initState();
    designDirectionController.addListener(_onDirectionChanged);
  }

  @override
  void dispose() {
    designDirectionController.removeListener(_onDirectionChanged);
    super.dispose();
  }

  void _onDirectionChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final direction = designDirectionController.active;
    return MaterialApp.router(
      title: 'Lilmod Ulilamed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.fromDirection(direction),
      routerConfig: appRouter,
    );
  }
}

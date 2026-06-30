import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'data/chavrusa_access.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/design_direction_controller.dart';
import 'utils/oauth_callback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
    // We exchange the OAuth/PKCE code manually below (single code path). Without
    // this, the built-in URL detector races that manual exchange for the same
    // one-time code; the loser fails and pushes an error onto onAuthStateChange,
    // which (unhandled) crashes the app on boot when a ?code= is present.
    authOptions: const FlutterAuthClientOptions(detectSessionInUri: false),
  );
  if (kIsWeb && isOAuthCallbackUri(Uri.base)) {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession == null) {
      try {
        await auth.getSessionFromUrl(Uri.base);
      } on AuthException {
        // Code already spent, PKCE mismatch, or other one-shot failure.
      }
    }
    // Supabase only clears the URL after a successful exchange; always strip
    // auth params so refresh does not retry a spent ?code= and break routing.
    clearOAuthParamsFromBrowserUrl();
  }
  Supabase.instance.client.auth.onAuthStateChange.listen(
    (data) {
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut) {
        ChavrusaAccess.invalidate();
      }
    },
    // Auth stream errors (e.g. a failed token refresh) must not become uncaught
    // zone errors that crash boot. Swallow and re-evaluate access.
    onError: (Object _) => ChavrusaAccess.invalidate(),
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

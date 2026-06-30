import 'package:flutter/foundation.dart';

/// App-wide runtime configuration (compile-time overrides via --dart-define).
abstract final class AppConfig {
  /// Canonical public URL for shareable deep links.
  ///
  /// Override at build time: `--dart-define=SITE_URL=https://forum.example.com`
  static const siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: 'https://lilmod-ulilamed.vercel.app',
  );

  /// Chavrusa directory subdomain (e.g. chavrusas.lilmodulilamed.com).
  static bool get isChavrusasSite {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host.startsWith('chavrusas.');
  }

  /// Where signed-in users land — chavrusas board on its subdomain, home elsewhere.
  static String get defaultSignedInRoute =>
      isChavrusasSite ? '/chavrusas' : '/';
}

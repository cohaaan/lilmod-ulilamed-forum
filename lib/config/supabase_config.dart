/// Supabase project connection details for Lilmod Ulilamed.
///
/// The publishable key is safe to ship in a client app — all access is
/// governed by Row-Level Security policies in the database.
abstract final class SupabaseConfig {
  static const url = 'https://lxcbaortmbhjsthycdkt.supabase.co';
  static const publishableKey = 'sb_publishable_BZinY_fUSJElilxipsNplA_T7y_a4i3';

  /// Deep-link scheme used for OAuth redirects (Google sign-in).
  static const redirectScheme = 'app.lilmodulilamed';
  static const oauthRedirect = '$redirectScheme://login-callback';
}

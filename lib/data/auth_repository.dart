import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../config/supabase_config.dart';

/// Thin wrapper over Supabase Auth.
class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Returns the AuthResponse so callers can detect whether email
  /// confirmation is required (session == null).
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': displayName, 'name': displayName},
    );
  }

  Future<void> signInWithGoogle() async {
    // Web uses the PKCE flow: Google returns to this origin with `?code=...` in
    // the query, which Supabase exchanges for a session (detectSessionInUri).
    // Redirect to the bare origin only — appending a path/#fragment, or an origin
    // not in Supabase's Redirect URL allow-list, breaks the callback. The allow-
    // list must include this exact origin (e.g. https://chavrusas.lilmodulilamed.com).
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb
          ? AppConfig.webOAuthRedirectOrigin
          : SupabaseConfig.oauthRedirect,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

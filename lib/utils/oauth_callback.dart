import 'oauth_callback_platform_stub.dart'
    if (dart.library.js_interop) 'oauth_callback_platform_web.dart';

/// Whether [uri] is a Supabase OAuth / magic-link callback.
bool isOAuthCallbackUri(Uri uri) {
  final fragmentParameters = Uri.splitQueryString(uri.fragment);
  bool has(String key) =>
      uri.queryParameters.containsKey(key) ||
      fragmentParameters.containsKey(key);

  return has('code') ||
      has('access_token') ||
      has('error') ||
      has('error_code') ||
      has('error_description');
}

/// Strip spent OAuth query/fragment params so refresh does not re-exchange.
void clearOAuthParamsFromBrowserUrl() => clearOAuthParamsPlatform();

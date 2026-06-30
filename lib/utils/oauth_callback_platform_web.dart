import 'package:web/web.dart' as web;

const _authParameters = {
  'code',
  'access_token',
  'expires_in',
  'expires_at',
  'refresh_token',
  'token_type',
  'provider_token',
  'provider_refresh_token',
  'error',
  'error_code',
  'error_description',
  'type',
};

void clearOAuthParamsPlatform() {
  final currentUri = Uri.parse(web.window.location.href);

  final query = Map<String, String>.of(currentUri.queryParameters)
    ..removeWhere((key, value) => _authParameters.contains(key));

  final fragmentParameters =
      Map<String, String>.of(Uri.splitQueryString(currentUri.fragment))
        ..removeWhere((key, value) => _authParameters.contains(key));

  final fragment = fragmentParameters.isEmpty
      ? null
      : Uri(queryParameters: fragmentParameters).query;

  final cleanedUri = Uri(
    scheme: currentUri.scheme,
    userInfo: currentUri.userInfo,
    host: currentUri.host,
    port: currentUri.hasPort ? currentUri.port : null,
    path: currentUri.path,
    queryParameters: query.isEmpty ? null : query,
    fragment: fragment,
  );

  web.window.history.replaceState(null, '', cleanedUri.toString());
}

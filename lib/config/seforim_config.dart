/// Configuration for the Seforim (Sefaria) integration.
///
/// We build our own UI on top of Sefaria's free public API. We do NOT copy
/// their GPL-3.0 frontend code. Texts are mostly public domain / CC — the API
/// returns a `license` per version which we surface as attribution. The name
/// "Sefaria" and its logo are trademarked, so the in-app tab is called
/// "Seforim" and we attribute the source/publisher, not the platform.
abstract final class SeforimConfig {
  /// Base URL for the Sefaria HTTP API.
  static const apiBase = 'https://www.sefaria.org';

  /// Canonical web URL for a reference, used for "open on the web" links and
  /// attribution in pasted source blocks. Refs use underscores for spaces.
  static String webUrl(String ref) =>
      '$apiBase/${Uri.encodeFull(ref.replaceAll(' ', '_'))}';

  /// Network timeout for API calls.
  static const timeout = Duration(seconds: 20);
}

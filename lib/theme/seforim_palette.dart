import 'package:flutter/material.dart';

/// Sefaria-style category colours, re-created for the Seforim browser so the
/// library reads colour-coded by corpus like Sefaria does. These are our own
/// constant values — no Sefaria code or assets are used.
abstract final class SeforimPalette {
  static const _byCategory = <String, Color>{
    'Tanakh': Color(0xFF004E5F),
    'Mishnah': Color(0xFF5A99B7),
    'Talmud': Color(0xFFCCB479),
    'Midrash': Color(0xFF5D956F),
    'Halakhah': Color(0xFF802022),
    'Kabbalah': Color(0xFF594176),
    'Liturgy': Color(0xFFAB4E66),
    'Jewish Thought': Color(0xFF7F85A9),
    'Tosefta': Color(0xFF00827F),
    'Chasidut': Color(0xFF97B386),
    'Musar': Color(0xFF7C406F),
    'Responsa': Color(0xFFCB6158),
    'Reference': Color(0xFF4B71B7),
    'Second Temple': Color(0xFF757575),
    'Commentary': Color(0xFF4B71B7),
    'Targum': Color(0xFF7B6857),
  };

  /// Neutral fallback for any corpus we don't have a colour for.
  static const fallback = Color(0xFF4B71B7);

  static Color forCategory(String? category) =>
      _byCategory[category] ?? fallback;
}

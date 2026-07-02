import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sefaria-style category colours for the Seforim browser, so the library
/// reads colour-coded by corpus like Sefaria does. Colour values were measured
/// from the rendered site (computed styles) — they are plain facts re-declared
/// as our own constants; no Sefaria code or assets are used.
abstract final class SeforimPalette {
  static const _byCategory = <String, Color>{
    'Tanakh': Color(0xFF004E5F),
    'Mishnah': Color(0xFF5A99B7),
    'Talmud': Color(0xFFCCB479),
    'Midrash': Color(0xFF5D956F),
    'Halakhah': Color(0xFF802F3E),
    'Kabbalah': Color(0xFF594176),
    'Liturgy': Color(0xFFAB4E66),
    'Jewish Thought': Color(0xFF7F85A9),
    'Tosefta': Color(0xFF00827F),
    'Chasidut': Color(0xFF97B386),
    'Musar': Color(0xFF7C416F),
    'Responsa': Color(0xFFCB6158),
    'Reference': Color(0xFFD4886C),
    'Second Temple': Color(0xFFC6A7B4),
    'Commentary': Color(0xFF4871BF),
    'Targum': Color(0xFF7B6857),
  };

  /// Neutral fallback for any corpus we don't have a colour for.
  static const fallback = Color(0xFF7F85A9);

  static Color forCategory(String? category) =>
      _byCategory[category] ?? fallback;

  // --- Neutrals (measured from Sefaria's reader) ---------------------------

  /// The reading/browse page background — plain white, like Sefaria's reader.
  static const paper = Color(0xFFFFFFFF);

  /// Background of the currently-selected verse — Sefaria's pale-blue
  /// segment highlight.
  static const paperSelected = Color(0xFFEDF4FA);

  /// Hairline separators on the page.
  static const paperLine = Color(0xFFEDEDEC);

  /// Faint off-white used for secondary panes: chapter-grid boxes, panel
  /// bands, commentator tiles.
  static const faint = Color(0xFFFBFBFA);

  /// Primary text — Sefaria sets titles and Hebrew in full black.
  static const black = Color(0xFF000000);

  /// Secondary text: descriptions, English translation, section links.
  static const secondary = Color(0xFF666666);

  /// Tertiary text: fine print, counts, small caps labels.
  static const tertiary = Color(0xFF999999);

  /// Sefaria's action navy ("Start Reading" button).
  static const navy = Color(0xFF18345D);
}

/// The three Sefaria text voices, mapped to freely-licensed faces:
/// - English serif: Cardo (the same OFL face Sefaria loads first for English).
/// - Hebrew: Taamey Frank CLM (Culmus; bundled — see assets/fonts).
/// - UI sans: Roboto.
abstract final class SeforimText {
  /// English serif — titles, English text, refs.
  static TextStyle serif({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.cardo(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Hebrew text — Taamey Frank with the bundled Noto fallback.
  static TextStyle hebrew({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: 'TaameyFrank',
    fontFamilyFallback: const ['NotoSansHebrew'],
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// UI sans — descriptions, labels, buttons.
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) => GoogleFonts.roboto(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    decoration: decoration,
  );
}

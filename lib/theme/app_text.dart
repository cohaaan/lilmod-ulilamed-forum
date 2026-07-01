import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'design_direction.dart';

/// Typography tokens — a small, fixed scale of semantic roles.
///
/// Use these instead of ad-hoc font calls so the app has one consistent type
/// ramp. Font family follows the active [DesignDirection].
abstract final class AppText {
  /// Locally-bundled Hebrew face (see `pubspec.yaml` fonts). Applied as a
  /// `fontFamilyFallback` on every style so Hebrew glyphs resolve from a font
  /// that's present at first paint — the Latin app fonts (Inter/Lato/…) have no
  /// Hebrew glyphs, and without a bundled fallback CanvasKit paints `.notdef`
  /// bars for each Hebrew letter until it fetches a Noto face over the network.
  static const String hebrewFallback = 'NotoSansHebrew';

  static const List<String> _hebrew = [hebrewFallback];

  static DesignTypography _typography = DesignTypography.inter;

  static void apply(DesignDirection direction) {
    _typography = direction.typography;
    _brutalist = direction.useBrutalistChrome;
  }

  static bool _brutalist = false;

  /// Screen titles ("Forums", "Lilmod Ulilamed").
  static TextStyle get display => _sans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: -0.3,
        color: AppColors.ink,
      );

  /// A thread title / opening-post headline.
  static TextStyle get title => _sans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: AppColors.ink,
      );

  /// Section headers ("Latest discussions").
  static TextStyle get section => _sans(
        fontSize: 17,
        fontWeight: _brutalist ? FontWeight.w800 : FontWeight.w700,
        letterSpacing: _brutalist ? -0.2 : null,
        color: AppColors.ink,
      );

  /// The title line of a list row (thread / forum row).
  static TextStyle get rowTitle => _sans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.ink,
      );

  /// Long-form reading text — opening posts, where line length is generous.
  static TextStyle get reading => _sans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.body,
      );

  /// Default body text — replies, descriptions.
  static TextStyle get body => _sans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.body,
      );

  /// Emphasised metadata — author names, button labels.
  static TextStyle get label => _sans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.body,
      );

  /// Secondary metadata — timestamps, counts.
  static TextStyle get caption => _sans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.muted,
      );

  /// Drop-in for `GoogleFonts.inter(...)` that carries the bundled Hebrew
  /// fallback. Use this anywhere ad-hoc Inter text may contain Hebrew so it
  /// never flashes `.notdef` bars while a network Noto face loads.
  static TextStyle inter({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
        decoration: decoration,
      ).copyWith(fontFamilyFallback: _hebrew);

  /// Ad-hoc sans text matching the active design direction.
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) =>
      _sans(
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight ?? FontWeight.w400,
        color: color ?? AppColors.body,
        height: height,
        letterSpacing: letterSpacing,
        fontStyle: fontStyle,
      );

  static TextStyle _sans({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) {
    switch (_typography) {
      case DesignTypography.lato:
        return GoogleFonts.lato(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        ).copyWith(fontFamilyFallback: _hebrew);
      case DesignTypography.serif:
        return GoogleFonts.sourceSerif4(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        ).copyWith(fontFamilyFallback: _hebrew);
      case DesignTypography.mono:
        return GoogleFonts.ibmPlexSans(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        ).copyWith(fontFamilyFallback: _hebrew);
      case DesignTypography.system:
        return TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
          fontFamilyFallback: _hebrew,
        );
      case DesignTypography.inter:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
          fontStyle: fontStyle,
        ).copyWith(fontFamilyFallback: _hebrew);
    }
  }
}

/// Spacing tokens on an 8pt grid (4 for micro-adjustments).
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Standard horizontal screen padding.
  static const double gutter = 20;
}

/// Corner-radius tokens — follow active design direction via [AppColors.cardRadius].
abstract final class AppRadius {
  static double get sm => AppColors.cardRadius <= 4 ? 4 : 4;
  static double get md => AppColors.cardRadius;
  static double get lg => AppColors.cardRadius + 2;
}

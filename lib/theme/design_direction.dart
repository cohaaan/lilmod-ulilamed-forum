import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Visual tokens for one enterprise-grade design direction.
class DesignDirection {
  const DesignDirection({
    required this.id,
    required this.name,
    required this.concept,
    required this.evokes,
    required this.primary,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.body,
    required this.muted,
    required this.border,
    required this.accent,
    required this.cornerRadius,
    required this.density,
    required this.useShadow,
    required this.useBorder,
    required this.pillTags,
    required this.navStyle,
    required this.typography,
    required this.isDark,
    this.useBrutalistChrome = false,
  });

  final String id;
  final String name;
  final String concept;
  final String evokes;

  final Color primary;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color ink;
  final Color body;
  final Color muted;
  final Color border;
  final Color accent;

  /// Corner radius for cards and inputs (px).
  final double cornerRadius;

  /// 0.85 = compact, 1.0 = default, 1.15 = airy.
  final double density;

  final bool useShadow;
  final bool useBorder;
  final bool pillTags;
  final DesignNavStyle navStyle;
  final DesignTypography typography;
  final bool isDark;

  /// Square cards, accent borders, offset-shadow buttons (Chavrusa directory).
  final bool useBrutalistChrome;

  TextStyle titleStyle({double size = 13, FontWeight weight = FontWeight.w600}) {
    return _baseFont(
      size: size,
      weight: weight,
      color: ink,
      height: 1.3,
    );
  }

  TextStyle bodyStyle({double size = 11, FontWeight weight = FontWeight.w400}) {
    return _baseFont(
      size: size,
      weight: weight,
      color: body,
      height: 1.45,
    );
  }

  TextStyle captionStyle({double size = 9.5}) {
    return _baseFont(
      size: size,
      weight: FontWeight.w400,
      color: muted,
      height: 1.3,
    );
  }

  TextStyle _baseFont({
    required double size,
    required FontWeight weight,
    required Color color,
    required double height,
  }) {
    switch (typography) {
      case DesignTypography.inter:
        return GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case DesignTypography.serif:
        return GoogleFonts.sourceSerif4(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case DesignTypography.mono:
        return GoogleFonts.ibmPlexSans(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case DesignTypography.lato:
        return GoogleFonts.lato(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
      case DesignTypography.system:
        return TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
        );
    }
  }

  BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: BorderRadius.circular(cornerRadius),
      border: useBorder ? Border.all(color: border) : null,
      boxShadow: useShadow
          ? [
              BoxShadow(
                color: ink.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
          : null,
    );
  }
}

enum DesignNavStyle {
  flatBorder,
  elevated,
  filled,
  underline,
  darkBar,
}

enum DesignTypography {
  inter,
  lato,
  serif,
  mono,
  system,
}

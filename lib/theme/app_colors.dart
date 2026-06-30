import 'package:flutter/material.dart';

import 'design_direction.dart';
import 'design_directions.dart';

/// Active palette — defaults to Discourse Minimal; swap via [apply].
abstract final class AppColors {
  static Color background = const Color(0xFFFAFAFA);
  static Color surface = const Color(0xFFFFFFFF);
  static Color surfaceMuted = const Color(0xFFF4F4F5);

  static Color primary = const Color(0xFF2563EB);
  static Color primaryDark = const Color(0xFF1D4ED8);
  static Color primaryLight = const Color(0xFF3B82F6);
  static Color primarySoft = const Color(0x1A2563EB);

  static Color ink = const Color(0xFF18181B);
  static Color body = const Color(0xFF3F3F46);
  static Color muted = const Color(0xFF71717A);

  static Color line = const Color(0xFFE4E4E7);
  static Color like = const Color(0xFFDC2626);
  static Color mint = const Color(0xFF16A34A);
  static Color gold = const Color(0xFFB45309);

  /// Inline / action links — accent in Slack, primary elsewhere.
  static Color link = primary;

  /// Slack-style aubergine workspace banner on main tabs.
  static bool useAubergineHeader = false;

  /// Pill-shaped category tags (Slack channel pills).
  static bool usePillTags = false;

  /// Chavrusa-style square cards, accent borders, brutalist buttons.
  static bool useBrutalistChrome = false;

  static Color softLine = const Color(0xFFD9E0E8);
  static Color shadow = const Color(0xFF17202B);
  static Color statusGreen = const Color(0xFF087A45);

  static double cardRadius = 8;

  static Color navy = ink;

  static Color soft(Color accent) => accent.withValues(alpha: 0.10);

  static List<Color> accents = const [
    Color(0xFF2563EB),
    Color(0xFF1D4ED8),
    Color(0xFF475569),
    Color(0xFF64748B),
    Color(0xFF334155),
  ];

  static Color accentAt(int i) => accents[i % accents.length];

  /// Legacy aliases — prefer [primary] in new code.
  static Color get indigo => primary;
  static Color get indigoDark => primaryDark;
  static Color get indigoLight => primaryLight;

  static void apply(DesignDirection direction) {
    background = direction.background;
    surface = direction.surface;
    surfaceMuted = direction.surfaceMuted;
    primary = direction.primary;
    ink = direction.ink;
    body = direction.body;
    muted = direction.muted;
    line = direction.border;
    link = direction.accent;
    useAubergineHeader = direction.id == DesignDirections.slackWorkspace.id;
    usePillTags = direction.pillTags;
    useBrutalistChrome = direction.useBrutalistChrome;
    cardRadius = direction.cornerRadius;

    if (direction.id == DesignDirections.chavrusaDirectory.id) {
      primaryDark = const Color(0xFF0D3977);
      primaryLight = const Color(0xFF1A6FD4);
      primarySoft = const Color(0x141458B0);
      mint = statusGreen;
      softLine = const Color(0xFFD9E0E8);
      shadow = const Color(0xFF17202B);
      accents = const [
        Color(0xFF1458B0),
        Color(0xFF0D3977),
        Color(0xFF087A45),
        Color(0xFF68707D),
        Color(0xFF14171C),
      ];
    } else if (direction.id == DesignDirections.slackWorkspace.id) {
      primaryDark = const Color(0xFF611F69);
      primaryLight = const Color(0xFF7C3085);
      primarySoft = const Color(0x334A154B);
      mint = const Color(0xFF2EB67D);
      accents = const [
        Color(0xFF1264A3),
        Color(0xFF2EB67D),
        Color(0xFF611F69),
        Color(0xFFECB22E),
        Color(0xFF4A154B),
      ];
    } else if (direction.id == DesignDirections.discourseMinimal.id) {
      _resetDiscourse();
    } else {
      primaryDark = _darken(direction.primary, 0.12);
      primaryLight = _lighten(direction.primary, 0.08);
      primarySoft = direction.primary.withValues(alpha: 0.10);
      mint = const Color(0xFF16A34A);
      accents = [
        direction.primary,
        direction.accent,
        direction.ink,
        direction.muted,
        direction.body,
      ];
    }
    navy = ink;
  }

  static void _resetDiscourse() {
    primaryDark = const Color(0xFF1D4ED8);
    primaryLight = const Color(0xFF3B82F6);
    primarySoft = const Color(0x1A2563EB);
    mint = const Color(0xFF16A34A);
    accents = const [
      Color(0xFF2563EB),
      Color(0xFF1D4ED8),
      Color(0xFF475569),
      Color(0xFF64748B),
      Color(0xFF334155),
    ];
  }

  static Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color _lighten(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
}

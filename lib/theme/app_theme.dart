import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text.dart';
import 'design_direction.dart';
import 'design_directions.dart';

abstract final class AppTheme {
  static ThemeData get light => fromDirection(DesignDirections.chavrusaDirectory);

  static ThemeData fromDirection(DesignDirection direction) {
    AppColors.apply(direction);
    AppText.apply(direction);

    final sans = _textTheme(direction);
    // Bundled locally (see pubspec + AppText.hebrewFallback) — do NOT use
    // GoogleFonts.notoSansHebrew() here: that fetches over the network, which is
    // exactly what makes Hebrew flash as `.notdef` bars on first load.
    const hebrewFamily = AppText.hebrewFallback;
    final isSlack = direction.id == DesignDirections.slackWorkspace.id;
    final isBrutalist = direction.useBrutalistChrome;
    final radius = direction.cornerRadius;
    final tagRadius = direction.pillTags ? 999.0 : 4.0;

    return ThemeData(
      useMaterial3: true,
      brightness: direction.isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme(
        brightness: direction.isDark ? Brightness.dark : Brightness.light,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primaryLight,
        onSecondary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        outline: AppColors.line,
        error: const Color(0xFFE01E5A),
        onError: Colors.white,
      ),
      textTheme: sans
          .copyWith(
            headlineMedium: sans.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
            headlineSmall: sans.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            titleLarge: sans.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            titleMedium: sans.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            bodyLarge: sans.bodyLarge?.copyWith(color: AppColors.body),
            bodyMedium: sans.bodyMedium?.copyWith(color: AppColors.body),
            bodySmall: sans.bodySmall?.copyWith(color: AppColors.muted),
            labelSmall: sans.labelSmall?.copyWith(color: AppColors.muted),
          )
          .apply(
            bodyColor: AppColors.body,
            displayColor: AppColors.ink,
            fontFamilyFallback: const [hebrewFamily],
          ),
      dividerColor: AppColors.line,
      appBarTheme: AppBarTheme(
        backgroundColor: isSlack ? AppColors.primary : AppColors.background,
        foregroundColor: isSlack ? Colors.white : AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppText.section.copyWith(
          color: isSlack ? Colors.white : AppColors.ink,
        ),
        iconTheme: IconThemeData(
          color: isSlack ? Colors.white : AppColors.ink,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: direction.useBorder
              ? BorderSide(
                  color: isBrutalist ? AppColors.primary : AppColors.line,
                )
              : BorderSide.none,
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: AppText.sans(color: AppColors.muted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(
            color: isSlack ? AppColors.link : AppColors.primary,
            width: isBrutalist ? 2 : 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSlack ? const Color(0xFF007A5A) : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: isBrutalist ? AppColors.shadow : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: isBrutalist
                ? BorderSide(color: AppColors.line)
                : BorderSide.none,
          ),
          textStyle: AppText.sans(
            fontWeight: isBrutalist ? FontWeight.w800 : FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.link,
          textStyle: AppText.sans(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceMuted,
        side: BorderSide(color: AppColors.line),
        labelStyle: AppText.sans(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: AppColors.body,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(tagRadius),
        ),
      ),
    );
  }

  static TextTheme _textTheme(DesignDirection direction) {
    return switch (direction.typography) {
      DesignTypography.lato => GoogleFonts.latoTextTheme(),
      DesignTypography.serif => GoogleFonts.sourceSerif4TextTheme(),
      DesignTypography.mono => GoogleFonts.ibmPlexSansTextTheme(),
      DesignTypography.system => ThemeData.light().textTheme,
      DesignTypography.inter => GoogleFonts.interTextTheme(),
    };
  }
}

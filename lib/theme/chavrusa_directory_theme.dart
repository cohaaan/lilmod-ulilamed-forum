import 'package:flutter/material.dart';

/// Visual tokens for the desktop chavrusa directory (matches site mockup).
abstract final class ChavrusaDirectoryTheme {
  static const ink = Color(0xFF14171C);
  static const muted = Color(0xFF68707D);
  static const line = Color(0xFF1C2430);
  static const soft = Color(0xFFD9E0E8);
  static const blue = Color(0xFF1458B0);
  static const blueDark = Color(0xFF0D3977);
  static const green = Color(0xFF087A45);
  static const shadow = Color(0xFF17202B);

  static const headerHeight = 104.0;
  static const sidebarWidth = 268.0;

  static TextStyle get eyebrow => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF747B86),
      );

  static TextStyle get fieldLabel => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: ink,
      );

  static TextStyle get metaLabel => const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.55,
        color: muted,
      );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        border: Border.all(color: blue),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.08),
            offset: const Offset(0, 1),
          ),
        ],
      );

  static InputDecoration fieldDecoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: fieldLabel.copyWith(color: muted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: const OutlineInputBorder(borderSide: BorderSide(color: line)),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: line)),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: blue, width: 2),
        ),
      );
}

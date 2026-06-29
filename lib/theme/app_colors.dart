import 'package:flutter/material.dart';

abstract final class AppColors {
  static const navy = Color(0xFF10233F);
  static const navy2 = Color(0xFF18395F);
  static const cream = Color(0xFFFBF4E6);
  static const parchment = Color(0xFFFFFAF0);
  static const surfaceSoft = Color(0xFFF5EAD7);
  static const surfaceSolid = Color(0xFFFFFFFF);
  static const ink = Color(0xFF18253B);
  static const muted = Color(0xFF6E6B61);
  static const gold = Color(0xFFB9892F);
  static const mint = Color(0xFF36C28A);
  static const coral = Color(0xFFF26D5B);
  static const line = Color(0x29554223);
  static const postedLink = Color(0xFF1F5F9F);

  static Color forumAccentSoft(Color accent) =>
      accent.withValues(alpha: 0.10);
}

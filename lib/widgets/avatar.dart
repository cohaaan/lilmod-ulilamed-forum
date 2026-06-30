import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A circular avatar that derives a stable colour and initial from a name.
/// Works for both Latin and Hebrew names (uses the first character).
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  static const _palette = [
    Color(0xFF4865E0),
    Color(0xFF7C5CE0),
    Color(0xFF2D9CDB),
    Color(0xFF27AE8F),
    Color(0xFFE0A23B),
    Color(0xFFE0686F),
    Color(0xFF5B8DEF),
    Color(0xFF9B59B6),
  ];

  Color get _color {
    if (name.isEmpty) return _palette.first;
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash + unit) % _palette.length;
    }
    return _palette[hash];
  }

  String get _initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: GoogleFonts.inter(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/seforim.dart';
import '../theme/app_colors.dart';
import '../theme/seforim_palette.dart';

/// A Sefaria-style library row: a thin category-colour rule on top, the
/// work/category name in a serif face with its Hebrew name alongside, and a
/// short description below. Categories drill into a sub-list; books open their
/// table of contents.
Widget seforimNodeRow(
  BuildContext context, {
  required SeforimNode node,
}) {
  final color = SeforimPalette.forCategory(node.colorKey);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(height: 3, color: color),
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final enc = Uri.encodeComponent(node.label);
            if (node.isCategory) {
              context.push('/seforim/c/$enc', extra: node);
            } else {
              context.push('/seforim/book/$enc', extra: node);
            }
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        node.label,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          height: 1.1,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    if (node.heLabel.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        node.heLabel,
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.frankRuhlLibre(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ],
                ),
                if (node.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    node.description,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.45,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

/// A simple serif section row (English + Hebrew label + chevron) used for
/// complex-book parts in the book screen.
Widget seforimSectionRow({
  required String label,
  required String heLabel,
  required VoidCallback onTap,
  bool showDivider = true,
}) {
  return Column(
    children: [
      Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 19,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                      if (heLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          heLabel,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.frankRuhlLibre(
                            fontSize: 15,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted, size: 20),
              ],
            ),
          ),
        ),
      ),
      if (showDivider)
        Divider(height: 1, color: AppColors.line),
    ],
  );
}

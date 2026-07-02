import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/seforim.dart';
import '../theme/seforim_palette.dart';

/// A Sefaria-style library row: a 4px category-colour rule on top (top level
/// only — sub-levels separate with a hairline, like Sefaria), the name in
/// Cardo with its Hebrew name in Taamey Frank alongside, and a short sans
/// description below. Categories drill into a sub-list; books open their
/// table of contents.
Widget seforimNodeRow(
  BuildContext context, {
  required SeforimNode node,
  bool showColorBar = true,
}) {
  final color = SeforimPalette.forCategory(node.colorKey);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (showColorBar)
        Container(height: 4, color: color)
      else
        Divider(height: 1, thickness: 1, color: SeforimPalette.paperLine),
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
                        style: SeforimText.serif(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: SeforimPalette.black,
                        ),
                      ),
                    ),
                    if (node.heLabel.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        node.heLabel,
                        textDirection: TextDirection.rtl,
                        style: SeforimText.hebrew(
                          fontSize: 21,
                          color: SeforimPalette.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (node.description.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    node.description,
                    style: SeforimText.sans(
                      fontSize: 14,
                      height: 1.3,
                      color: SeforimPalette.secondary,
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
                        style: SeforimText.serif(
                          fontSize: 19,
                          color: SeforimPalette.black,
                        ),
                      ),
                      if (heLabel.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          heLabel,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SeforimText.hebrew(
                            fontSize: 16,
                            color: SeforimPalette.secondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SeforimPalette.tertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
      if (showDivider)
        Divider(height: 1, color: SeforimPalette.paperLine),
    ],
  );
}

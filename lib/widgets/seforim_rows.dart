import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/seforim_prefs.dart';
import '../models/seforim.dart';
import '../theme/seforim_palette.dart';

/// A Sefaria-style library row: a 4px category-colour rule on top (top level
/// only — sub-levels separate with a hairline, like Sefaria), the name in
/// Cardo (or Taamey Frank in Hebrew mode — one language at a time, like
/// Sefaria's א/A interface switch) and a short description below.
/// Categories drill into a sub-list; books open their table of contents.
Widget seforimNodeRow(
  BuildContext context, {
  required SeforimNode node,
  bool showColorBar = true,
  bool hebrew = false,
}) {
  final color = SeforimPalette.forCategory(node.colorKey);
  final useHe = hebrew && node.heLabel.isNotEmpty;
  final title = useHe ? node.heLabel : node.label;
  final desc = hebrew && node.heShortDesc.trim().isNotEmpty
      ? node.heShortDesc.trim()
      : node.description;
  final descIsHe = hebrew && node.heShortDesc.trim().isNotEmpty;
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
              crossAxisAlignment:
                  useHe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textDirection:
                      useHe ? TextDirection.rtl : TextDirection.ltr,
                  style: useHe
                      ? SeforimText.hebrew(
                          fontSize: 23,
                          height: 1.3,
                          color: SeforimPalette.black,
                        )
                      : SeforimText.serif(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          height: 1.3,
                          color: SeforimPalette.black,
                        ),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    textDirection:
                        descIsHe ? TextDirection.rtl : TextDirection.ltr,
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

/// Sefaria's small-caps sub-group header on a category page —
/// "HALAKHAH (Law)" — tappable to drill into the group's own page.
Widget seforimGroupHeader(
  BuildContext context, {
  required SeforimNode node,
  bool hebrew = false,
}) {
  final useHe = hebrew && node.heLabel.isNotEmpty;
  final desc = hebrew && node.heShortDesc.trim().isNotEmpty
      ? node.heShortDesc.trim()
      : node.description;
  final paren = desc.isNotEmpty && desc.length <= 40 ? desc : '';
  return InkWell(
    onTap: () => context.push(
      '/seforim/c/${Uri.encodeComponent(node.label)}',
      extra: node,
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
      child: useHe
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (paren.isNotEmpty)
                  Text(
                    '($paren) ',
                    textDirection: TextDirection.rtl,
                    style: SeforimText.hebrew(
                      fontSize: 15,
                      color: SeforimPalette.tertiary,
                    ),
                  ),
                Text(
                  node.heLabel,
                  textDirection: TextDirection.rtl,
                  style: SeforimText.hebrew(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: SeforimPalette.secondary,
                  ),
                ),
              ],
            )
          : Text.rich(
              TextSpan(
                text: node.label.toUpperCase(),
                style: SeforimText.serif(
                  fontSize: 15,
                  letterSpacing: 1.2,
                  color: SeforimPalette.secondary,
                ),
                children: [
                  if (paren.isNotEmpty)
                    TextSpan(
                      text: '  ($paren)',
                      style: SeforimText.serif(
                        fontSize: 13,
                        letterSpacing: 0.4,
                        color: SeforimPalette.tertiary,
                      ),
                    ),
                ],
              ),
            ),
    ),
  );
}

/// Sefaria's א / A interface-language switch: a small bordered box that
/// toggles the library screens between English and Hebrew titles. Shows the
/// language you'd switch *to*, like Sefaria's toggle.
class SeforimLangToggle extends StatelessWidget {
  const SeforimLangToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: seforimHebrewMode,
      builder: (context, hebrew, _) => Material(
        color: SeforimPalette.paper,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: () => seforimHebrewMode.value = !hebrew,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: SeforimPalette.paperLine),
            ),
            child: hebrew
                ? Text(
                    'A',
                    style: SeforimText.serif(
                      fontSize: 17,
                      color: SeforimPalette.secondary,
                    ),
                  )
                : Text(
                    'א',
                    style: SeforimText.hebrew(
                      fontSize: 17,
                      color: SeforimPalette.secondary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// A simple serif section row (English + Hebrew label + chevron) used for
/// complex-book parts in the book screen.
Widget seforimSectionRow({
  required String label,
  required String heLabel,
  required VoidCallback onTap,
  bool showDivider = true,
  bool hebrew = false,
}) {
  final useHe = hebrew && heLabel.isNotEmpty;
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
                  child: Text(
                    useHe ? heLabel : label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection:
                        useHe ? TextDirection.rtl : TextDirection.ltr,
                    style: useHe
                        ? SeforimText.hebrew(
                            fontSize: 18,
                            color: SeforimPalette.black,
                          )
                        : SeforimText.serif(
                            fontSize: 19,
                            color: SeforimPalette.black,
                          ),
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

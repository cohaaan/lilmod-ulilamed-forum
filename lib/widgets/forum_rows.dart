import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// A tight, tappable row used for both categories and subforums:
/// coloured icon · title + subtitle · meta · chevron.
class ForumRow extends StatelessWidget {
  const ForumRow({
    super.key,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.showDivider = true,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 4,
                      constraints: const BoxConstraints(minHeight: 38),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                              height: 1.35,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                          if (trailing.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                trailing,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: 70),
            child: Divider(height: 1, color: AppColors.line),
          ),
      ],
    );
  }
}

/// Convenience builder that wires a row to push a route.
ForumRow forumRowTo(
  BuildContext context, {
  required Color accent,
  required String title,
  required String subtitle,
  required String trailing,
  required String path,
  bool showDivider = true,
}) {
  return ForumRow(
    accent: accent,
    title: title,
    subtitle: subtitle,
    trailing: trailing,
    showDivider: showDivider,
    onTap: () => context.push(path),
  );
}

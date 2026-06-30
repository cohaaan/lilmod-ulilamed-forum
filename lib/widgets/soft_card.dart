import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Flat bordered surface — no drop shadows (Discourse-style).
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.useBrutalistChrome ? AppColors.primary : AppColors.line,
        ),
        boxShadow: AppColors.useBrutalistChrome
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: card,
      ),
    );
  }
}

/// A row with a bold section title and an optional trailing action link.
class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.section,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(color: AppColors.link),
            ),
          ),
        ],
      ],
    );
  }
}

/// Rectangular category label — not a pill.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (AppColors.useBrutalistChrome) {
      final fill = color ?? AppColors.primary;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: AppColors.line),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.sans(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
      );
    }

    final c = color ?? AppColors.link;
    final radius = AppColors.usePillTags ? 999.0 : 4.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.sans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: c,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/thread.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import 'avatar.dart';
import 'soft_card.dart';

/// A forum thread shown as a card: category, activity, title, author, stats.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.thread});

  final Thread thread;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.useBrutalistChrome
        ? AppColors.primary
        : accentForId(thread.subforumId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        onTap: () => context.push('/threads/${thread.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Tag(
                    label: thread.subforumName ?? thread.type,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (thread.isNew) ...[
                      Tag(label: 'NEW', color: AppColors.mint),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      relativeTime(thread.lastActivityAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              thread.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            Divider(height: 22, color: AppColors.line),
            Row(
              children: [
                Avatar(name: thread.authorName, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    thread.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.body,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Stat(
                      icon: Icons.chat_bubble_outline_rounded,
                      value: thread.replyCount,
                    ),
                    const SizedBox(width: 14),
                    _Stat(
                      icon: Icons.remove_red_eye_outlined,
                      value: thread.viewCount,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.muted),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
      ],
    );
  }
}

/// A compact one-line thread row used in search results.
class CompactPostRow extends StatelessWidget {
  const CompactPostRow({
    super.key,
    required this.id,
    required this.title,
    required this.meta,
    required this.accent,
  });

  final String id;
  final String title;
  final String meta;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/threads/$id'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

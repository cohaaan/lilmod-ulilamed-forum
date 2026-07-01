import 'package:flutter/material.dart';
import '../theme/app_text.dart';

/// A colourful gradient tile used in the horizontal "Popular categories" rail.
class TopicCard extends StatelessWidget {
  const TopicCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.gradient,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.30),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

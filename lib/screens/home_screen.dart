import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/content_panel.dart';
import '../widgets/hero_section.dart';
import '../widgets/site_scaffold.dart';
import '../widgets/thread_row.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      showHero: true,
      hero: const HeroSection(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;

          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      eyebrow: 'Forums',
                      title: 'Recent discussions',
                      actionLabel: 'Active topics',
                      onAction: () => context.go('/forums'),
                    ),
                    const SizedBox(height: 16),
                    ...MockData.recentThreads.map(
                      (thread) => ThreadRow(thread: thread),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ContentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionHeading(
                      eyebrow: 'Articles',
                      title: 'Featured writing',
                      actionLabel: 'All articles',
                      onAction: () => context.go('/articles'),
                    ),
                    const SizedBox(height: 16),
                    ...MockData.featuredArticles.map(
                      (article) => ArticleCard(article: article),
                    ),
                  ],
                ),
              ),
            ],
          );

          final sidebar = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ContentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Popular Topics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ...MockData.popularThreads.map(
                      (thread) => SidebarThreadRow(thread: thread),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ContentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Standards',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    ...MockData.communityStandards.map(
                      (standard) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(
                              child: Text(
                                standard,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  height: 1.45,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ContentPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forum snapshot',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatChip(
                          value: '${MockData.forumStats['threads']}',
                          label: 'threads',
                        ),
                        _StatChip(
                          value: '${MockData.forumStats['posts']}',
                          label: 'posts',
                        ),
                        _StatChip(
                          value: '${MockData.forumStats['articles']}',
                          label: 'Articles',
                        ),
                        _StatChip(
                          value: '${MockData.forumStats['members']}',
                          label: 'Members',
                        ),
                        _StatChip(
                          value: '${MockData.forumStats['online']}',
                          label: 'online',
                          highlight: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Online: ${MockData.onlineMembers.join(', ')}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final lower = ContentPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Source requests',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                ...MockData.sourceRequests.map(
                  (thread) => MiniRow(thread: thread),
                ),
              ],
            ),
          );

          if (wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: mainColumn),
                    const SizedBox(width: 16),
                    Expanded(flex: 4, child: sidebar),
                  ],
                ),
                const SizedBox(height: 16),
                lower,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mainColumn,
              const SizedBox(height: 16),
              sidebar,
              const SizedBox(height: 16),
              lower,
            ],
          );
        },
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.mint.withValues(alpha: 0.14)
            : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.muted),
          children: [
            TextSpan(
              text: value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            TextSpan(text: label),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../models/article_item.dart';
import '../theme/app_colors.dart';
import '../widgets/content_panel.dart';
import '../widgets/site_scaffold.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.slug});

  final String slug;

  ArticleItem _findArticle() {
    return MockData.allArticles.firstWhere(
      (article) => article.slug == slug,
      orElse: () => MockData.allArticles.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final article = _findArticle();

    return SiteScaffold(
      child: ContentPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/articles'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to articles'),
            ),
            const SizedBox(height: 8),
            Text(
              '${article.category} · ${article.date}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.15,
              ),
            ),
            if (article.excerpt != null) ...[
              const SizedBox(height: 12),
              Text(
                article.excerpt!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.muted,
                  height: 1.6,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Article body will load here once the backend is connected.',
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.7,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/articles_data.dart';
import '../theme/app_colors.dart';
import '../widgets/soft_card.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final article = ArticlesData.bySlug(slug);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/articles'),
        ),
        title: Text(
          'Article',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: null,
            icon: Icon(Icons.bookmark_border_rounded, color: AppColors.ink),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Row(
            children: [
              Tag(label: article.category, color: article.accentColor),
              const SizedBox(width: 8),
              Text(
                article.date,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            article.title,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: AppColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          if (article.excerpt != null) ...[
            const SizedBox(height: 12),
            Text(
              article.excerpt!,
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: AppColors.body,
              ),
            ),
          ],
          const SizedBox(height: 20),
          SoftCard(
            child: Text(
              'The article body will load here once the backend is connected.',
              style: GoogleFonts.inter(
                fontSize: 14.5,
                height: 1.7,
                color: AppColors.body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';
import '../widgets/site_scaffold.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Articles',
            style: GoogleFonts.playfairDisplay(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Polished long-form articles, source studies, and serious written contributions.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...MockData.allArticles.map(
            (article) => ArticleCard(article: article),
          ),
        ],
      ),
    );
  }
}

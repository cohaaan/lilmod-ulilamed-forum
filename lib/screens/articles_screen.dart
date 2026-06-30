import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/articles_data.dart';
import '../theme/app_colors.dart';
import '../widgets/article_card.dart';

class ArticlesScreen extends StatelessWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text(
              'Articles',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Long-form articles, source studies, and written contributions.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ...ArticlesData.all.map((a) => ArticleCard(article: a)),
          ],
        ),
      ),
    );
  }
}

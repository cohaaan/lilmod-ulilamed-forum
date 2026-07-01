import '../theme/forum_palette.dart';
import '../models/article_item.dart';

/// Articles are editorial content, managed separately from the live forum.
/// Kept static for now; can move to Supabase later if needed.
abstract final class ArticlesData {
  static final featured = [
    ArticleItem(
      slug: 'kavod-hatzibbur',
      title: 'Kavod Hatzibbur',
      category: 'Halacha',
      date: 'Jun 20, 2026',
      accentColor: ForumPalette.forName('Halacha'),
    ),
    ArticleItem(
      slug: 'on-semichas-geulah-ltfillah',
      title: "On Semichas Geulah L'tfillah",
      category: 'Aggadah and Derush',
      date: 'Jun 15, 2026',
      accentColor: ForumPalette.forName('Aggadah and Derush'),
    ),
    ArticleItem(
      slug: 'hats-jackets-and-gartels-in-halacha',
      title: 'Hats Jackets and Gartels in Halacha',
      category: 'Halacha',
      date: 'Jun 5, 2026',
      accentColor: ForumPalette.forName('Halacha'),
      excerpt:
          'An understanding of the halachos related to dress during prayer, according to all communities.',
    ),
  ];

  static final all = [
    ...featured,
    ArticleItem(
      slug: 'sample-article',
      title: 'Sample Article',
      category: 'Machshavah',
      date: 'May 1, 2026',
      accentColor: ForumPalette.forName('Machshavah'),
    ),
    ArticleItem(
      slug: 'another-article',
      title: 'Another Article',
      category: 'Historical Studies',
      date: 'Apr 12, 2026',
      accentColor: ForumPalette.forName('Historical Studies'),
    ),
  ];

  static ArticleItem bySlug(String slug) => all.firstWhere(
        (a) => a.slug == slug,
        orElse: () => all.first,
      );
}

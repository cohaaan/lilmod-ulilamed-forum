import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Stable topic colours for forum subforums, categories, and article labels.
///
/// Subforums inherit their parent category colour unless listed in
/// [_subforumOverride]. Article category names resolve through [_byDisplayName]
/// so the Articles tab and forum tags stay aligned.
abstract final class ForumPalette {
  static const fallback = Color(0xFF68707D);

  static const _byCategoryId = <String, Color>{
    'beis-hamidrash': Color(0xFFCCB479),
    'parashah-tanach': Color(0xFF004E5F),
    'halachah-minhag': Color(0xFF8A63D2),
    'tefillah-piyyut': Color(0xFFAB4E66),
    'moadim': Color(0xFFB7791F),
    'mekoros': Color(0xFF2F80ED),
    'sefarim': Color(0xFF594176),
    'dikduk': Color(0xFF5A99B7),
    'history-gedolim': Color(0xFFB7791F),
    'machshavah': Color(0xFF3D8B55),
    'chinuch': Color(0xFF97B386),
    'articles': Color(0xFF64748B),
    'community-discussion': Color(0xFF475569),
    'questions-riddles': Color(0xFFECB22E),
    'technical-help': Color(0xFF1264A3),
    'marketplace': Color(0xFFCB6158),
    'community-site': Color(0xFF1458B0),
  };

  /// Subforums that need a distinct colour within their parent category.
  static const _subforumOverride = <String, Color>{
    'aggadah-midrash': Color(0xFFC4667B),
  };

  static const _subforumCategory = <String, String>{
    'aggadah-midrash': 'beis-hamidrash',
    'announcements': 'community-site',
    'aramaic': 'dikduk',
    'bibliography': 'mekoros',
    'calendar-zemanim': 'moadim',
    'chanukah-purim': 'moadim',
    'chinuch-general': 'chinuch',
    'chumash': 'parashah-tanach',
    'communities-history': 'history-gedolim',
    'community-exchange': 'marketplace',
    'contemporary-halachah': 'halachah-minhag',
    'current-events': 'community-discussion',
    'customs-tefillah': 'tefillah-piyyut',
    'daas-torah': 'machshavah',
    'daf-yomi': 'beis-hamidrash',
    'databases-tools': 'technical-help',
    'dates-chronology': 'history-gedolim',
    'digital-otzar': 'mekoros',
    'digital-publishing': 'sefarim',
    'dikduk-grammar': 'dikduk',
    'editing-proofreading': 'sefarim',
    'educational-dilemmas': 'chinuch',
    'emunah-bitachon': 'machshavah',
    'emunah-discussion': 'community-discussion',
    'errata-corrections': 'sefarim',
    'even-haezer-choshen': 'halachah-minhag',
    'fast-days': 'moadim',
    'feedback': 'community-site',
    'finding-sources': 'mekoros',
    'gedolim-rabbanim': 'history-gedolim',
    'gemara': 'beis-hamidrash',
    'general-discussion': 'community-discussion',
    'halacha-articles': 'articles',
    'hard-mareh-mekomos': 'questions-riddles',
    'hashkafah-issues': 'machshavah',
    'hebrew-text-tech': 'technical-help',
    'historical-documents': 'history-gedolim',
    'historical-halachah': 'halachah-minhag',
    'invited-essays': 'articles',
    'lashon-hakodesh': 'dikduk',
    'lost-references': 'mekoros',
    'machshavah-articles': 'articles',
    'machshavah-general': 'machshavah',
    'manuscripts-editing': 'sefarim',
    'manuscripts-prints': 'mekoros',
    'mareh-mekomos': 'beis-hamidrash',
    'mareh-mekomos-trails': 'mekoros',
    'masorah': 'dikduk',
    'midrashim': 'parashah-tanach',
    'minhagim': 'halachah-minhag',
    'moderation-notes': 'community-site',
    'mussar': 'machshavah',
    'neviim-kesuvim': 'parashah-tanach',
    'new-sefarim': 'sefarim',
    'niggunim': 'tefillah-piyyut',
    'nusach-tefillah': 'tefillah-piyyut',
    'orach-chaim': 'halachah-minhag',
    'parashah-essays': 'articles',
    'parenting': 'chinuch',
    'pdf-documents': 'technical-help',
    'permitted-resources': 'mekoros',
    'perush-hatefillah': 'tefillah-piyyut',
    'piyut-liturgy': 'tefillah-piyyut',
    'practical-matters': 'community-discussion',
    'quizzes-challenges': 'questions-riddles',
    'quotations-attributions': 'mekoros',
    'rare-sefarim': 'mekoros',
    'recommendations': 'marketplace',
    'rules-guidelines': 'community-site',
    'schools-yeshivos': 'chinuch',
    'secondhand': 'marketplace',
    'sefarim-reviews': 'sefarim',
    'sefarim-sales': 'marketplace',
    'sefiras-haomer': 'moadim',
    'shabbos': 'moadim',
    'shalosh-regalim': 'moadim',
    'sharp-questions': 'questions-riddles',
    'short-questions': 'beis-hamidrash',
    'sifrei-machshavah': 'machshavah',
    'site-help': 'community-site',
    'software-help': 'technical-help',
    'source-studies': 'articles',
    'suggestions': 'community-site',
    'sugyos-halachah': 'halachah-minhag',
    'taamei-hamikra': 'dikduk',
    'torah-life': 'community-discussion',
    'torah-riddles': 'questions-riddles',
    'typography-typesetting': 'sefarim',
    'weekly-parashah': 'parashah-tanach',
    'workflows': 'technical-help',
    'yamim-noraim': 'moadim',
    'yoreh-deah': 'halachah-minhag',
  };

  /// Article and legacy display-name aliases (case-insensitive).
  static const _byDisplayName = <String, Color>{
    'halacha': Color(0xFF8A63D2),
    'aggadah and derush': Color(0xFFC4667B),
    'aggadah and midrash': Color(0xFFC4667B),
    'machshavah': Color(0xFF3D8B55),
    'historical studies': Color(0xFFB7791F),
    'gemara': Color(0xFFCCB479),
    'finding sources': Color(0xFF2F80ED),
    'contemporary halachic questions': Color(0xFF8A63D2),
  };

  static Color forSubforum(String id, {String? name}) {
    final override = _subforumOverride[id];
    if (override != null) return override;

    final categoryId = _subforumCategory[id];
    if (categoryId != null) {
      return _byCategoryId[categoryId] ?? _hashed(id);
    }

    if (name != null) {
      final byName = _lookupName(name);
      if (byName != null) return byName;
    }

    return _hashed(id.isNotEmpty ? id : (name ?? ''));
  }

  static Color forCategory(String id) =>
      _byCategoryId[id] ?? _hashed(id);

  static Color forName(String name) =>
      _lookupName(name) ?? _hashed(name);

  /// Returns a palette colour when [id] is a known category or subforum slug.
  static Color? tryForId(String id) {
    if (_subforumOverride.containsKey(id) ||
        _subforumCategory.containsKey(id)) {
      return forSubforum(id);
    }
    if (_byCategoryId.containsKey(id)) return forCategory(id);
    return null;
  }

  static Color? _lookupName(String name) {
    final key = name.toLowerCase().trim();
    return _byDisplayName[key];
  }

  static Color _hashed(String seed) {
    if (seed.isEmpty) return fallback;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash + unit) % AppColors.accents.length;
    }
    return AppColors.accents[hash];
  }
}

// Models for the Seforim (Sefaria) browser. Parsed from the Sefaria API.
//
// The library is a tree: categories contain sub-categories and/or books.
// A book has a structure (chapters / sections) and its text is read a section
// at a time, where a section is a list of segments (verses / mishnayot / etc.).

/// A node in the library tree — either a category (has [contents]) or a book
/// (has a [title] and no contents).
class SeforimNode {
  const SeforimNode({
    this.category,
    this.heCategory,
    this.title,
    this.heTitle,
    this.contents = const [],
    this.categories = const [],
    this.enShortDesc = '',
    this.heShortDesc = '',
    this.primaryCategory,
  });

  /// Category display name (English), null for books.
  final String? category;
  final String? heCategory;

  /// Book title (English), null for categories.
  final String? title;
  final String? heTitle;

  /// Child nodes for a category; empty for a book.
  final List<SeforimNode> contents;

  /// Category path for a book (e.g. ["Talmud","Bavli",...]); used to pick the
  /// right addressing (daf vs chapter) in the book screen.
  final List<String> categories;

  /// Short English / Hebrew descriptions (shown Sefaria-style under the name).
  final String enShortDesc;
  final String heShortDesc;

  /// Top corpus a book belongs to (e.g. "Tanakh"); used for colour-coding.
  final String? primaryCategory;

  bool get isBook => title != null;
  bool get isCategory => title == null;

  /// Whether this book is addressed by Talmudic daf (2a, 2b, …).
  bool get isTalmud => categories.contains('Talmud');

  /// Best English label for the node.
  String get label => (title ?? category ?? '').trim();

  /// Best Hebrew label for the node.
  String get heLabel => (heTitle ?? heCategory ?? '').trim();

  /// Short description for display (English).
  String get description => enShortDesc.trim();

  /// The corpus key used to pick this node's category colour.
  String get colorKey => isBook
      ? (primaryCategory ?? (categories.isNotEmpty ? categories.first : ''))
      : (category ?? '');

  factory SeforimNode.fromJson(Map<String, dynamic> json) {
    final rawContents = json['contents'] as List?;
    final rawCats = json['categories'] as List?;
    return SeforimNode(
      category: json['category'] as String?,
      heCategory: json['heCategory'] as String?,
      title: json['title'] as String?,
      heTitle: json['heTitle'] as String?,
      contents: rawContents == null
          ? const []
          : rawContents
              .whereType<Map<String, dynamic>>()
              .map(SeforimNode.fromJson)
              .toList(),
      categories:
          rawCats == null ? const [] : rawCats.whereType<String>().toList(),
      enShortDesc: (json['enShortDesc'] as String?) ?? '',
      heShortDesc: (json['heShortDesc'] as String?) ?? '',
      primaryCategory: json['primary_category'] as String?,
    );
  }
}

/// One structural node from `/api/shape/{title}` — describes how a book is
/// divided. For a simple book there's a single node with [chapters] holding
/// the segment count per chapter. For complex books there are several nodes.
class ShapeNode {
  const ShapeNode({
    required this.title,
    required this.heTitle,
    required this.chapters,
    required this.length,
    required this.isComplex,
  });

  /// The reference/title for this node (e.g. "Genesis", or a sub-section ref).
  final String title;
  final String heTitle;

  /// Segment count per chapter for a simple text; empty for complex nodes.
  final List<int> chapters;

  /// Number of top-level sections.
  final int length;
  final bool isComplex;

  bool get isSimple => !isComplex && chapters.isNotEmpty;

  factory ShapeNode.fromJson(Map<String, dynamic> json) {
    // `chapters` is a flat list of ints for simple texts; for complex texts it
    // is a nested structure we don't unpack here.
    final raw = json['chapters'];
    final chapters = <int>[];
    if (raw is List) {
      for (final c in raw) {
        if (c is int) {
          chapters.add(c);
        } else if (c is num) {
          chapters.add(c.toInt());
        }
      }
      // If the list held non-int entries (complex), treat as not-simple.
      if (chapters.length != raw.length) chapters.clear();
    }
    return ShapeNode(
      title: (json['title'] ?? json['book'] ?? '') as String,
      heTitle: (json['heTitle'] ?? json['heBook'] ?? '') as String,
      chapters: chapters,
      length: (json['length'] as num?)?.toInt() ?? chapters.length,
      isComplex: json['isComplex'] == true,
    );
  }
}

/// A loaded section of text: a list of aligned Hebrew/English segments plus
/// navigation to the previous/next section.
class SeforimPassage {
  const SeforimPassage({
    required this.ref,
    required this.heRef,
    required this.book,
    required this.segments,
    required this.next,
    required this.prev,
    required this.heAttribution,
    required this.enAttribution,
  });

  final String ref;
  final String heRef;
  final String book;
  final List<SeforimSegment> segments;

  /// Ref of the next / previous section, or null at the boundary.
  final String? next;
  final String? prev;

  final SeforimAttribution? heAttribution;
  final SeforimAttribution? enAttribution;
}

/// A single segment (verse / mishnah / line) with both languages.
class SeforimSegment {
  const SeforimSegment({
    required this.number,
    required this.he,
    required this.en,
  });

  /// 1-based segment label within the section.
  final String number;
  final String he;
  final String en;

  bool get hasHe => he.trim().isNotEmpty;
  bool get hasEn => en.trim().isNotEmpty;
}

/// Attribution for a text version, shown in the reader and pasted sources.
class SeforimAttribution {
  const SeforimAttribution({
    required this.versionTitle,
    required this.source,
    required this.license,
  });

  final String versionTitle;
  final String source;
  final String license;
}

/// A single related text linked to a verse — a commentary (Rashi, Ramban…),
/// or a Midrash / Talmud / Halakhah / Targum source — parsed from Sefaria's
/// links API.
class SeforimComment {
  const SeforimComment({
    required this.category,
    required this.commentator,
    required this.heCommentator,
    required this.ref,
    required this.heRef,
    required this.he,
    required this.en,
  });

  /// Sefaria link category, e.g. "Commentary", "Midrash", "Talmud".
  final String category;

  /// Work / commentator display name (English), e.g. "Rashi".
  final String commentator;

  /// Commentator display name (Hebrew), e.g. "רש״י".
  final String heCommentator;

  /// The exact source ref of this comment, e.g. "Rashi on Exodus 3:1:1".
  final String ref;
  final String heRef;
  final String he;
  final String en;

  bool get hasHe => he.trim().isNotEmpty;
  bool get hasEn => en.trim().isNotEmpty;
}

/// A search result pointing at a reference.
class SeforimSearchResult {
  const SeforimSearchResult({
    required this.ref,
    required this.heRef,
    required this.snippet,
  });

  final String ref;
  final String heRef;
  final String snippet;
}

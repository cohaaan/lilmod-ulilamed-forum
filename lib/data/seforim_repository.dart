import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/seforim_config.dart';
import '../models/seforim.dart';

/// All Sefaria API access goes through here. Mirrors the singleton pattern of
/// the other repositories. Read-only; texts are public data.
class SeforimRepository {
  final http.Client _client = http.Client();

  /// The library tree is large and static — fetch once and reuse.
  List<SeforimNode>? _indexCache;

  /// Small cache of recently-read sections so prev/next is snappy.
  final Map<String, SeforimPassage> _passageCache = {};

  /// Related texts are fetched lazily per verse; cache them so re-opening a
  /// verse's sources is instant.
  final Map<String, List<SeforimComment>> _relatedCache = {};

  /// Link categories surfaced as "related texts" under a verse, in display
  /// order. Mirrors Sefaria's reader; noisier categories (Quoting Commentary,
  /// Reference, Essay…) are omitted to keep the list focused and lighter.
  static const relatedCategories = [
    'Commentary',
    'Targum',
    'Midrash',
    'Talmud',
    'Halakhah',
    'Kabbalah',
    'Chasidut',
    'Musar',
    'Jewish Thought',
  ];

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('${SeforimConfig.apiBase}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
      );

  Future<dynamic> _getJson(Uri uri) async {
    final res = await _client.get(uri).timeout(SeforimConfig.timeout);
    if (res.statusCode != 200) {
      throw Exception('Sefaria API ${res.statusCode} for $uri');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Max entries kept in the section/commentary caches. Commentary entries can
  /// each retain a large `with_text=1` response, so bound them to avoid
  /// unbounded memory growth over a long browsing session.
  static const _maxCacheEntries = 30;

  /// Insert into a cache with FIFO eviction (maps preserve insertion order).
  void _putCapped<V>(Map<String, V> cache, String key, V value) {
    if (!cache.containsKey(key) && cache.length >= _maxCacheEntries) {
      cache.remove(cache.keys.first);
    }
    cache[key] = value;
  }

  // ------------------------------------------------------------------- index
  /// The full category/book tree.
  Future<List<SeforimNode>> fetchIndex() async {
    final cached = _indexCache;
    if (cached != null) return cached;
    final data = await _getJson(_uri('/api/index/'));
    final list = (data as List)
        .whereType<Map<String, dynamic>>()
        .map(SeforimNode.fromJson)
        .toList();
    _indexCache = list;
    return list;
  }

  /// Find a book node in the index tree by its English title. Used to recover
  /// addressing (Talmud daf vs chapter) on a cold deep-link where navigation
  /// didn't pass the node.
  Future<SeforimNode?> findBook(String title) async {
    SeforimNode? search(List<SeforimNode> nodes) {
      for (final n in nodes) {
        if (n.isBook && n.label == title) return n;
        final hit = search(n.contents);
        if (hit != null) return hit;
      }
      return null;
    }

    return search(await fetchIndex());
  }

  // ------------------------------------------------------------------- shape
  /// The structure of a book (chapters / sections).
  Future<List<ShapeNode>> fetchShape(String title) async {
    final data = await _getJson(_uri('/api/shape/${Uri.encodeComponent(title)}'));
    final list = data is List ? data : [data];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ShapeNode.fromJson)
        .toList();
  }

  // -------------------------------------------------------------------- text
  /// A section of text with aligned Hebrew + English segments.
  Future<SeforimPassage> fetchPassage(String ref) async {
    final cached = _passageCache[ref];
    if (cached != null) return cached;

    // Request both the source (usually Hebrew/Aramaic) and an English
    // translation in one call, with HTML/footnotes stripped.
    final uri = _uri('/api/v3/texts/${Uri.encodeComponent(ref)}', {
      'version': 'source',
      'return_format': 'text_only',
    });
    // The v3 endpoint takes repeated `version` params; build the URL manually
    // so we can pass both source and translation.
    final fullUri = uri.replace(
      query: '${uri.query}&version=translation',
    );

    final data = await _getJson(fullUri) as Map<String, dynamic>;

    final versions = (data['versions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();

    Map<String, dynamic>? pick(bool he) {
      for (final v in versions) {
        final lang = (v['language'] ?? v['actualLanguage'] ?? '') as String;
        final isHe = lang == 'he';
        if (isHe == he) return v;
      }
      return null;
    }

    final heVer = pick(true);
    final enVer = pick(false);

    final heText = _asSegments(heVer?['text']).map(_stripTeamim).toList();
    final enText = _asSegments(enVer?['text']);

    // The source (Hebrew) defines canonical verse numbering — verseRefs derived
    // from it drive commentary lookups. Pair English by index only when the
    // counts match; a translation segmented differently can't be aligned
    // per-verse, so fall back to source-only rather than scrambling verses.
    final List<String> heSeg;
    final List<String> enSeg;
    if (heText.isNotEmpty) {
      heSeg = heText;
      enSeg = enText.length == heText.length ? enText : const <String>[];
    } else {
      heSeg = const <String>[];
      enSeg = enText; // English-only text: number by the translation.
    }
    final count = heSeg.isNotEmpty ? heSeg.length : enSeg.length;

    final segments = <SeforimSegment>[
      for (var i = 0; i < count; i++)
        SeforimSegment(
          number: '${i + 1}',
          he: i < heSeg.length ? heSeg[i] : '',
          en: i < enSeg.length ? enSeg[i] : '',
        ),
    ];

    final passage = SeforimPassage(
      ref: (data['ref'] ?? ref) as String,
      heRef: (data['heRef'] ?? '') as String,
      book: (data['book'] ?? '') as String,
      segments: segments,
      next: data['next'] as String?,
      prev: data['prev'] as String?,
      heAttribution: _attribution(heVer),
      enAttribution: _attribution(enVer),
    );
    _putCapped(_passageCache, ref, passage);
    return passage;
  }

  // --------------------------------------------------------------- related
  /// The related texts linked to a single verse — meforshim (Rashi, Ramban…)
  /// plus Midrash / Talmud / Halakhah / Targum sources — filtered to
  /// [relatedCategories] and tagged with their category. Fetched lazily when a
  /// reader expands a verse.
  Future<List<SeforimComment>> fetchRelated(String verseRef) async {
    final cached = _relatedCache[verseRef];
    if (cached != null) return cached;

    // Metadata only (`with_text=0`): the full text of every link is ~1.5MB per
    // verse and slow, so we fetch just the list/structure here and load each
    // source's text on demand via [fetchSourceText] when the user expands it.
    final uri = _uri('/api/links/${Uri.encodeComponent(verseRef)}', {
      'with_text': '0',
    });
    final data = await _getJson(uri);
    final links = data is List
        ? data.whereType<Map<String, dynamic>>()
        : const <Map<String, dynamic>>[];

    final out = <SeforimComment>[];
    for (final l in links) {
      final cat = l['category'] as String?;
      if (cat == null || !relatedCategories.contains(cat)) continue;
      final ref = (l['sourceRef'] ?? l['ref']) as String?;
      if (ref == null || ref.isEmpty) continue;
      final ct = l['collectiveTitle'];
      final enTitle = ct is Map<String, dynamic> ? (ct['en'] as String?) : null;
      final heTitle = ct is Map<String, dynamic> ? (ct['he'] as String?) : null;
      out.add(SeforimComment(
        category: cat,
        commentator: (enTitle?.isNotEmpty ?? false)
            ? enTitle!
            : (l['index_title'] as String?) ?? cat,
        heCommentator: heTitle ?? '',
        ref: ref,
        heRef: (l['sourceHeRef'] ?? '') as String,
        he: '',
        en: '',
        indexTitle: (l['index_title'] as String?) ?? '',
        sourceHasEn: l['sourceHasEn'] == true,
      ));
    }
    _putCapped(_relatedCache, verseRef, out);
    return out;
  }

  /// The text of a single linked source (e.g. "Rashi on Genesis 11:1:1"),
  /// Hebrew + English, fetched on demand when a related-text tile is expanded.
  final Map<String, ({String he, String en})> _sourceTextCache = {};

  Future<({String he, String en})> fetchSourceText(String ref) async {
    final cached = _sourceTextCache[ref];
    if (cached != null) return cached;

    final uri = _uri('/api/v3/texts/${Uri.encodeComponent(ref)}', {
      'version': 'source',
      'return_format': 'text_only',
    });
    final fullUri = uri.replace(query: '${uri.query}&version=translation');
    final data = await _getJson(fullUri) as Map<String, dynamic>;

    final versions = (data['versions'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    Map<String, dynamic>? pick(bool he) {
      for (final v in versions) {
        final lang = (v['language'] ?? v['actualLanguage'] ?? '') as String;
        if ((lang == 'he') == he) return v;
      }
      return null;
    }

    final result = (
      he: _stripTeamim(_clean(_joinText(pick(true)?['text']))),
      en: _clean(_joinText(pick(false)?['text'])),
    );
    _putCapped(_sourceTextCache, ref, result);
    return result;
  }

  // ------------------------------------------------------------------- about
  /// About-the-work metadata, cached per index title. Sefaria shows an author
  /// blurb and a "Composed" line for each work; `/api/v2/raw/index/{title}`
  /// carries both (`enDesc`, `compDate`, `compPlace`).
  final Map<String, SeforimWorkAbout> _aboutCache = {};

  Future<SeforimWorkAbout> fetchWorkAbout(String indexTitle) async {
    final cached = _aboutCache[indexTitle];
    if (cached != null) return cached;

    final slug = indexTitle.replaceAll(' ', '_');
    final data =
        await _getJson(_uri('/api/v2/raw/index/${Uri.encodeComponent(slug)}'))
            as Map<String, dynamic>;

    final desc = _clean((data['enDesc'] ?? data['enShortDesc'] ?? '') as String);
    final place = (data['compPlace'] ?? '') as String;
    final dates = (data['compDate'] as List? ?? const [])
        .whereType<num>()
        .map((n) => n.toInt())
        .toList();
    String era = '';
    if (dates.length >= 2 && dates[0] != dates[1]) {
      era = 'c.${dates[0]} – c.${dates[1]}';
    } else if (dates.isNotEmpty) {
      era = 'c.${dates[0]}';
    }
    final composed = [
      if (place.isNotEmpty) place,
      if (era.isNotEmpty) era,
    ].join(', ');

    final about = SeforimWorkAbout(
      description: desc,
      composedLine: composed.isEmpty ? '' : 'Composed: $composed',
    );
    _putCapped(_aboutCache, indexTitle, about);
    return about;
  }

  /// Flatten a links-API `text`/`he` field (String, or possibly-nested List)
  /// into a single string.
  String _joinText(dynamic text) {
    if (text == null) return '';
    if (text is String) return text;
    if (text is List) {
      return text.map(_joinText).where((s) => s.isNotEmpty).join(' ');
    }
    return '';
  }

  /// Remove Hebrew cantillation (te'amim, U+0591–U+05AF) while keeping nikud,
  /// so vocalised text renders cleanly in the reader's serif font.
  String _stripTeamim(String s) =>
      s.replaceAll(RegExp(r'[\u0591-\u05AF]'), '');

  /// Normalise a v3 `text` field (String for a single segment, List for a
  /// section, possibly nested) into a flat list of cleaned strings.
  List<String> _asSegments(dynamic text) {
    if (text == null) return const [];
    if (text is String) return [_clean(text)];
    if (text is List) {
      final out = <String>[];
      for (final item in text) {
        if (item is String) {
          out.add(_clean(item));
        } else if (item is List) {
          // Nested (spanning) — flatten one more level.
          out.add(_clean(item.whereType<String>().join(' ')));
        }
      }
      return out;
    }
    return const [];
  }

  SeforimAttribution? _attribution(Map<String, dynamic>? v) {
    if (v == null) return null;
    return SeforimAttribution(
      versionTitle: (v['versionTitle'] ?? '') as String,
      source: (v['versionSource'] ?? '') as String,
      license: (v['license'] ?? '') as String,
    );
  }

  // ------------------------------------------------------------------ search
  Future<List<SeforimSearchResult>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final res = await _client
        .post(
          _uri('/api/search-wrapper'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': q,
            'type': 'text',
            // `field` is required by the search-wrapper; "exact" matches the
            // literal phrase across Hebrew and English text.
            'field': 'exact',
            'source_proj': true,
            'size': 30,
            'slop': 10,
          }),
        )
        .timeout(SeforimConfig.timeout);
    if (res.statusCode != 200) {
      throw Exception('Sefaria search ${res.statusCode}');
    }
    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final hits = (data['hits']?['hits'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();
    final out = <SeforimSearchResult>[];
    for (final h in hits) {
      final src = h['_source'] as Map<String, dynamic>? ?? const {};
      final ref = (src['ref'] ?? '') as String;
      if (ref.isEmpty) continue;
      final highlight = h['highlight'] as Map<String, dynamic>?;
      final snippetParts = (highlight?['exact'] ??
          highlight?['naive_lemmatizer'] ??
          const []) as List;
      final snippet = snippetParts.isNotEmpty
          ? _clean(snippetParts.first.toString())
          : _clean((src['exact'] ?? src['content'] ?? '').toString());
      out.add(SeforimSearchResult(
        ref: ref,
        heRef: (src['heRef'] ?? '') as String,
        snippet: snippet,
      ));
    }
    return out;
  }

  // ------------------------------------------------------------------ helpers
  /// Strip residual HTML tags/entities that survive `return_format=text_only`
  /// (footnote markers, search highlight tags, etc.).
  String _clean(String input) {
    var s = input.replaceAll(RegExp(r'<[^>]*>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&thinsp;', ' ');
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

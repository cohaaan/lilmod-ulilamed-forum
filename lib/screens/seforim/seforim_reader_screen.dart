import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/seforim_config.dart';
import '../../data/repositories.dart';
import '../../data/seforim_clipboard.dart';
import '../../models/seforim.dart';
import '../../theme/app_colors.dart';
import '../../theme/seforim_palette.dart';
import '../../widgets/async.dart';
import '../../theme/app_text.dart';

enum _ReaderLang { both, hebrew, english }

/// Display order for related-text categories under a verse (mirrors Sefaria).
const _relatedOrder = [
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

/// Hebrew labels for those categories.
const _relatedHeLabels = {
  'Commentary': 'מפרשים',
  'Targum': 'תרגום',
  'Midrash': 'מדרש',
  'Talmud': 'תלמוד',
  'Halakhah': 'הלכה',
  'Kabbalah': 'קבלה',
  'Chasidut': 'חסידות',
  'Musar': 'מוסר',
  'Jewish Thought': 'מחשבה',
};

/// Reading view for a section of text. Hebrew (RTL) + English interleaved on a
/// paper surface. Tapping a verse selects it — the selection highlights, its
/// mekoros open, and per-verse actions ("copy to reply") surface for that verse
/// only, so the rest of the page stays quiet and reads like a page.
class SeforimReaderScreen extends StatefulWidget {
  const SeforimReaderScreen({super.key, required this.reference});

  final String reference;

  @override
  State<SeforimReaderScreen> createState() => _SeforimReaderScreenState();
}

class _SeforimReaderScreenState extends State<SeforimReaderScreen> {
  final ScrollController _controller = ScrollController();

  /// Anchors the scroll position of the section that first loaded, so that
  /// prepending an earlier section above it doesn't jump the viewport.
  final GlobalKey _centerKey = GlobalKey();

  /// Contiguous sections currently loaded, top → bottom. Grows as the reader
  /// scrolls: [SeforimPassage.next] appends the section below, [prev] prepends
  /// the one above. The repository's passage cache backs the fetches.
  final List<SeforimPassage> _sections = [];

  /// Index within [_sections] of the first-loaded section (the scroll anchor).
  /// Prepends insert above it and bump this; appends go below.
  int _anchorIndex = 0;

  late String _ref = widget.reference;
  late Future<SeforimPassage> _future = _loadInitial(_ref);
  _ReaderLang _lang = _ReaderLang.both;

  /// Ref of the currently-selected verse (e.g. "Genesis 1:3"), or null.
  /// Selection lives on the list — not per-card — so exactly one verse is
  /// active at a time.
  String? _selectedRef;

  bool _loadingNext = false;
  bool _loadingPrev = false;
  bool _appendFailed = false;
  bool _prependFailed = false;

  /// Distance (px) from an edge at which we start fetching the adjacent
  /// section — far enough that the next page is usually ready before it shows.
  static const _fetchThreshold = 900.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  /// (Re)load from a fresh reference: reset the accumulated sections and seed
  /// the list with the first section once it resolves. Returning the seeding
  /// future means [AsyncView] shows the loading/error/retry states, and
  /// [_sections] is already populated by the time the builder runs.
  Future<SeforimPassage> _loadInitial(String ref) {
    _sections.clear();
    _anchorIndex = 0;
    _loadingNext = _loadingPrev = false;
    _appendFailed = _prependFailed = false;
    return seforimRepository.fetchPassage(ref).then((p) {
      _sections.add(p);
      return p;
    });
  }

  void _reload(String ref) {
    setState(() {
      _ref = ref;
      _selectedRef = null;
      _future = _loadInitial(ref);
    });
  }

  void _onScroll() {
    if (!_controller.hasClients || _sections.isEmpty) return;
    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - _fetchThreshold) {
      _appendNext();
    }
    // Only prepend when the user is actively scrolling up, so a cold deep-link
    // to a mid-book ref doesn't cascade-load the whole book above it on open.
    if (pos.userScrollDirection == ScrollDirection.forward &&
        pos.pixels <= pos.minScrollExtent + _fetchThreshold) {
      _prependPrev();
    }
  }

  Future<void> _appendNext() async {
    if (_loadingNext || _appendFailed || _sections.isEmpty) return;
    final nextRef = _sections.last.next;
    if (nextRef == null) return;
    setState(() => _loadingNext = true);
    try {
      final p = await seforimRepository.fetchPassage(nextRef);
      if (!mounted) return;
      setState(() {
        _loadingNext = false;
        if (!_sections.any((s) => s.ref == p.ref)) _sections.add(p);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingNext = false;
        _appendFailed = true;
      });
    }
  }

  Future<void> _prependPrev() async {
    if (_loadingPrev || _prependFailed || _sections.isEmpty) return;
    final prevRef = _sections.first.prev;
    if (prevRef == null) return;
    setState(() => _loadingPrev = true);
    try {
      final p = await seforimRepository.fetchPassage(prevRef);
      if (!mounted) return;
      setState(() {
        _loadingPrev = false;
        if (!_sections.any((s) => s.ref == p.ref)) {
          _sections.insert(0, p);
          _anchorIndex += 1;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPrev = false;
        _prependFailed = true;
      });
    }
  }

  /// Toggle selection of a verse (tapping the active verse deselects it).
  void _select(String verseRef) => setState(
        () => _selectedRef = _selectedRef == verseRef ? null : verseRef,
      );

  void _copyToReply(SeforimPassage p, SeforimSegment seg) {
    final threadId = seforimClipboard.addSegmentForReply(
      ref: '${p.ref}:${seg.number}',
      heRef: p.heRef,
      segment: seg,
    );
    if (threadId != null) {
      context.go('/threads/$threadId');
      return;
    }
    _toast('Added to reply — open a thread to insert it',
        icon: Icons.reply_rounded);
  }

  void _copyCommentToReply(SeforimComment c) {
    final threadId = seforimClipboard.addSegmentForReply(
      ref: c.ref,
      heRef: c.heRef,
      segment: SeforimSegment(number: '', he: c.he, en: c.en),
    );
    if (threadId != null) {
      context.go('/threads/$threadId');
      return;
    }
    _toast('Added to reply — open a thread to insert it',
        icon: Icons.reply_rounded);
  }

  void _toast(String msg, {IconData icon = Icons.check_rounded}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg,
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeforimPalette.paper,
      appBar: AppBar(
        backgroundColor: SeforimPalette.paper,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/seforim'),
        ),
        title: Text(
          _ref,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.ebGaramond(
              fontSize: 19, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        actions: [
          PopupMenuButton<_ReaderLang>(
            tooltip: 'Language',
            icon: const Icon(Icons.translate_rounded, size: 20),
            initialValue: _lang,
            onSelected: (v) => setState(() => _lang = v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _ReaderLang.both, child: Text('Hebrew & English')),
              PopupMenuItem(value: _ReaderLang.hebrew, child: Text('Hebrew only')),
              PopupMenuItem(value: _ReaderLang.english, child: Text('English only')),
            ],
          ),
        ],
      ),
      body: AsyncView<SeforimPassage>(
        future: _future,
        onRetry: () => _reload(_ref),
        builder: (context, p) {
          if (_sections.isEmpty || p.segments.isEmpty) {
            return Center(
              child: Text(
                'No text available for this section.',
                style: AppText.inter(fontSize: 14, color: AppColors.muted),
              ),
            );
          }
          // Segments exist but none are visible in the selected language
          // (e.g. "English only" on a text with no translation) — otherwise the
          // body would render blank with no explanation.
          final hasVisible = p.segments.any((seg) =>
              (_lang != _ReaderLang.english && seg.hasHe) ||
              (_lang != _ReaderLang.hebrew && seg.hasEn));
          if (!hasVisible) {
            final lang = _lang == _ReaderLang.english ? 'English' : 'Hebrew';
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No $lang text available for this section.\n'
                  'Try switching language from the menu above.',
                  textAlign: TextAlign.center,
                  style: AppText.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ),
            );
          }
          return SelectionArea(
            child: CustomScrollView(
              controller: _controller,
              center: _centerKey,
              slivers: [
                // Sections above the anchor grow upward, so they're listed
                // nearest-anchor-first; the top status sits above them all.
                SliverList(
                  delegate: SliverChildListDelegate([
                    for (var i = _anchorIndex - 1; i >= 0; i--)
                      _sectionSlab(_sections[i]),
                    _topStatus(),
                  ]),
                ),
                // The anchor section and everything below it.
                SliverList(
                  key: _centerKey,
                  delegate: SliverChildListDelegate([
                    for (var i = _anchorIndex; i < _sections.length; i++)
                      _sectionSlab(_sections[i]),
                    _bottomStatus(_sections.last),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// One loaded section: its Hebrew heading followed by its verses.
  Widget _sectionSlab(SeforimPassage p) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.heRef.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 10),
              child: Column(
                children: [
                  Text(
                    p.heRef,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.frankRuhlLibre(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                      width: 40, height: 2, color: SeforimPalette.paperLine),
                ],
              ),
            ),
          for (final seg in p.segments)
            _SegmentView(
              segment: seg,
              lang: _lang,
              verseRef: '${p.ref}:${seg.number}',
              selected: _selectedRef == '${p.ref}:${seg.number}',
              onTap: () => _select('${p.ref}:${seg.number}'),
              onCopyToReply: () => _copyToReply(p, seg),
              onCopyComment: _copyCommentToReply,
            ),
        ],
      ),
    );
  }

  /// Loading / retry affordance shown above the topmost loaded section.
  Widget _topStatus() {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        children: [
          if (_loadingPrev)
            _loaderRow()
          else if (_prependFailed)
            _retryRow("Couldn't load the previous section", () {
              setState(() => _prependFailed = false);
              _prependPrev();
            }),
        ],
      ),
    );
  }

  /// Loading / retry / end-of-text and attribution below the last section.
  Widget _bottomStatus(SeforimPassage last) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loadingNext)
            _loaderRow()
          else if (_appendFailed)
            _retryRow("Couldn't load the next section", () {
              setState(() => _appendFailed = false);
              _appendNext();
            })
          else if (last.next == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                last.book.isNotEmpty ? 'End of ${last.book}' : 'End of text',
                textAlign: TextAlign.center,
                style: AppText.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          const SizedBox(height: 16),
          _Attribution(passage: last),
        ],
      ),
    );
  }

  Widget _loaderRow() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );

  Widget _retryRow(String message, VoidCallback onRetry) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.inter(fontSize: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.indigo),
            ),
          ],
        ),
      );
}

/// One verse on the paper page. Flows quietly by default; when [selected] it
/// highlights, reveals its mekoros, and surfaces the per-verse "copy to reply"
/// action. Selection state is owned by the reader, not the card.
class _SegmentView extends StatelessWidget {
  const _SegmentView({
    required this.segment,
    required this.lang,
    required this.verseRef,
    required this.selected,
    required this.onTap,
    required this.onCopyToReply,
    required this.onCopyComment,
  });

  final SeforimSegment segment;
  final _ReaderLang lang;
  final String verseRef;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onCopyToReply;
  final void Function(SeforimComment) onCopyComment;

  @override
  Widget build(BuildContext context) {
    final showHe = lang != _ReaderLang.english && segment.hasHe;
    final showEn = lang != _ReaderLang.hebrew && segment.hasEn;
    if (!showHe && !showEn) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: selected
          ? BoxDecoration(
              color: SeforimPalette.paperSelected,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.indigo.withValues(alpha: 0.22),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 7),
                      child: Text(
                        segment.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.ebGaramond(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: selected ? AppColors.indigo : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showHe)
                          Text(
                            segment.he,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.frankRuhlLibre(
                              fontSize: 23,
                              height: 2.0,
                              color: AppColors.ink,
                            ),
                          ),
                        if (showHe && showEn) const SizedBox(height: 10),
                        if (showEn)
                          Text(
                            segment.en,
                            style: GoogleFonts.ebGaramond(
                              fontSize: 17,
                              height: 1.75,
                              color: AppColors.body,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selected) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: _VerseCommentaries(
                verseRef: verseRef,
                lang: lang,
                onCopyToReply: onCopyComment,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: _SegmentAction(
                  icon: Icons.reply_rounded,
                  label: 'Copy to reply',
                  primary: true,
                  onTap: onCopyToReply,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Related texts (mekoros) for a verse — shown when the verse text is tapped.
/// Fetches lazily on first open.
class _VerseCommentaries extends StatefulWidget {
  const _VerseCommentaries({
    required this.verseRef,
    required this.lang,
    required this.onCopyToReply,
  });

  final String verseRef;
  final _ReaderLang lang;
  final void Function(SeforimComment) onCopyToReply;

  @override
  State<_VerseCommentaries> createState() => _VerseCommentariesState();
}

class _VerseCommentariesState extends State<_VerseCommentaries> {
  Future<List<SeforimComment>>? _future;

  @override
  void initState() {
    super.initState();
    _future = seforimRepository.fetchRelated(widget.verseRef);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SeforimComment>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Text(
              'Could not load mekoros.',
              style:
                  AppText.inter(fontSize: 12.5, color: AppColors.muted),
            ),
          );
        }
        final items = snap.data ?? const <SeforimComment>[];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 4),
            child: Text(
              'No mekoros on this verse.',
              style:
                  AppText.inter(fontSize: 12.5, color: AppColors.muted),
            ),
          );
        }
        final byCat = <String, List<SeforimComment>>{};
        for (final c in items) {
          byCat.putIfAbsent(c.category, () => []).add(c);
        }
        final cats = _relatedOrder.where(byCat.containsKey).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
              child: Text(
                'מקורות',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.frankRuhlLibre(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.indigo,
                ),
              ),
            ),
            for (final cat in cats)
              _RelatedCategory(
                category: cat,
                items: byCat[cat]!,
                lang: widget.lang,
                onCopyToReply: widget.onCopyToReply,
              ),
          ],
        );
      },
    );
  }
}

/// A related-text category (Commentary, Midrash, …): a small header with a
/// count, above its works grouped by title.
class _RelatedCategory extends StatelessWidget {
  const _RelatedCategory({
    required this.category,
    required this.items,
    required this.lang,
    required this.onCopyToReply,
  });

  final String category;
  final List<SeforimComment> items;
  final _ReaderLang lang;
  final void Function(SeforimComment) onCopyToReply;

  @override
  Widget build(BuildContext context) {
    // Group the works within this category, preserving order.
    final order = <String>[];
    final byWork = <String, List<SeforimComment>>{};
    for (final c in items) {
      byWork.putIfAbsent(c.commentator, () {
        order.add(c.commentator);
        return <SeforimComment>[];
      }).add(c);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 2),
          child: Row(
            children: [
              Text(
                _relatedHeLabels[category] ?? category,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.frankRuhlLibre(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${category.toUpperCase()} · ${order.length}',
                style: AppText.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        for (final name in order)
          _CommentatorTile(
            name: name,
            heName: byWork[name]!.first.heCommentator,
            comments: byWork[name]!,
            lang: lang,
            onCopyToReply: onCopyToReply,
          ),
      ],
    );
  }
}

/// One commentator (Rashi, Ramban, …) as a collapsible tile holding its
/// comment(s) on the verse.
class _CommentatorTile extends StatefulWidget {
  const _CommentatorTile({
    required this.name,
    required this.heName,
    required this.comments,
    required this.lang,
    required this.onCopyToReply,
  });

  final String name;
  final String heName;
  final List<SeforimComment> comments;
  final _ReaderLang lang;
  final void Function(SeforimComment) onCopyToReply;

  @override
  State<_CommentatorTile> createState() => _CommentatorTileState();
}

class _CommentatorTileState extends State<_CommentatorTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final hasHe = widget.heName.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SeforimPalette.paperLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      hasHe ? widget.heName : widget.name,
                      textDirection:
                          hasHe ? TextDirection.rtl : TextDirection.ltr,
                      style: GoogleFonts.frankRuhlLibre(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final c in widget.comments)
                    _LazyCommentText(
                      source: c,
                      lang: widget.lang,
                      onCopyToReply: widget.onCopyToReply,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Lazily loads one related source's text on expand, and offers copy-to-reply
/// carrying the loaded Hebrew/English.
class _LazyCommentText extends StatefulWidget {
  const _LazyCommentText({
    required this.source,
    required this.lang,
    required this.onCopyToReply,
  });

  final SeforimComment source;
  final _ReaderLang lang;
  final void Function(SeforimComment) onCopyToReply;

  @override
  State<_LazyCommentText> createState() => _LazyCommentTextState();
}

class _LazyCommentTextState extends State<_LazyCommentText> {
  late final Future<({String he, String en})> _future =
      seforimRepository.fetchSourceText(widget.source.ref);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({String he, String en})>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              'Could not load this source.',
              style:
                  AppText.inter(fontSize: 12.5, color: AppColors.muted),
            ),
          );
        }
        final he = snap.data?.he ?? '';
        final en = snap.data?.en ?? '';
        final showHe = widget.lang != _ReaderLang.english && he.isNotEmpty;
        final showEn = widget.lang != _ReaderLang.hebrew && en.isNotEmpty;
        if (!showHe && !showEn) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHe)
              Text(
                he,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.frankRuhlLibre(
                  fontSize: 17,
                  height: 1.7,
                  color: AppColors.ink,
                ),
              ),
            if (showHe && showEn) const SizedBox(height: 6),
            if (showEn)
              Text(
                en,
                style: AppText.inter(
                  fontSize: 13.5,
                  height: 1.55,
                  color: AppColors.body,
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _SegmentAction(
                icon: Icons.reply_rounded,
                label: 'Copy to reply',
                primary: true,
                onTap: () => widget.onCopyToReply(
                  SeforimComment(
                    category: widget.source.category,
                    commentator: widget.source.commentator,
                    heCommentator: widget.source.heCommentator,
                    ref: widget.source.ref,
                    heRef: widget.source.heRef,
                    he: he,
                    en: en,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        );
      },
    );
  }
}

class _SegmentAction extends StatelessWidget {
  const _SegmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final color = primary ? AppColors.indigo : AppColors.muted;
    return Material(
      color: primary
          ? AppColors.indigo.withValues(alpha: 0.10)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppText.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Source attribution for the section. Renders each version's title, its
/// digitization source (`versionSource`) and license, plus a link back to the
/// passage on Sefaria — both the source credit and the link-back are required
/// by the project's legal rules (see SEFORIM_PLAN.md).
class _Attribution extends StatelessWidget {
  const _Attribution({required this.passage});

  final SeforimPassage passage;

  static Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Prettier label for a `versionSource`: its host if it's a URL, else raw.
  static String _sourceLabel(String source) {
    final u = Uri.tryParse(source);
    if (u != null && u.hasScheme && u.host.isNotEmpty) return u.host;
    return source;
  }

  @override
  Widget build(BuildContext context) {
    final versions = <SeforimAttribution>[
      if (passage.heAttribution != null) passage.heAttribution!,
      if (passage.enAttribution != null) passage.enAttribution!,
    ].where((a) =>
        a.versionTitle.isNotEmpty ||
        a.source.isNotEmpty ||
        a.license.isNotEmpty).toList();

    final webUrl =
        passage.ref.isNotEmpty ? SeforimConfig.webUrl(passage.ref) : '';
    if (versions.isEmpty && webUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: SeforimPalette.paperLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOURCE',
            style: AppText.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          for (final a in versions) ...[
            const SizedBox(height: 6),
            if (a.versionTitle.isNotEmpty || a.license.isNotEmpty)
              Text(
                [
                  if (a.versionTitle.isNotEmpty) a.versionTitle,
                  if (a.license.isNotEmpty) a.license,
                ].join(' · '),
                style: AppText.inter(fontSize: 11.5, color: AppColors.muted),
              ),
            if (a.source.isNotEmpty)
              _LinkText(
                label: _sourceLabel(a.source),
                onTap: Uri.tryParse(a.source)?.hasScheme ?? false
                    ? () => _open(a.source)
                    : null,
              ),
          ],
          if (webUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _open(webUrl),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View this passage on Sefaria',
                      style: AppText.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded,
                        size: 13, color: AppColors.indigo),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A short attribution line that's tappable (a link) when [onTap] is given,
/// and plain muted text otherwise.
class _LinkText extends StatelessWidget {
  const _LinkText({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: AppText.inter(
        fontSize: 11.5,
        color: onTap != null ? AppColors.indigo : AppColors.muted,
        decoration: onTap != null ? TextDecoration.underline : null,
      ),
    );
    if (onTap == null) return text;
    return InkWell(onTap: onTap, child: text);
  }
}

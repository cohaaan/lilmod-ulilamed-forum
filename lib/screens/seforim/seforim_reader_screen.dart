import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories.dart';
import '../../data/seforim_clipboard.dart';
import '../../models/seforim.dart';
import '../../theme/app_colors.dart';
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

/// Reading view for a section of text. Hebrew (RTL) + English, with prev/next
/// navigation, tap-to-expand mekoros, and "copy to reply" per segment.
class SeforimReaderScreen extends StatefulWidget {
  const SeforimReaderScreen({super.key, required this.reference});

  final String reference;

  @override
  State<SeforimReaderScreen> createState() => _SeforimReaderScreenState();
}

class _SeforimReaderScreenState extends State<SeforimReaderScreen> {
  late String _ref = widget.reference;
  late Future<SeforimPassage> _future = seforimRepository.fetchPassage(_ref);
  _ReaderLang _lang = _ReaderLang.both;

  void _load(String ref) {
    setState(() {
      _ref = ref;
      _future = seforimRepository.fetchPassage(ref);
    });
  }

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
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
        onRetry: () => _load(_ref),
        builder: (context, p) {
          if (p.segments.isEmpty) {
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
            child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              if (p.heRef.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18, top: 4),
                  child: Column(
                    children: [
                      Text(
                        p.heRef,
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.frankRuhlLibre(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(width: 40, height: 2, color: AppColors.line),
                    ],
                  ),
                ),
              ...p.segments.map((seg) => _SegmentCard(
                    segment: seg,
                    lang: _lang,
                    verseRef: '${p.ref}:${seg.number}',
                    onCopyToReply: () => _copyToReply(p, seg),
                    onCopyComment: _copyCommentToReply,
                  )),
              const SizedBox(height: 16),
              _NavRow(
                onPrev: p.prev == null ? null : () => _load(p.prev!),
                onNext: p.next == null ? null : () => _load(p.next!),
              ),
              const SizedBox(height: 16),
              _Attribution(passage: p),
            ],
            ),
          );
        },
      ),
    );
  }
}

class _SegmentCard extends StatefulWidget {
  const _SegmentCard({
    required this.segment,
    required this.lang,
    required this.verseRef,
    required this.onCopyToReply,
    required this.onCopyComment,
  });

  final SeforimSegment segment;
  final _ReaderLang lang;
  final String verseRef;
  final VoidCallback onCopyToReply;
  final void Function(SeforimComment) onCopyComment;

  @override
  State<_SegmentCard> createState() => _SegmentCardState();
}

class _SegmentCardState extends State<_SegmentCard> {
  bool _mekorosOpen = false;

  void _toggleMekoros() => setState(() => _mekorosOpen = !_mekorosOpen);

  @override
  Widget build(BuildContext context) {
    final showHe =
        widget.lang != _ReaderLang.english && widget.segment.hasHe;
    final showEn = widget.lang != _ReaderLang.hebrew && widget.segment.hasEn;
    if (!showHe && !showEn) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: _mekorosOpen
                ? AppColors.indigo.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _toggleMekoros,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          widget.segment.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.ebGaramond(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
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
                              widget.segment.he,
                              textDirection: TextDirection.rtl,
                              style: GoogleFonts.frankRuhlLibre(
                                fontSize: 22,
                                height: 1.9,
                                color: AppColors.ink,
                              ),
                            ),
                          if (showHe && showEn) const SizedBox(height: 8),
                          if (showEn)
                            Text(
                              widget.segment.en,
                              style: GoogleFonts.ebGaramond(
                                fontSize: 16.5,
                                height: 1.7,
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
          ),
          if (_mekorosOpen)
            _VerseCommentaries(
              verseRef: widget.verseRef,
              lang: widget.lang,
              onCopyToReply: widget.onCopyComment,
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: _SegmentAction(
              icon: Icons.reply_rounded,
              label: 'Copy to reply',
              primary: true,
              onTap: widget.onCopyToReply,
            ),
          ),
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
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
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

class _NavRow extends StatelessWidget {
  const _NavRow({required this.onPrev, required this.onNext});

  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.indigo,
              side: BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            label: const Text('Next'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.indigo,
              side: BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Attribution extends StatelessWidget {
  const _Attribution({required this.passage});

  final SeforimPassage passage;

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];
    void add(SeforimAttribution? a) {
      if (a == null) return;
      final bits = [
        if (a.versionTitle.isNotEmpty) a.versionTitle,
        if (a.license.isNotEmpty) a.license,
      ];
      if (bits.isNotEmpty) lines.add(bits.join(' · '));
    }

    add(passage.heAttribution);
    add(passage.enAttribution);
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source',
            style: AppText.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          for (final l in lines)
            Text(
              l,
              style: AppText.inter(fontSize: 11.5, color: AppColors.muted),
            ),
        ],
      ),
    );
  }
}

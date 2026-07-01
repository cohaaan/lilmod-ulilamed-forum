import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';
import '../../theme/app_text.dart';

/// Table of contents for a book: a grid of chapters (or daf for Talmud), or a
/// list of sub-sections for a complex work. Tapping a section opens the reader.
class SeforimBookScreen extends StatefulWidget {
  const SeforimBookScreen({super.key, required this.title, this.node});

  final String title;
  final SeforimNode? node;

  @override
  State<SeforimBookScreen> createState() => _SeforimBookScreenState();
}

class _SeforimBookScreenState extends State<SeforimBookScreen> {
  late Future<List<ShapeNode>> _future =
      seforimRepository.fetchShape(widget.title);

  late bool _isTalmud = widget.node?.isTalmud ?? false;

  @override
  void initState() {
    super.initState();
    // On a cold deep-link no node is passed, so recover Talmud addressing from
    // the index — otherwise a tractate renders as numeric chapters and produces
    // refs that 404 in the reader.
    if (widget.node == null) {
      seforimRepository.findBook(widget.title).then((node) {
        if (mounted && !_isTalmud && (node?.isTalmud ?? false)) {
          setState(() => _isTalmud = true);
        }
      });
    }
  }

  void _openRef(String ref) =>
      context.push('/seforim/read/${Uri.encodeComponent(ref)}');

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
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.ebGaramond(
              fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
      ),
      body: AsyncView<List<ShapeNode>>(
        future: _future,
        onRetry: () =>
            setState(() => _future = seforimRepository.fetchShape(widget.title)),
        builder: (context, nodes) {
          // Complex / multi-part work: list each part; the reader handles the
          // rest via prev/next.
          final simple = nodes.length == 1 && nodes.first.isSimple;
          if (!simple) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ..._header(),
                for (var i = 0; i < nodes.length; i++)
                  _SectionRow(
                    label: nodes[i].title.isEmpty
                        ? widget.title
                        : nodes[i].title,
                    heLabel: nodes[i].heTitle,
                    showDivider: i != nodes.length - 1,
                    onTap: () => _openRef(
                      nodes[i].title.isEmpty ? widget.title : nodes[i].title,
                    ),
                  ),
              ],
            );
          }

          final entries = _entries(nodes.first);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              ..._header(),
              Text(
                _isTalmud ? 'Dapim' : 'Chapters',
                style: GoogleFonts.ebGaramond(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final e in entries)
                    _ChapterChip(label: e.label, onTap: () => _openRef(e.ref)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Book header: Hebrew title + short description, when navigation passed the
  /// node (omitted on a cold deep-link where only the title is known).
  List<Widget> _header() {
    final node = widget.node;
    if (node == null) return const [];
    return [
      if (node.heLabel.isNotEmpty)
        Text(
          node.heLabel,
          textDirection: TextDirection.rtl,
          style: GoogleFonts.frankRuhlLibre(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      if (node.description.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          node.description,
          style: AppText.inter(
            fontSize: 13.5,
            height: 1.45,
            color: AppColors.muted,
          ),
        ),
      ],
      const SizedBox(height: 18),
    ];
  }

  /// Build the tappable entries for a simple book, respecting daf vs chapter
  /// addressing.
  List<({String label, String ref})> _entries(ShapeNode node) {
    final out = <({String label, String ref})>[];
    if (_isTalmud) {
      // Talmud chapters list is indexed by daf-half from daf 1; skip empties.
      for (var i = 0; i < node.chapters.length; i++) {
        if (node.chapters[i] <= 0) continue;
        final daf = (i ~/ 2) + 1;
        final side = i.isEven ? 'a' : 'b';
        final label = '$daf$side';
        out.add((label: label, ref: '${widget.title} $label'));
      }
    } else {
      final n = node.chapters.isNotEmpty ? node.chapters.length : node.length;
      for (var i = 1; i <= n; i++) {
        out.add((label: '$i', ref: '${widget.title} $i'));
      }
    }
    return out;
  }
}

class _ChapterChip extends StatelessWidget {
  const _ChapterChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minWidth: 56, minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.ebGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.label,
    required this.heLabel,
    required this.onTap,
    required this.showDivider,
  });

  final String label;
  final String heLabel;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return seforimSectionRow(
      label: label,
      heLabel: heLabel,
      onTap: onTap,
      showDivider: showDivider,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/seforim_palette.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';

/// Table of contents for a book, Sefaria-style: the title in Cardo over a
/// small-caps category line, a navy "Start Reading" button, and a grid of
/// chapter (or daf) boxes — or a list of sub-sections for a complex work.
/// Tapping a section opens the reader.
class SeforimBookScreen extends StatefulWidget {
  const SeforimBookScreen({super.key, required this.title, this.node});

  final String title;
  final SeforimNode? node;

  @override
  State<SeforimBookScreen> createState() => _SeforimBookScreenState();
}

class _SeforimBookScreenState extends State<SeforimBookScreen> {
  late Future<List<ShapeNode>> _future = seforimRepository.fetchShape(
    widget.title,
  );

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
      backgroundColor: SeforimPalette.paper,
      appBar: AppBar(
        backgroundColor: SeforimPalette.paper,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/seforim'),
        ),
      ),
      body: AsyncView<List<ShapeNode>>(
        future: _future,
        onRetry: () => setState(
          () => _future = seforimRepository.fetchShape(widget.title),
        ),
        builder: (context, nodes) {
          // Complex / multi-part work: list each part; the reader handles the
          // rest via prev/next.
          final simple = nodes.length == 1 && nodes.first.isSimple;
          if (!simple) {
            final firstRef = nodes.isEmpty || nodes.first.title.isEmpty
                ? widget.title
                : nodes.first.title;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                ..._header(startRef: firstRef),
                for (var i = 0; i < nodes.length; i++)
                  seforimSectionRow(
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
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              ..._header(startRef: entries.isEmpty ? null : entries.first.ref),
              Text(
                _isTalmud ? 'Daf' : 'Chapter',
                style: SeforimText.sans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: SeforimPalette.secondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in entries)
                    _SectionBox(label: e.label, onTap: () => _openRef(e.ref)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// Book header, Sefaria TOC style: Cardo title, small-caps category line,
  /// Hebrew title, description, and a navy "Start Reading" button.
  List<Widget> _header({String? startRef}) {
    final node = widget.node;
    final category = node?.colorKey ?? '';
    return [
      Text(
        widget.title,
        style: SeforimText.serif(
          fontSize: 30,
          color: SeforimPalette.black,
          height: 1.2,
        ),
      ),
      if (node != null && node.heLabel.isNotEmpty) ...[
        const SizedBox(height: 2),
        Text(
          node.heLabel,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.left,
          style: SeforimText.hebrew(fontSize: 22, color: SeforimPalette.black),
        ),
      ],
      if (category.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(
          category.toUpperCase(),
          style: SeforimText.sans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: SeforimPalette.tertiary,
          ),
        ),
      ],
      if (node != null && node.description.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          node.description,
          style: SeforimText.sans(
            fontSize: 14,
            height: 1.35,
            color: SeforimPalette.secondary,
          ),
        ),
      ],
      if (startRef != null) ...[
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            onPressed: () => _openRef(startRef),
            style: FilledButton.styleFrom(
              backgroundColor: SeforimPalette.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: SeforimText.sans(fontSize: 16),
            ),
            child: const Text('Start Reading'),
          ),
        ),
      ],
      const SizedBox(height: 22),
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

/// One chapter/daf box in the TOC grid — Sefaria's faint square with a serif
/// grey numeral.
class _SectionBox extends StatelessWidget {
  const _SectionBox({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SeforimPalette.faint,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        // Shrink-wraps to the label (so boxes tile in the Wrap) but never
        // smaller than a 50px square, like Sefaria's section grid.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                label,
                style: SeforimText.serif(
                  fontSize: 18,
                  color: SeforimPalette.secondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

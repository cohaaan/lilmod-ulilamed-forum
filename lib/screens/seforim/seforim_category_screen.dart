import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../data/seforim_prefs.dart';
import '../../models/seforim.dart';
import '../../theme/seforim_palette.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';

/// A category page, Sefaria-style: the category name in caps over its colour
/// rule, then its contents with sub-groups flattened one level under
/// small-caps headers ("SEDER ZERAIM (Agriculture)", "HALAKHAH (Law)"), the
/// way Sefaria lays out Mishnah/Midrash/etc. Normally handed its [node] via
/// `extra`; on a cold deep-link it falls back to locating a matching
/// top-level category.
class SeforimCategoryScreen extends StatefulWidget {
  const SeforimCategoryScreen({super.key, required this.label, this.node});

  final String label;
  final SeforimNode? node;

  @override
  State<SeforimCategoryScreen> createState() => _SeforimCategoryScreenState();
}

class _SeforimCategoryScreenState extends State<SeforimCategoryScreen> {
  late Future<SeforimNode> _future = _resolve();

  Future<SeforimNode> _resolve() async {
    final passed = widget.node;
    if (passed != null) return passed;
    // Cold deep-link: find a top-level category with this label.
    final index = await seforimRepository.fetchIndex();
    return index.firstWhere(
      (n) => n.label == widget.label,
      orElse: () => SeforimNode(category: widget.label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = SeforimPalette.forCategory(widget.label);
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: SeforimLangToggle()),
          ),
        ],
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: seforimHebrewMode,
        builder: (context, hebrew, _) => AsyncView<SeforimNode>(
          future: _future,
          onRetry: () => setState(() => _future = _resolve()),
          builder: (context, node) {
            final useHe = hebrew && node.heLabel.isNotEmpty;
            final desc = hebrew && node.heShortDesc.trim().isNotEmpty
                ? node.heShortDesc.trim()
                : node.description;
            final children = node.contents;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                // Category heading: caps name in Cardo over its colour rule
                // (Hebrew name in Hebrew mode), the way Sefaria heads its
                // category pages.
                Align(
                  alignment:
                      useHe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    useHe ? node.heLabel : widget.label.toUpperCase(),
                    textDirection:
                        useHe ? TextDirection.rtl : TextDirection.ltr,
                    style: useHe
                        ? SeforimText.hebrew(
                            fontSize: 28,
                            color: SeforimPalette.black,
                            height: 1.2,
                          )
                        : SeforimText.serif(
                            fontSize: 26,
                            letterSpacing: 0.5,
                            color: SeforimPalette.black,
                            height: 1.2,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment:
                      useHe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(height: 4, width: 56, color: color),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    textDirection:
                        hebrew && node.heShortDesc.trim().isNotEmpty
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                    style: SeforimText.sans(
                      fontSize: 14,
                      height: 1.35,
                      color: SeforimPalette.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                if (children.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Center(
                      child: Text(
                        'Nothing to show here.',
                        style: SeforimText.sans(
                          fontSize: 14,
                          color: SeforimPalette.secondary,
                        ),
                      ),
                    ),
                  )
                else
                  ..._flattened(context, children, hebrew),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Sefaria flattens one level on category pages: a child that is itself a
  /// category renders as a small-caps group header with its own contents
  /// listed beneath; plain books render as rows.
  List<Widget> _flattened(
    BuildContext context,
    List<SeforimNode> children,
    bool hebrew,
  ) {
    final out = <Widget>[];
    for (final child in children) {
      if (child.isCategory && child.contents.isNotEmpty) {
        out.add(seforimGroupHeader(context, node: child, hebrew: hebrew));
        for (final grand in child.contents) {
          out.add(seforimNodeRow(
            context,
            node: grand,
            showColorBar: false,
            hebrew: hebrew,
          ));
        }
      } else {
        out.add(seforimNodeRow(
          context,
          node: child,
          showColorBar: false,
          hebrew: hebrew,
        ));
      }
    }
    return out;
  }
}

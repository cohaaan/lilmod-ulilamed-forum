import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/seforim_palette.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';

/// A sub-level of the library tree, Sefaria-style: the category name as a
/// serif heading over hairline-separated child rows. Normally handed its
/// [node] via `extra`; on a cold deep-link it falls back to locating a
/// matching top-level category.
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
      ),
      body: AsyncView<SeforimNode>(
        future: _future,
        onRetry: () => setState(() => _future = _resolve()),
        builder: (context, node) {
          final children = node.contents;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              // Category heading: name in Cardo over its colour rule, the way
              // Sefaria heads its category pages.
              Text(
                widget.label,
                style: SeforimText.serif(
                  fontSize: 30,
                  color: SeforimPalette.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 4, width: 56, color: color),
              if (node.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  node.description,
                  style: SeforimText.sans(
                    fontSize: 14,
                    height: 1.35,
                    color: SeforimPalette.secondary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
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
                for (final child in children)
                  seforimNodeRow(context, node: child, showColorBar: false),
            ],
          );
        },
      ),
    );
  }
}

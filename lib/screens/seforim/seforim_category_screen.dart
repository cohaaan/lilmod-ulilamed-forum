import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';
import '../../theme/app_text.dart';

/// A sub-level of the library tree. Normally handed its [node] via `extra`;
/// on a cold deep-link it falls back to locating a matching top-level category.
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
          widget.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.ebGaramond(
              fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
      ),
      body: AsyncView<SeforimNode>(
        future: _future,
        onRetry: () => setState(() => _future = _resolve()),
        builder: (context, node) {
          final children = node.contents;
          if (children.isEmpty) {
            return Center(
              child: Text(
                'Nothing to show here.',
                style: AppText.inter(fontSize: 14, color: AppColors.muted),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (node.description.isNotEmpty) ...[
                Text(
                  node.description,
                  style: AppText.inter(
                    fontSize: 13.5,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              for (final child in children)
                seforimNodeRow(context, node: child),
            ],
          );
        },
      ),
    );
  }
}

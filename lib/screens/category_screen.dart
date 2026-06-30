import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/repositories.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../utils/share_link.dart';
import '../widgets/async.dart';
import '../widgets/forum_rows.dart';
import '../widgets/soft_card.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<Category?> _future =
      forumRepository.fetchCategory(widget.categoryId);

  Future<void> _refresh() async {
    setState(() {
      _future = forumRepository.fetchCategory(widget.categoryId);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentForId(widget.categoryId);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/forums'),
        ),
        title: AsyncTitle(
          future: _future,
          fallback: 'Category',
          titleOf: (c) => c?.name ?? 'Category',
        ),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => copyForumLink(
              context,
              '/forums/c/${widget.categoryId}',
              label: 'Category link copied',
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: AsyncView<Category?>(
          future: _future,
          onRetry: _refresh,
          builder: (context, category) {
            if (category == null) {
              return const _Missing();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Text(
                  category.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Subforums',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                SoftCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < category.subforums.length; i++)
                        forumRowTo(
                          context,
                          accent: accent,
                          title: category.subforums[i].name,
                          subtitle: category.subforums[i].description,
                          trailing:
                              '${category.subforums[i].threadCount} threads',
                          path:
                              '/forums/c/${category.id}/s/${category.subforums[i].id}',
                          showDivider: i != category.subforums.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.help_outline_rounded, size: 44, color: AppColors.muted),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Category not found.',
            style: GoogleFonts.inter(color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

/// An AppBar title that resolves from a future without flashing empty.
class AsyncTitle<T> extends StatelessWidget {
  const AsyncTitle({
    super.key,
    required this.future,
    required this.fallback,
    required this.titleOf,
  });

  final Future<T> future;
  final String fallback;
  final String Function(T) titleOf;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        final text = snap.hasData ? titleOf(snap.data as T) : fallback;
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        );
      },
    );
  }
}

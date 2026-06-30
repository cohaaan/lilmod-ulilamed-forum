import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/category.dart';
import '../theme/app_colors.dart';
import '../widgets/async.dart';
import '../widgets/forum_rows.dart';
import '../widgets/soft_card.dart';
import '../widgets/workspace_header.dart';

class ForumsScreen extends StatefulWidget {
  const ForumsScreen({super.key});

  @override
  State<ForumsScreen> createState() => _ForumsScreenState();
}

class _ForumsScreenState extends State<ForumsScreen> {
  late Future<List<Category>> _future = _load();

  Future<List<Category>> _load() => forumRepository.fetchCategories();

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final contentPad = AppColors.useAubergineHeader
        ? const EdgeInsets.fromLTRB(20, 16, 20, 24)
        : const EdgeInsets.fromLTRB(20, 0, 20, 24);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        top: !AppColors.useAubergineHeader,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: contentPad,
            children: [
              const WorkspaceHeader(
                title: 'Forums',
                subtitle: 'Browse all forum categories and subforums.',
              ),
              SizedBox(height: AppColors.useAubergineHeader ? 16 : 18),
              AsyncView<List<Category>>(
                future: _future,
                onRetry: _refresh,
                builder: (context, categories) {
                  final ordered = categories.reversed.toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeading(title: 'Browse by category'),
                      const SizedBox(height: 12),
                      SoftCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            for (var i = 0; i < ordered.length; i++)
                              forumRowTo(
                                context,
                                accent: AppColors.accentAt(i),
                                title: ordered[i].name,
                                subtitle: ordered[i].description,
                                trailing:
                                    '${ordered[i].subforums.length} subforums',
                                path: '/forums/c/${ordered[i].id}',
                                showDivider: i != ordered.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

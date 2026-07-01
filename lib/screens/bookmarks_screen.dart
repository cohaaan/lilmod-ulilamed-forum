import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories.dart';
import '../models/thread.dart';
import '../theme/app_colors.dart';
import '../widgets/async.dart';
import '../widgets/post_card.dart';
import '../theme/app_text.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  late Future<List<Thread>> _future =
      forumRepository.fetchBookmarkedThreads();

  Future<void> _reload() async {
    setState(() {
      _future = forumRepository.fetchBookmarkedThreads();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          'Bookmarks',
          style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: AsyncView<List<Thread>>(
          future: _future,
          onRetry: _reload,
          builder: (context, threads) {
            if (threads.isEmpty) {
              return const _EmptyBookmarks();
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                for (final t in threads) PostCard(thread: t),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyBookmarks extends StatelessWidget {
  const _EmptyBookmarks();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(
          Icons.bookmark_border_rounded,
          size: 44,
          color: AppColors.muted,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'No bookmarks yet. Tap the bookmark icon on a thread to save it.',
            textAlign: TextAlign.center,
            style: AppText.inter(fontSize: 14, color: AppColors.muted),
          ),
        ),
      ],
    );
  }
}

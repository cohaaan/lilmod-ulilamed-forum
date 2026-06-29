import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/mock_data.dart';
import '../models/thread_item.dart';
import '../theme/app_colors.dart';
import '../widgets/content_panel.dart';
import '../widgets/site_scaffold.dart';

ThreadItem _findThread(String id) {
  for (final thread in MockData.recentThreads) {
    if (thread.id == id) return thread;
  }

  for (final thread in MockData.popularThreads) {
    if (thread.id == id) {
      return ThreadItem(
        id: thread.id,
        title: thread.title,
        type: 'Discussion',
        forumName: thread.forumName,
        date: thread.stats,
        postCount: 0,
        viewCount: 0,
        latestActivity: thread.stats,
        openedBy: 'Unknown',
        latestBy: 'Unknown',
        accentColor: thread.accentColor,
      );
    }
  }

  return MockData.recentThreads.first;
}

class ThreadDetailScreen extends StatelessWidget {
  const ThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context) {
    final thread = _findThread(threadId);

    return SiteScaffold(
      child: ContentPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to home'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(thread.type)),
                Chip(label: Text(thread.forumName)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              thread.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${thread.postCount} posts · ${thread.viewCount} views · Opened by ${thread.openedBy}',
              style: GoogleFonts.inter(color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            Text(
              'Thread content will load here once the backend is connected.',
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.6,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/repositories.dart';
import '../models/thread.dart';
import '../theme/app_colors.dart';
import '../utils/share_link.dart';
import '../widgets/async.dart';
import '../widgets/post_card.dart';
import 'compose_thread_screen.dart';

class SubforumScreen extends StatefulWidget {
  const SubforumScreen({
    super.key,
    required this.categoryId,
    required this.subforumId,
  });

  final String categoryId;
  final String subforumId;

  @override
  State<SubforumScreen> createState() => _SubforumScreenState();
}

class _SubforumScreenState extends State<SubforumScreen> {
  late Future<List<Thread>> _future =
      forumRepository.fetchThreadsForSubforum(widget.subforumId);
  String _title = 'Subforum';

  @override
  void initState() {
    super.initState();
    forumRepository.fetchSubforum(widget.subforumId).then((s) {
      if (s != null && mounted) setState(() => _title = s.name);
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _future = forumRepository.fetchThreadsForSubforum(widget.subforumId);
    });
    await _future;
  }

  Future<void> _compose() async {
    final created = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ComposeThreadScreen(
          subforumId: widget.subforumId,
          subforumName: _title,
        ),
      ),
    );
    if (created != null && mounted) {
      await _refresh();
      if (mounted) context.push('/threads/$created');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/forums'),
        ),
        title: Text(
          _title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => copyForumLink(
              context,
              '/forums/c/${widget.categoryId}/s/${widget.subforumId}',
              label: 'Subforum link copied',
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _compose,
        backgroundColor: AppColors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(
          'New thread',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: AsyncView<List<Thread>>(
          future: _future,
          onRetry: _refresh,
          builder: (context, threads) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                Text(
                  threads.isEmpty
                      ? 'No threads yet'
                      : '${threads.length} thread${threads.length == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                if (threads.isEmpty)
                  _EmptyThreads(onStart: _compose)
                else
                  ...threads.map((t) => PostCard(thread: t)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyThreads extends StatelessWidget {
  const _EmptyThreads({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            'Be the first to start a discussion here.',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: const Text('Start a discussion'),
          ),
        ],
      ),
    );
  }
}

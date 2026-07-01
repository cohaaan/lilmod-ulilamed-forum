import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/thread.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/post_card.dart';
import '../theme/app_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late Future<List<Thread>> _future = forumRepository.fetchRecentThreads(limit: 20);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _query = value.trim();
        _future = forumRepository.searchThreads(_query);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search',
                    style: AppText.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search threads…',
                      prefixIcon: Icon(Icons.search_rounded,
                          color: AppColors.muted),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: AppColors.muted),
                              onPressed: () {
                                _controller.clear();
                                _onChanged('');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _query.isEmpty ? 'Recent threads' : 'Results for "$_query"',
                    style: AppText.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Thread>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    );
                  }
                  if (snap.hasError) {
                    return _SearchMessage(
                      icon: Icons.cloud_off_rounded,
                      text: "Couldn't search right now. Try again.",
                    );
                  }
                  final results = snap.data ?? const [];
                  if (results.isEmpty) {
                    return _EmptyState(query: _query);
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, i) {
                      final t = results[i];
                      return CompactPostRow(
                        id: t.id,
                        title: t.title,
                        meta:
                            '${t.subforumName ?? ''} · ${t.authorName} · ${relativeTime(t.lastActivityAt)}',
                        accent: accentForId(t.subforumId),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return _SearchMessage(
      icon: Icons.search_off_rounded,
      text: query.isEmpty ? 'No threads yet.' : 'No results for "$query"',
    );
  }
}

class _SearchMessage extends StatelessWidget {
  const _SearchMessage({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.body,
            ),
          ),
        ],
      ),
    );
  }
}

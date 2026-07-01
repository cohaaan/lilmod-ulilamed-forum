import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';
import '../../theme/app_text.dart';

/// Full-text search across the library, debounced. Tapping a hit opens the
/// reader at that reference.
class SeforimSearchScreen extends StatefulWidget {
  const SeforimSearchScreen({super.key});

  @override
  State<SeforimSearchScreen> createState() => _SeforimSearchScreenState();
}

class _SeforimSearchScreenState extends State<SeforimSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  Future<List<SeforimSearchResult>>? _future;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final q = value.trim();
      if (q == _query) return;
      setState(() {
        _query = q;
        _future = q.isEmpty ? null : seforimRepository.search(q);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/seforim'),
        ),
        title: Text(
          'Search seforim',
          style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Search texts, e.g. “tzedakah”…',
                prefixIcon: Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surfaceMuted,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _buildResults()),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final future = _future;
    if (future == null) {
      return _Hint(
        icon: Icons.menu_book_rounded,
        text: 'Search across the whole library.',
      );
    }
    return FutureBuilder<List<SeforimSearchResult>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
        }
        if (snap.hasError) {
          return _Hint(
            icon: Icons.cloud_off_rounded,
            text: "Couldn't search right now. Try again.",
          );
        }
        final results = snap.data ?? const [];
        if (results.isEmpty) {
          return _Hint(
            icon: Icons.search_off_rounded,
            text: 'No results for “$_query”.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final r = results[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SoftCard(
                onTap: () => context
                    .push('/seforim/read/${Uri.encodeComponent(r.ref)}'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.ref,
                      style: AppText.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo,
                      ),
                    ),
                    if (r.heRef.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        r.heRef,
                        textDirection: TextDirection.rtl,
                        style: AppText.inter(
                          fontSize: 12.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                    if (r.snippet.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        r.snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.inter(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: AppText.inter(fontSize: 14, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

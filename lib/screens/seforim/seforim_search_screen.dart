import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/seforim_palette.dart';

/// Full-text search across the library, debounced. Sefaria-style results —
/// serif ref over a grey snippet, hairline separated. Tapping a hit opens the
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
      backgroundColor: SeforimPalette.paper,
      appBar: AppBar(
        backgroundColor: SeforimPalette.paper,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/seforim'),
        ),
        title: Text(
          'Search',
          style: SeforimText.sans(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: SeforimPalette.secondary,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              style: SeforimText.sans(
                fontSize: 15,
                color: SeforimPalette.black,
              ),
              decoration: InputDecoration(
                hintText: 'Search texts, e.g. “tzedakah”…',
                hintStyle: SeforimText.sans(
                  fontSize: 15,
                  color: SeforimPalette.tertiary,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: SeforimPalette.secondary,
                ),
                filled: true,
                fillColor: SeforimPalette.faint,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: SeforimPalette.paperLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: SeforimPalette.paperLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: SeforimPalette.navy),
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
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: results.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: SeforimPalette.paperLine),
          itemBuilder: (context, i) {
            final r = results[i];
            return InkWell(
              onTap: () =>
                  context.push('/seforim/read/${Uri.encodeComponent(r.ref)}'),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            r.ref,
                            style: SeforimText.serif(
                              fontSize: 18,
                              color: SeforimPalette.black,
                            ),
                          ),
                        ),
                        if (r.heRef.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Text(
                            r.heRef,
                            textDirection: TextDirection.rtl,
                            style: SeforimText.hebrew(
                              fontSize: 16,
                              color: SeforimPalette.tertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (r.snippet.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        r.snippet,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: SeforimText.serif(
                          fontSize: 15,
                          height: 1.5,
                          color: SeforimPalette.secondary,
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
          Icon(icon, size: 44, color: SeforimPalette.tertiary),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: SeforimText.sans(
                fontSize: 14,
                color: SeforimPalette.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

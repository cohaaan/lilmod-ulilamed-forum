import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../data/seforim_prefs.dart';
import '../../models/seforim.dart';
import '../../theme/seforim_palette.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';

/// The Seforim tab root: the top level of the library tree, Sefaria-style —
/// a colour-coded, serif list of corpora with short sans descriptions on a
/// white page.
class SeforimBrowseScreen extends StatefulWidget {
  const SeforimBrowseScreen({super.key});

  @override
  State<SeforimBrowseScreen> createState() => _SeforimBrowseScreenState();
}

class _SeforimBrowseScreenState extends State<SeforimBrowseScreen> {
  late Future<List<SeforimNode>> _future = seforimRepository.fetchIndex();

  Future<void> _refresh() async {
    setState(() => _future = seforimRepository.fetchIndex());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SeforimPalette.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Browse the Library',
                      style: SeforimText.sans(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: SeforimPalette.secondary,
                      ),
                    ),
                  ),
                  const SeforimLangToggle(),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Search seforim',
                    onPressed: () => context.push('/seforim/search'),
                    icon: Icon(
                      Icons.search_rounded,
                      color: SeforimPalette.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Read the classic texts and copy sources straight into your '
                'reply.',
                style: SeforimText.sans(
                  fontSize: 14,
                  color: SeforimPalette.secondary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: seforimHebrewMode,
                builder: (context, hebrew, _) =>
                    AsyncView<List<SeforimNode>>(
                  future: _future,
                  onRetry: _refresh,
                  builder: (context, nodes) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final node in nodes)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: seforimNodeRow(
                            context,
                            node: node,
                            hebrew: hebrew,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Texts via Sefaria’s open API. Sources are attributed to their '
                'publishers; most are public domain or Creative Commons.',
                style: SeforimText.sans(
                  fontSize: 12,
                  color: SeforimPalette.tertiary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

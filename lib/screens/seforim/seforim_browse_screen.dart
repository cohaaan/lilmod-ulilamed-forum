import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/repositories.dart';
import '../../models/seforim.dart';
import '../../theme/app_colors.dart';
import '../../widgets/async.dart';
import '../../widgets/seforim_rows.dart';
import '../../theme/app_text.dart';

/// The Seforim tab root: the top level of the library tree, Sefaria-style —
/// a colour-coded, serif list of corpora with short descriptions.
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
      backgroundColor: AppColors.surface,
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
                      'Seforim Library',
                      style: GoogleFonts.ebGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Search seforim',
                    onPressed: () => context.push('/seforim/search'),
                    icon: Icon(Icons.search_rounded,
                        color: AppColors.ink),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Browse the library and copy sources straight into your reply.',
                style: AppText.inter(
                  fontSize: 13.5,
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              AsyncView<List<SeforimNode>>(
                future: _future,
                onRetry: _refresh,
                builder: (context, nodes) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final node in nodes) seforimNodeRow(context, node: node),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Texts via Sefaria’s open API. Sources are attributed to their '
                'publishers; most are public domain or Creative Commons.',
                style: AppText.inter(
                  fontSize: 11.5,
                  color: AppColors.muted,
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

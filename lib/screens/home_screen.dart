import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories.dart';
import '../models/category.dart';
import '../models/chavrusa_listing.dart';
import '../models/thread.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../widgets/async.dart';
import '../widgets/chavrusa/brutalist_button.dart';
import '../widgets/post_card.dart';
import '../widgets/soft_card.dart';
import '../widgets/workspace_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<(List<Category>, List<Thread>)> _future = _load();
  int _chavrusaRefresh = 0;

  Future<(List<Category>, List<Thread>)> _load() async {
    final results = await Future.wait([
      forumRepository.fetchCategories(),
      forumRepository.fetchRecentThreads(limit: 12),
    ]);
    return (results[0] as List<Category>, results[1] as List<Thread>);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
      _chavrusaRefresh++;
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final brutalist = AppColors.useBrutalistChrome;
    final contentPad = AppColors.useAubergineHeader
        ? const EdgeInsets.fromLTRB(20, 16, 20, 24)
        : brutalist
            ? const EdgeInsets.fromLTRB(0, 0, 0, 24)
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
              if (brutalist) ...[
                _ForumIndexHeader(trailing: _AccountButton()),
                const SizedBox(height: 14),
                Container(height: 6, color: AppColors.primary),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ChavrusaActionBar(refreshKey: _chavrusaRefresh),
                      const SizedBox(height: 12),
                      _ForumSearchBar(onTap: () => context.go('/search')),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ] else ...[
                WorkspaceHeader(
                  title: 'Lilmod Ulilamed',
                  subtitle: 'Serious, respectful Torah discourse',
                  trailing: _AccountButton(),
                ),
                SizedBox(height: AppColors.useAubergineHeader ? 16 : 18),
                _ChavrusaPromo(refreshKey: _chavrusaRefresh),
                const SizedBox(height: 18),
                _ForumSearchBar(onTap: () => context.go('/search')),
                const SizedBox(height: 24),
              ],
              Padding(
                padding: brutalist
                    ? const EdgeInsets.symmetric(horizontal: 20)
                    : EdgeInsets.zero,
                child: AsyncView<(List<Category>, List<Thread>)>(
                future: _future,
                onRetry: _refresh,
                builder: (context, data) {
                  final categories = data.$1;
                  final recent = data.$2;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionHeading(
                        title: 'Latest discussions',
                        actionLabel: 'All',
                        onAction: () => context.go('/forums'),
                      ),
                      const SizedBox(height: 12),
                      if (recent.isEmpty)
                        _EmptyRecent()
                      else
                        ...recent.map((t) => PostCard(thread: t)),
                      const SizedBox(height: 18),
                      SectionHeading(
                        title: 'Forums',
                        actionLabel: 'See all',
                        onAction: () => context.go('/forums'),
                      ),
                      const SizedBox(height: 12),
                      for (var i = 0; i < categories.length; i++)
                        _CategoryPanel(
                          category: categories[i],
                          accent: AppColors.accentAt(i),
                          initiallyExpanded: false,
                        ),
                    ],
                  );
                },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _forumIssueLabel() {
  final now = DateTime.now();
  final dd = now.day.toString().padLeft(2, '0');
  final mm = now.month.toString().padLeft(2, '0');
  return 'ISSUE $dd.$mm';
}

class _ForumIndexHeader extends StatelessWidget {
  const _ForumIndexHeader({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppText.display.copyWith(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      height: 1.0,
      letterSpacing: -0.6,
    );
    final indexStyle = AppText.sans(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
      color: AppColors.ink,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lilmod', style: titleStyle),
                Text('Ulilamed', style: titleStyle),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (trailing != null) trailing!,
              const SizedBox(height: 8),
              Text('FORUM INDEX', style: indexStyle),
              Text(_forumIssueLabel(), style: indexStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChavrusaActionBar extends StatefulWidget {
  const _ChavrusaActionBar({required this.refreshKey});

  final int refreshKey;

  @override
  State<_ChavrusaActionBar> createState() => _ChavrusaActionBarState();
}

class _ChavrusaActionBarState extends State<_ChavrusaActionBar> {
  static const _barHeight = 48.0;

  late Future<ChavrusaListing?> _mineFuture = _fetch();

  @override
  void didUpdateWidget(_ChavrusaActionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _mineFuture = _fetch());
    }
  }

  Future<ChavrusaListing?> _fetch() => chavrusaRepository.fetchMyListing();

  Future<void> _reload() async {
    setState(() => _mineFuture = _fetch());
    await _mineFuture;
  }

  Future<void> _openChavrusas() async {
    await context.push('/chavrusas');
    if (mounted) _reload();
  }

  Future<void> _openPost(ChavrusaListing? existing) async {
    await context.push<bool>('/chavrusas/edit', extra: existing);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChavrusaListing?>(
      future: _mineFuture,
      builder: (context, snapshot) {
        final mine = snapshot.data;
        final hasListing = mine != null;

        final barLabel = hasListing
            ? 'YOUR LISTING — ${mine.status.label.toUpperCase()} · ${mine.learningInterests.toUpperCase()}'
            : 'FIND A CHAVRUSA / POST AVAILABILITY';

        return SizedBox(
          height: _barHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BrutalistShell(
                  onTap: _openChavrusas,
                  minHeight: _barHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      barLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.35,
                        height: 1.2,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: hasListing ? null : _barHeight,
                child: BrutalistButton(
                  label: hasListing ? 'Edit' : '+',
                  style: hasListing
                      ? BrutalistButtonStyle.secondary
                      : BrutalistButtonStyle.primary,
                  minHeight: _barHeight,
                  padding: hasListing
                      ? const EdgeInsets.symmetric(horizontal: 14)
                      : EdgeInsets.zero,
                  expandWidth: !hasListing,
                  onPressed: () => _openPost(mine),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ForumSearchBar extends StatelessWidget {
  const _ForumSearchBar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brutalist = AppColors.useBrutalistChrome;

    if (brutalist) {
      return BrutalistShell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'SEARCH ALL DISCUSSIONS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.35,
                  color: AppColors.ink,
                ),
              ),
            ),
            Icon(Icons.search_rounded, color: AppColors.ink, size: 20),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.muted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search threads, sources…',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.sans(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A category that expands to reveal its subforums in place.
class _CategoryPanel extends StatefulWidget {
  const _CategoryPanel({
    required this.category,
    required this.accent,
    this.initiallyExpanded = false,
  });

  final Category category;
  final Color accent;
  final bool initiallyExpanded;

  @override
  State<_CategoryPanel> createState() => _CategoryPanelState();
}

class _CategoryPanelState extends State<_CategoryPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final cat = widget.category;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 38,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${cat.subforums.length} subforums · ${cat.threadCount} threads',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.sans(
                                fontSize: 12.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(Icons.keyboard_arrow_down_rounded,
                            color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  Divider(height: 1, color: AppColors.line),
                  for (final sub in cat.subforums)
                    _SubforumRow(
                      categoryId: cat.id,
                      subforumId: sub.id,
                      name: sub.name,
                      threadCount: sub.threadCount,
                      accent: widget.accent,
                    ),
                ],
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubforumRow extends StatelessWidget {
  const _SubforumRow({
    required this.categoryId,
    required this.subforumId,
    required this.name,
    required this.threadCount,
    required this.accent,
  });

  final String categoryId;
  final String subforumId;
  final String name;
  final int threadCount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go('/forums/c/$categoryId/s/$subforumId'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 13, 16, 13),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.sans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$threadCount',
                style: AppText.sans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChavrusaPromo extends StatefulWidget {
  const _ChavrusaPromo({required this.refreshKey});

  final int refreshKey;

  @override
  State<_ChavrusaPromo> createState() => _ChavrusaPromoState();
}

class _ChavrusaPromoState extends State<_ChavrusaPromo> {
  late Future<ChavrusaListing?> _mineFuture = _fetch();

  @override
  void didUpdateWidget(_ChavrusaPromo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      setState(() => _mineFuture = _fetch());
    }
  }

  Future<ChavrusaListing?> _fetch() => chavrusaRepository.fetchMyListing();

  Future<void> _reload() async {
    setState(() => _mineFuture = _fetch());
    await _mineFuture;
  }

  Future<void> _openChavrusas() async {
    await context.push('/chavrusas');
    if (mounted) _reload();
  }

  Future<void> _openPost(ChavrusaListing? existing) async {
    await context.push<bool>('/chavrusas/edit', extra: existing);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChavrusaListing?>(
      future: _mineFuture,
      builder: (context, snapshot) {
        final mine = snapshot.data;
        final hasListing = mine != null;

        return SoftCard(
          onTap: hasListing ? () => _openPost(mine) : _openChavrusas,
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasListing ? Icons.edit_calendar_outlined : Icons.groups_outlined,
                  color: AppColors.indigo,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasListing ? 'Your chavrusa listing' : 'Find a chavrusa',
                      style: AppText.sans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasListing
                          ? '${mine.status.label} · ${mine.learningInterests} · ${mine.topic}'
                          : 'By phone, during work hours, or whenever',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.sans(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Icon(Icons.forum_outlined, size: 40, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(
            'No discussions yet — be the first to start one.',
            textAlign: TextAlign.center,
            style: AppText.sans(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.go('/forums'),
            child: const Text('Browse forums'),
          ),
        ],
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (AppColors.useBrutalistChrome) {
      return BrutalistButton(
        label: 'Account',
        style: BrutalistButtonStyle.login,
        minHeight: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        onPressed: () => context.push('/account'),
      );
    }

    final onBanner = AppColors.useAubergineHeader;
    final fg = onBanner ? Colors.white : AppColors.ink;
    final border = onBanner
        ? Colors.white.withValues(alpha: 0.35)
        : AppColors.line;

    return InkWell(
      onTap: () => context.push('/account'),
      customBorder: const CircleBorder(),
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        child: Icon(Icons.person_outline_rounded, color: fg, size: 22),
      ),
    );
  }
}

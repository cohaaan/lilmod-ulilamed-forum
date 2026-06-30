import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories.dart';
import '../../models/chavrusa_listing.dart';
import '../../theme/chavrusa_directory_theme.dart';
import '../../util/format.dart';
import '../../widgets/async.dart';
import '../../widgets/chavrusa/brutalist_button.dart';
import '../../widgets/chavrusa/chavrusa_directory_card.dart';
import '../../widgets/chavrusa/chavrusa_post_form.dart';

enum _StatusFilter { all, available, newThisWeek }

enum _SortMode { newest, name, time }

class ChavrusasScreen extends StatefulWidget {
  const ChavrusasScreen({super.key});

  @override
  State<ChavrusasScreen> createState() => _ChavrusasScreenState();
}

class _ChavrusasScreenState extends State<ChavrusasScreen> {
  late Future<(List<ChavrusaListing>, ChavrusaListing?)> _future = _load();
  final _search = TextEditingController();

  _StatusFilter _statusFilter = _StatusFilter.all;
  _SortMode _sort = _SortMode.newest;
  ChavrusaContactMethod? _contactFilter;
  final _dayFilters = <String>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<(List<ChavrusaListing>, ChavrusaListing?)> _load() async {
    unawaited(chavrusaRepository.recordPageVisit());
    final results = await Future.wait([
      chavrusaRepository.fetchAvailableListings(),
      chavrusaRepository.fetchMyListing(),
    ]);
    return (
      results[0] as List<ChavrusaListing>,
      results[1] as ChavrusaListing?,
    );
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  List<ChavrusaListing> _filterAndSort(List<ChavrusaListing> listings) {
    final query = _search.text.trim().toLowerCase();
    final now = DateTime.now();

    var filtered = listings.where((listing) {
      if (_statusFilter == _StatusFilter.newThisWeek &&
          now.difference(listing.updatedAt).inDays > 7) {
        return false;
      }
      if (_contactFilter != null && listing.preferredContact != _contactFilter) {
        return false;
      }
      if (!chavrusaListingMatchesDayFilters(listing, _dayFilters)) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        listing.displayName,
        listing.learningInterests,
        listing.topic,
        listing.learningDetails,
        formatChavrusaAvailability(listing.availability),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case _SortMode.name:
          return a.displayName.compareTo(b.displayName);
        case _SortMode.time:
          return chavrusaEarliestSlotHour(a.availability)
              .compareTo(chavrusaEarliestSlotHour(b.availability));
        case _SortMode.newest:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });
    return filtered;
  }

  int _gridColumns(double width) {
    if (width >= 1180) return 4;
    if (width >= 900) return 3;
    if (width >= 620) return 2;
    return 1;
  }

  Future<void> _openPostModal({ChavrusaListing? existing}) async {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 720) {
      final changed = await context.push<bool>(
        '/chavrusas/edit',
        extra: existing,
      );
      if (changed == true) _refresh();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierColor: const Color(0x850F141C),
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide.none),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 860),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 20, 16, 20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: ChavrusaDirectoryTheme.blue, width: 2)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        existing == null ? 'Post your chavrusa availability' : 'Edit your listing',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: ChavrusaDirectoryTheme.ink,
                        ),
                      ),
                    ),
                    BrutalistButton(
                      label: '×',
                      style: BrutalistButtonStyle.secondary,
                      minHeight: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ChavrusaPostForm(
                    existing: existing,
                    onCancel: () => Navigator.pop(dialogContext),
                    onSaved: () {
                      Navigator.pop(dialogContext);
                      _refresh();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContact(ChavrusaListing listing) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(listing.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age ${listing.age} · updated ${relativeTime(listing.updatedAt)}'),
            const SizedBox(height: 12),
            Text('Subject: ${listing.learningInterests}'),
            Text('Sefer: ${listing.topic}'),
            if (listing.learningDetails.isNotEmpty) Text('Notes: ${listing.learningDetails}'),
            Text('When: ${formatChavrusaAvailability(listing.availability)}'),
            Text('Length: ${listing.sessionLength}'),
            const SizedBox(height: 12),
            Text('Phone: ${listing.phone}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final method in listing.allowedContacts)
                  Chip(
                    label: Text(
                      method == listing.preferredContact
                          ? '${method.label} (preferred)'
                          : method.label,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: listing.phone));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone number copied')),
                );
              }
            },
            child: const Text('Copy phone'),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AsyncView<(List<ChavrusaListing>, ChavrusaListing?)>(
        future: _future,
        onRetry: _refresh,
        loadingHeight: MediaQuery.sizeOf(context).height * 0.55,
        builder: (context, data) {
          final listings = _filterAndSort(data.$1);
          final mine = data.$2;
          final width = MediaQuery.sizeOf(context).width;
          final showSidebar = width >= 900;

          return Column(
            children: [
              _DirectoryHeader(
                onAccount: () => context.push('/account'),
                onBack: context.canPop() ? () => context.pop() : () => context.go('/'),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSidebar)
                      _FilterSidebar(
                        statusFilter: _statusFilter,
                        contactFilter: _contactFilter,
                        dayFilters: _dayFilters,
                        onStatusChanged: (v) => setState(() => _statusFilter = v),
                        onContactChanged: (v) => setState(() => _contactFilter = v),
                        onDayToggled: (abbrev, checked) => setState(() {
                          if (checked) {
                            _dayFilters.add(abbrev);
                          } else {
                            _dayFilters.remove(abbrev);
                          }
                        }),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          showSidebar ? 30 : 20,
                          28,
                          showSidebar ? 30 : 20,
                          48,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!showSidebar) ...[
                              _FilterSidebar(
                                compact: true,
                                statusFilter: _statusFilter,
                                contactFilter: _contactFilter,
                                dayFilters: _dayFilters,
                                onStatusChanged: (v) => setState(() => _statusFilter = v),
                                onContactChanged: (v) => setState(() => _contactFilter = v),
                                onDayToggled: (abbrev, checked) => setState(() {
                                  if (checked) {
                                    _dayFilters.add(abbrev);
                                  } else {
                                    _dayFilters.remove(abbrev);
                                  }
                                }),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (mine != null) ...[
                              _MyListingStrip(
                                listing: mine,
                                onEdit: () => _openPostModal(existing: mine),
                              ),
                              const SizedBox(height: 20),
                            ],
                            _Toolbar(
                              search: _search,
                              count: listings.length,
                              sort: _sort,
                              onSearchChanged: () => setState(() {}),
                              onSortChanged: (v) => setState(() => _sort = v),
                              onPost: () => _openPostModal(existing: mine),
                            ),
                            const SizedBox(height: 28),
                            if (listings.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 18),
                                decoration: BoxDecoration(
                                  border: Border.all(color: ChavrusaDirectoryTheme.line),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No chavrusa listings match these filters.',
                                    style: TextStyle(color: ChavrusaDirectoryTheme.muted),
                                  ),
                                ),
                              )
                            else
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final cols = _gridColumns(constraints.maxWidth);
                                  return GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: cols,
                                      crossAxisSpacing: 18,
                                      mainAxisSpacing: 18,
                                      mainAxisExtent: 296,
                                    ),
                                    itemCount: listings.length,
                                    itemBuilder: (context, index) => ChavrusaDirectoryCard(
                                      listing: listings[index],
                                      onContact: () => _showContact(listings[index]),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DirectoryHeader extends StatelessWidget {
  const _DirectoryHeader({required this.onAccount, required this.onBack});

  final VoidCallback onAccount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 900;
    return Container(
      constraints: const BoxConstraints(minHeight: ChavrusaDirectoryTheme.headerHeight),
      padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 34, vertical: 24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ChavrusaDirectoryTheme.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: ChavrusaDirectoryTheme.ink,
          ),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              runSpacing: 7,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: ChavrusaDirectoryTheme.ink,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            'ללמוד וללמד',
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ),
                      ),
                      const TextSpan(text: ' · Lilmod U\'Lilamed'),
                    ],
                  ),
                ),
                const Text(
                  'Find a chavrusa to learn with — by phone, during work hours, or whenever.',
                  style: TextStyle(fontSize: 14, color: ChavrusaDirectoryTheme.muted),
                ),
              ],
            ),
          ),
          BrutalistButton(
            label: 'Account',
            style: BrutalistButtonStyle.login,
            minHeight: 40,
            padding: const EdgeInsets.symmetric(horizontal: 17),
            onPressed: onAccount,
          ),
        ],
      ),
    );
  }
}

class _FilterSidebar extends StatelessWidget {
  const _FilterSidebar({
    required this.statusFilter,
    required this.contactFilter,
    required this.dayFilters,
    required this.onStatusChanged,
    required this.onContactChanged,
    required this.onDayToggled,
    this.compact = false,
  });

  final _StatusFilter statusFilter;
  final ChavrusaContactMethod? contactFilter;
  final Set<String> dayFilters;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<ChavrusaContactMethod?> onContactChanged;
  final void Function(String abbrev, bool checked) onDayToggled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('FILTERS', style: ChavrusaDirectoryTheme.eyebrow),
        const SizedBox(height: 16),
        _FilterSection(
          title: 'Status',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterLabel('Show'),
              DropdownButtonFormField<_StatusFilter>(
                value: statusFilter,
                decoration: ChavrusaDirectoryTheme.fieldDecoration(''),
                items: const [
                  DropdownMenuItem(value: _StatusFilter.all, child: Text('All')),
                  DropdownMenuItem(value: _StatusFilter.available, child: Text('Available now')),
                  DropdownMenuItem(value: _StatusFilter.newThisWeek, child: Text('New this week')),
                ],
                onChanged: (v) => onStatusChanged(v ?? _StatusFilter.all),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FilterSection(
          title: 'Day',
          child: Column(
            children: [
              for (final entry in chavrusaDayFilterOptions.entries)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  value: dayFilters.contains(entry.key),
                  onChanged: (v) => onDayToggled(entry.key, v ?? false),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FilterSection(
          title: 'Contact',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterLabel('Preferred method'),
              DropdownButtonFormField<ChavrusaContactMethod?>(
                value: contactFilter,
                decoration: ChavrusaDirectoryTheme.fieldDecoration(''),
                hint: const Text('All methods'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All methods')),
                  DropdownMenuItem(value: ChavrusaContactMethod.whatsapp, child: Text('WhatsApp')),
                  DropdownMenuItem(value: ChavrusaContactMethod.text, child: Text('Text')),
                  DropdownMenuItem(value: ChavrusaContactMethod.call, child: Text('Call')),
                ],
                onChanged: onContactChanged,
              ),
            ],
          ),
        ),
      ],
    );

    if (compact) return content;
    return SizedBox(
      width: ChavrusaDirectoryTheme.sidebarWidth,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 31, 28, 31),
        child: content,
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ChavrusaDirectoryTheme.soft),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              const Icon(Icons.expand_more, size: 18, color: ChavrusaDirectoryTheme.muted),
            ],
          ),
          child,
        ],
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  const _FilterLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: ChavrusaDirectoryTheme.fieldLabel.copyWith(
          color: ChavrusaDirectoryTheme.muted,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.search,
    required this.count,
    required this.sort,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onPost,
  });

  final TextEditingController search;
  final int count;
  final _SortMode sort;
  final VoidCallback onSearchChanged;
  final ValueChanged<_SortMode> onSortChanged;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        BrutalistButton(
          label: '+ Post a Chavrusa',
          minHeight: 48,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          icon: const Icon(Icons.add, color: Colors.white, size: 18),
          onPressed: onPost,
        ),
        SizedBox(
          width: compact ? double.infinity : 320,
          child: TextField(
            controller: search,
            onChanged: (_) => onSearchChanged(),
            decoration: ChavrusaDirectoryTheme.fieldDecoration(
              '',
              hint: 'Search name, sefer, topic, or time…',
            ).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              suffixIcon: const Icon(Icons.search, color: ChavrusaDirectoryTheme.muted, size: 20),
            ),
          ),
        ),
        if (!compact)
          Text(
            '$count available listings',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ChavrusaDirectoryTheme.muted),
          ),
        SizedBox(
          width: compact ? double.infinity : 180,
          child: DropdownButtonFormField<_SortMode>(
            value: sort,
            decoration: ChavrusaDirectoryTheme.fieldDecoration('').copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: const [
              DropdownMenuItem(value: _SortMode.newest, child: Text('Newest first')),
              DropdownMenuItem(value: _SortMode.name, child: Text('Name A–Z')),
              DropdownMenuItem(value: _SortMode.time, child: Text('Earliest time')),
            ],
            onChanged: (v) => onSortChanged(v ?? _SortMode.newest),
          ),
        ),
      ],
    );
  }
}

class _MyListingStrip extends StatelessWidget {
  const _MyListingStrip({required this.listing, required this.onEdit});

  final ChavrusaListing listing;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ChavrusaDirectoryTheme.blue),
        color: ChavrusaDirectoryTheme.blue.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your listing — ${listing.status.label}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${listing.learningInterests} · ${listing.topic}',
                  style: const TextStyle(fontSize: 13, color: ChavrusaDirectoryTheme.muted),
                ),
              ],
            ),
          ),
          BrutalistButton(
            label: 'Edit',
            style: BrutalistButtonStyle.secondary,
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

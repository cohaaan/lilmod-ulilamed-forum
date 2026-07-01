import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/chavrusa_access.dart';
import '../../data/repositories.dart';
import '../../models/chavrusa_listing.dart';
import '../../theme/chavrusa_directory_theme.dart';
import '../../util/format.dart';
import '../../widgets/async.dart';
import '../../widgets/chavrusa/brutalist_button.dart';
import '../../widgets/chavrusa/chavrusa_directory_card.dart';
import '../../widgets/chavrusa/chavrusa_post_form.dart';

enum _StatusFilter { all, available, newThisWeek }

class ChavrusasScreen extends StatefulWidget {
  const ChavrusasScreen({super.key});

  @override
  State<ChavrusasScreen> createState() => _ChavrusasScreenState();
}

class _ChavrusasScreenState extends State<ChavrusasScreen> {
  late Future<({List<ChavrusaListing> listings, ChavrusaListing? mine, bool needsInvite})> _future =
      _load();
  final _search = TextEditingController();

  _StatusFilter _statusFilter = _StatusFilter.all;
  ChavrusaContactMethod? _contactFilter;
  String? _filterDay;
  String? _filterTime;
  String? _filterSubject;

  bool get _filtersActive =>
      _filterDay != null ||
      _filterTime != null ||
      _filterSubject != null ||
      _contactFilter != null ||
      _statusFilter != _StatusFilter.all ||
      _search.text.trim().isNotEmpty;

  void _clearFilters() {
    setState(() {
      _filterDay = null;
      _filterTime = null;
      _filterSubject = null;
      _contactFilter = null;
      _statusFilter = _StatusFilter.all;
      _search.clear();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<({List<ChavrusaListing> listings, ChavrusaListing? mine, bool needsInvite})> _load() async {
    unawaited(chavrusaRepository.recordPageVisit());
    final requiresInvite = await chavrusaRepository.requiresInvite();
    final isMember = !requiresInvite || await chavrusaRepository.isMember();
    if (!isMember) {
      return (listings: const <ChavrusaListing>[], mine: null, needsInvite: true);
    }
    final results = await Future.wait([
      chavrusaRepository.fetchAvailableListings(),
      chavrusaRepository.fetchMyListing(),
    ]);
    return (
      listings: results[0] as List<ChavrusaListing>,
      mine: results[1] as ChavrusaListing?,
      needsInvite: false,
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
      if (_filterSubject != null &&
          listing.learningInterests != _filterSubject) {
        return false;
      }
      if (!chavrusaListingMatchesAvailabilityQuery(
        listing,
        day: _filterDay,
        time: _filterTime,
      )) {
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

    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
      body: AsyncView<({List<ChavrusaListing> listings, ChavrusaListing? mine, bool needsInvite})>(
        future: _future,
        onRetry: _refresh,
        loadingHeight: MediaQuery.sizeOf(context).height * 0.55,
        builder: (context, data) {
          if (data.needsInvite) {
            return Column(
              children: [
                _DirectoryHeader(
                  onAccount: () => context.push('/account'),
                  onBack: context.canPop() ? () => context.pop() : () => context.go('/'),
                ),
                Expanded(
                  child: _ChavrusaInviteGate(onJoined: _refresh),
                ),
              ],
            );
          }

          final allListings = data.listings;
          final listings = _filterAndSort(allListings);
          final mine = data.mine;
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
                        filterDay: _filterDay,
                        filterTime: _filterTime,
                        filterSubject: _filterSubject,
                        filtersActive: _filtersActive,
                        onStatusChanged: (v) => setState(() => _statusFilter = v),
                        onContactChanged: (v) => setState(() => _contactFilter = v),
                        onFilterDayChanged: (v) => setState(() => _filterDay = v),
                        onFilterTimeChanged: (v) => setState(() => _filterTime = v),
                        onFilterSubjectChanged: (v) =>
                            setState(() => _filterSubject = v),
                        onClearFilters: _clearFilters,
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
                                filterDay: _filterDay,
                                filterTime: _filterTime,
                                filterSubject: _filterSubject,
                                filtersActive: _filtersActive,
                                onStatusChanged: (v) => setState(() => _statusFilter = v),
                                onContactChanged: (v) => setState(() => _contactFilter = v),
                                onFilterDayChanged: (v) => setState(() => _filterDay = v),
                                onFilterTimeChanged: (v) => setState(() => _filterTime = v),
                                onFilterSubjectChanged: (v) =>
                                    setState(() => _filterSubject = v),
                                onClearFilters: _clearFilters,
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
                              filteredCount: listings.length,
                              totalCount: allListings.length,
                              filtersActive: _filtersActive,
                              onSearchChanged: () => setState(() {}),
                              onClearFilters: _clearFilters,
                              onPost: () => _openPostModal(existing: mine),
                            ),
                            const SizedBox(height: 28),
                            if (listings.isEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 18),
                                decoration: BoxDecoration(
                                  border: Border.all(color: ChavrusaDirectoryTheme.line),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        allListings.isEmpty
                                            ? 'No chavrusa listings yet.'
                                            : 'No listings match these filters.',
                                        style: const TextStyle(
                                          color: ChavrusaDirectoryTheme.muted,
                                        ),
                                      ),
                                      if (allListings.isNotEmpty && _filtersActive) ...[
                                        const SizedBox(height: 12),
                                        TextButton(
                                          onPressed: _clearFilters,
                                          child: Text(
                                            'Clear filters (${allListings.length} '
                                            '${allListings.length == 1 ? 'listing' : 'listings'} total)',
                                          ),
                                        ),
                                      ],
                                    ],
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
    required this.filterDay,
    required this.filterTime,
    required this.filterSubject,
    required this.filtersActive,
    required this.onStatusChanged,
    required this.onContactChanged,
    required this.onFilterDayChanged,
    required this.onFilterTimeChanged,
    required this.onFilterSubjectChanged,
    required this.onClearFilters,
    this.compact = false,
  });

  final _StatusFilter statusFilter;
  final ChavrusaContactMethod? contactFilter;
  final String? filterDay;
  final String? filterTime;
  final String? filterSubject;
  final bool filtersActive;
  final ValueChanged<_StatusFilter> onStatusChanged;
  final ValueChanged<ChavrusaContactMethod?> onContactChanged;
  final ValueChanged<String?> onFilterDayChanged;
  final ValueChanged<String?> onFilterTimeChanged;
  final ValueChanged<String?> onFilterSubjectChanged;
  final VoidCallback onClearFilters;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('FILTERS', style: ChavrusaDirectoryTheme.eyebrow),
        const SizedBox(height: 10),
        TextButton(
          onPressed: filtersActive ? onClearFilters : null,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Clear all filters',
            style: TextStyle(
              color: filtersActive
                  ? ChavrusaDirectoryTheme.blue
                  : ChavrusaDirectoryTheme.muted.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
          title: 'When I\'m free',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterLabel('Day'),
              DropdownButtonFormField<String?>(
                value: filterDay,
                decoration: ChavrusaDirectoryTheme.fieldDecoration(''),
                hint: const Text('Any day'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any day')),
                  for (final day in chavrusaDays)
                    DropdownMenuItem(value: day, child: Text(day)),
                ],
                onChanged: onFilterDayChanged,
              ),
              _FilterLabel('Time'),
              DropdownButtonFormField<String?>(
                value: filterTime,
                decoration: ChavrusaDirectoryTheme.fieldDecoration(''),
                hint: const Text('Any time'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any time')),
                  for (final time in chavrusaTimeSlots)
                    DropdownMenuItem(value: time, child: Text(time)),
                ],
                onChanged: onFilterTimeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FilterSection(
          title: 'Topic',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterLabel('Subject'),
              DropdownButtonFormField<String?>(
                value: filterSubject,
                decoration: ChavrusaDirectoryTheme.fieldDecoration(''),
                hint: const Text('Any subject'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any subject')),
                  for (final subject in chavrusaSubjects)
                    DropdownMenuItem(value: subject, child: Text(subject)),
                ],
                onChanged: onFilterSubjectChanged,
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
    required this.filteredCount,
    required this.totalCount,
    required this.filtersActive,
    required this.onSearchChanged,
    required this.onClearFilters,
    required this.onPost,
  });

  final TextEditingController search;
  final int filteredCount;
  final int totalCount;
  final bool filtersActive;
  final VoidCallback onSearchChanged;
  final VoidCallback onClearFilters;
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
          label: 'Post a Chavrusa',
          minHeight: 48,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          icon: const Icon(Icons.add, color: Colors.white, size: 20),
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
            filtersActive && filteredCount != totalCount
                ? '$filteredCount of $totalCount listings'
                : '$totalCount ${totalCount == 1 ? 'listing' : 'listings'}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ChavrusaDirectoryTheme.muted),
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

class _ChavrusaInviteGate extends StatefulWidget {
  const _ChavrusaInviteGate({required this.onJoined});

  final VoidCallback onJoined;

  @override
  State<_ChavrusaInviteGate> createState() => _ChavrusaInviteGateState();
}

class _ChavrusaInviteGateState extends State<_ChavrusaInviteGate> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _redeem() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter your invite code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await chavrusaRepository.validateInvite(code);
      if (message != null) {
        setState(() => _error = message);
        return;
      }
      await chavrusaRepository.redeemInvite(code);
      ChavrusaAccess.markMember();
      widget.onJoined();
    } catch (_) {
      setState(() => _error = 'Could not redeem that code. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Chavrusas is invite-only',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: ChavrusaDirectoryTheme.ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your invite code to browse listings and post your availability.',
                style: TextStyle(fontSize: 14, color: ChavrusaDirectoryTheme.muted, height: 1.45),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 6),
                decoration: ChavrusaDirectoryTheme.fieldDecoration(
                  'Invite code',
                  hint: '••••••',
                ),
                onSubmitted: (_) {
                  if (!_busy) _redeem();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB42318)),
                ),
              ],
              const SizedBox(height: 16),
              BrutalistButton(
                label: _busy ? 'Checking…' : 'Continue',
                onPressed: _busy ? null : _redeem,
                expandWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

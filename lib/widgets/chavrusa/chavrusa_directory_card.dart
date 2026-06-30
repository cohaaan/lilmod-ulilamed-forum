import 'package:flutter/material.dart';

import '../../models/chavrusa_listing.dart';
import '../../theme/chavrusa_directory_theme.dart';
import '../../util/format.dart';
import 'brutalist_button.dart';

class ChavrusaDirectoryCard extends StatefulWidget {
  const ChavrusaDirectoryCard({
    super.key,
    required this.listing,
    required this.onContact,
  });

  final ChavrusaListing listing;
  final VoidCallback onContact;

  @override
  State<ChavrusaDirectoryCard> createState() => _ChavrusaDirectoryCardState();
}

class _ChavrusaDirectoryCardState extends State<ChavrusaDirectoryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: _hover ? Matrix4.translationValues(0, -2, 0) : Matrix4.identity(),
        decoration: ChavrusaDirectoryTheme.cardDecoration.copyWith(
          color: _hover ? const Color(0xFFF8FBFF) : Colors.white,
          boxShadow: _hover
              ? [BoxShadow(color: ChavrusaDirectoryTheme.blue.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))]
              : ChavrusaDirectoryTheme.cardDecoration.boxShadow,
        ),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const _StatusBadge(),
                Text(
                  relativeTime(listing.updatedAt),
                  style: const TextStyle(fontSize: 10, color: ChavrusaDirectoryTheme.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 18,
                  height: 1.1,
                  letterSpacing: -0.4,
                  color: ChavrusaDirectoryTheme.ink,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(text: listing.displayName),
                  TextSpan(
                    text: ' · ${listing.age}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: ChavrusaDirectoryTheme.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              listing.learningInterests.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: ChavrusaDirectoryTheme.blue,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.topic,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: ChavrusaDirectoryTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MetaRow(label: 'When', value: formatChavrusaAvailability(listing.availability)),
                  const SizedBox(height: 5),
                  _MetaRow(label: 'Length', value: listing.sessionLength),
                  const SizedBox(height: 5),
                  Expanded(
                    child: _MetaRow(
                      label: 'Notes',
                      value: chavrusaCardNotes(listing),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ChavrusaDirectoryTheme.soft)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${listing.preferredContact.label} preferred',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: ChavrusaDirectoryTheme.muted,
                      ),
                    ),
                  ),
                  BrutalistButton(
                    label: 'View & contact',
                    style: BrutalistButtonStyle.contact,
                    minHeight: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    onPressed: widget.onContact,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: ChavrusaDirectoryTheme.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 7),
        const Text(
          'AVAILABLE',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: ChavrusaDirectoryTheme.green,
          ),
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.maxLines = 2,
  });

  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label.toUpperCase(), style: ChavrusaDirectoryTheme.metaLabel),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, height: 1.3, color: ChavrusaDirectoryTheme.ink),
          ),
        ),
      ],
    );
  }
}

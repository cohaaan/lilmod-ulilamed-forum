import 'package:flutter/material.dart';

import '../theme/design_direction.dart';
import '../theme/design_directions.dart';

/// Miniature phone mockup: header + thread list + bottom nav for one direction.
class DesignDirectionMockup extends StatelessWidget {
  const DesignDirectionMockup({
    super.key,
    required this.direction,
    this.width = 168,
  });

  final DesignDirection direction;
  final double width;

  static const _threads = [
    (tag: 'halacha', title: 'Shabbos eruv boundaries in apartment buildings', unread: true),
    (tag: 'machshava', title: 'Free will and hashgacha pratis — a framework', unread: false),
  ];

  bool get _isSlack => direction.id == DesignDirections.slackWorkspace.id;

  @override
  Widget build(BuildContext context) {
    if (_isSlack) return _SlackMockup(direction: direction, width: width);
    if (direction.useBrutalistChrome) {
      return _BrutalistMockup(direction: direction, width: width);
    }
    return _GenericMockup(direction: direction, width: width);
  }
}

class _SlackMockup extends StatelessWidget {
  const _SlackMockup({required this.direction, required this.width});

  final DesignDirection direction;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 1.95;
    const threads = DesignDirectionMockup._threads;

    return Container(
      width: width,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: direction.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: direction.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 18,
            color: direction.primary,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Container(
            color: direction.primary,
            padding: const EdgeInsets.fromLTRB(10, 2, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Lilmod Ulilamed',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: direction.titleStyle(
                            size: 11,
                            weight: FontWeight.w700,
                          ).copyWith(color: Colors.white),
                        ),
                      ),
                      Icon(
                        Icons.expand_more_rounded,
                        size: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.search_rounded,
                  size: 12,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
            child: Text(
              'Home',
              style: direction.titleStyle(size: 10, weight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < threads.length; i++) ...[
                  _SlackChannelRow(
                    direction: direction,
                    hash: threads[i].tag,
                    title: threads[i].title,
                    unread: threads[i].unread,
                  ),
                  if (i < threads.length - 1)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: direction.border,
                      indent: 10,
                      endIndent: 10,
                    ),
                ],
              ],
            ),
          ),
          _MiniNavBar(direction: direction, slackStyle: true),
        ],
      ),
    );
  }
}

class _SlackChannelRow extends StatelessWidget {
  const _SlackChannelRow({
    required this.direction,
    required this.hash,
    required this.title,
    required this.unread,
  });

  final DesignDirection direction;
  final String hash;
  final String title;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#',
            style: direction.bodyStyle(size: 9).copyWith(
              color: direction.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hash,
                  style: direction.titleStyle(
                    size: 9,
                    weight: unread ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: direction.bodyStyle(size: 7.5).copyWith(
                    color: direction.muted,
                  ),
                ),
              ],
            ),
          ),
          if (unread)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 3),
              decoration: BoxDecoration(
                color: direction.accent,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _BrutalistMockup extends StatelessWidget {
  const _BrutalistMockup({required this.direction, required this.width});

  final DesignDirection direction;
  final double width;

  static const _threads = [
    ('Halacha', 'Shabbos eruv boundaries in apartment buildings'),
    ('Machshava', 'Free will and hashgacha pratis — a framework'),
  ];

  @override
  Widget build(BuildContext context) {
    final h = width * 1.95;
    final pad = 10 * direction.density;

    return Container(
      width: width,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: direction.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: direction.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 18,
            color: direction.surface,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: direction.muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 6 * direction.density, pad, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lilmod Ulilamed',
                  style: direction.titleStyle(size: 13, weight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'LATEST DISCUSSIONS',
                  style: direction.captionStyle(size: 7).copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: pad),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final (tag, title) in _threads) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: 6 * direction.density),
                    padding: EdgeInsets.all(8 * direction.density),
                    decoration: BoxDecoration(
                      color: direction.surface,
                      border: Border.all(color: direction.primary),
                      boxShadow: [
                        BoxShadow(
                          color: direction.primary.withValues(alpha: 0.08),
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tag.toUpperCase(),
                          style: direction.captionStyle(size: 7).copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                        ),
                        SizedBox(height: 4 * direction.density),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: direction.titleStyle(
                            size: 9.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: direction.border)),
            ),
            child: Container(
              height: 14,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: direction.primary,
                border: Border.all(color: direction.border),
                boxShadow: [
                  BoxShadow(
                    color: direction.ink.withValues(alpha: 0.35),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'Post',
                style: direction.captionStyle(size: 7).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
          _MiniNavBar(direction: direction, slackStyle: false),
        ],
      ),
    );
  }
}

class _GenericMockup extends StatelessWidget {
  const _GenericMockup({required this.direction, required this.width});

  final DesignDirection direction;
  final double width;

  static const _threads = [
    ('Halacha', 'Shabbos eruv boundaries in apartment buildings'),
    ('Machshava', 'Free will and hashgacha pratis — a framework'),
  ];

  @override
  Widget build(BuildContext context) {
    final h = width * 1.95;
    final pad = 10 * direction.density;
    final tagRadius = direction.pillTags ? 999.0 : 4.0;

    return Container(
      width: width,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: direction.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: direction.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 18,
            color: direction.isDark ? direction.surfaceMuted : direction.surface,
            alignment: Alignment.center,
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: direction.muted.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(pad, 6 * direction.density, pad, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Forums',
                  style: direction.titleStyle(size: 14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Latest discussions',
                  style: direction.captionStyle(size: 8.5),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: pad),
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final (tag, title) in _threads) ...[
                  Container(
                    margin: EdgeInsets.only(bottom: 6 * direction.density),
                    padding: EdgeInsets.all(8 * direction.density),
                    decoration: direction.cardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: direction.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(tagRadius),
                          ),
                          child: Text(
                            tag,
                            style: direction.captionStyle(size: 7.5).copyWith(
                              color: direction.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(height: 4 * direction.density),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: direction.titleStyle(
                            size: 9.5,
                            weight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 5 * direction.density),
                        Row(
                          children: [
                            _MiniAvatar(direction: direction),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'R. Cohen · 12 replies',
                                style: direction.captionStyle(size: 7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _MiniNavBar(direction: direction, slackStyle: false),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.direction});

  final DesignDirection direction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: direction.primary.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'R',
        style: direction.captionStyle(size: 6).copyWith(
          color: direction.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniNavBar extends StatelessWidget {
  const _MiniNavBar({
    required this.direction,
    required this.slackStyle,
  });

  final DesignDirection direction;
  final bool slackStyle;

  static const _labels = ['Home', 'Forums', 'Seforim', 'Search', 'Articles'];

  @override
  Widget build(BuildContext context) {
    final bg = switch (direction.navStyle) {
      DesignNavStyle.darkBar => direction.surfaceMuted,
      DesignNavStyle.filled => direction.surface,
      _ => direction.surface,
    };

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: direction.border,
            width: direction.navStyle == DesignNavStyle.underline ? 2 : 1,
          ),
        ),
        boxShadow: direction.navStyle == DesignNavStyle.elevated
            ? [
                BoxShadow(
                  color: direction.ink.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < _labels.length; i++)
            _MiniNavItem(
              label: _labels[i],
              selected: slackStyle ? i == 0 : i == 1,
              direction: direction,
            ),
        ],
      ),
    );
  }
}

class _MiniNavItem extends StatelessWidget {
  const _MiniNavItem({
    required this.label,
    required this.selected,
    required this.direction,
  });

  final String label;
  final bool selected;
  final DesignDirection direction;

  @override
  Widget build(BuildContext context) {
    final color = selected ? direction.primary : direction.muted;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          selected ? Icons.home_rounded : Icons.forum_outlined,
          size: 11,
          color: color,
        ),
        const SizedBox(height: 1),
        Text(
          label.substring(0, label.length.clamp(0, 4)),
          style: direction.captionStyle(size: 5.5).copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

/// Horizontal swatches for a direction's palette.
class DesignPaletteStrip extends StatelessWidget {
  const DesignPaletteStrip({super.key, required this.direction});

  final DesignDirection direction;

  @override
  Widget build(BuildContext context) {
    final swatches = [
      ('Primary', direction.primary),
      ('Surface', direction.surface),
      ('BG', direction.background),
      ('Text', direction.ink),
      ('Accent', direction.accent),
      ('Border', direction.border),
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final (name, color) in swatches)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: direction.border,
                    width: color == direction.surface ? 1 : 0,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                name,
                style: direction.captionStyle(size: 9).copyWith(
                  color: direction.muted,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

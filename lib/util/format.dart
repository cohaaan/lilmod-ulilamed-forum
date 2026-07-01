import 'package:flutter/material.dart';

import '../theme/forum_palette.dart';

/// A short relative time like "3h ago" / "2d ago".
String relativeTime(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return '$m minute${m == 1 ? '' : 's'} ago';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return '$d day${d == 1 ? '' : 's'} ago';
  }
  if (diff.inDays < 30) {
    final w = (diff.inDays / 7).floor();
    return '$w week${w == 1 ? '' : 's'} ago';
  }
  final mo = (diff.inDays / 30).floor();
  return '$mo month${mo == 1 ? '' : 's'} ago';
}

/// A stable accent colour for a forum category/subforum id, or a hash fallback.
Color accentForId(String id) =>
    ForumPalette.tryForId(id) ?? ForumPalette.forSubforum(id);

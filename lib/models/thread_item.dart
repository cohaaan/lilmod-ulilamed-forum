import 'package:flutter/material.dart';

class ThreadItem {
  const ThreadItem({
    required this.id,
    required this.title,
    required this.type,
    required this.forumName,
    required this.date,
    required this.postCount,
    required this.viewCount,
    required this.latestActivity,
    required this.openedBy,
    required this.latestBy,
    required this.accentColor,
    this.isNew = false,
  });

  final String id;
  final String title;
  final String type;
  final String forumName;
  final String date;
  final int postCount;
  final int viewCount;
  final String latestActivity;
  final String openedBy;
  final String latestBy;
  final Color accentColor;
  final bool isNew;
}

class SidebarThread {
  const SidebarThread({
    required this.id,
    required this.title,
    required this.forumName,
    required this.stats,
    required this.accentColor,
  });

  final String id;
  final String title;
  final String forumName;
  final String stats;
  final Color accentColor;
}

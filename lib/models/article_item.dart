import 'package:flutter/material.dart';

class ArticleItem {
  const ArticleItem({
    required this.slug,
    required this.title,
    required this.category,
    required this.date,
    required this.accentColor,
    this.excerpt,
  });

  final String slug;
  final String title;
  final String category;
  final String date;
  final Color accentColor;
  final String? excerpt;
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';

/// Renders a forum post/reply body, turning any embedded Sefaria source URL
/// into a tappable link that opens the **in-app** Seforim reader at that ref
/// (rather than the Sefaria website). Used for opening posts and replies.
class SourceBodyText extends StatefulWidget {
  const SourceBodyText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  State<SourceBodyText> createState() => _SourceBodyTextState();
}

class _SourceBodyTextState extends State<SourceBodyText> {
  final List<TapGestureRecognizer> _recognizers = [];

  static final _urlRe =
      RegExp(r'https?://(?:www\.)?sefaria\.org/\S+', caseSensitive: false);

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  /// Recover the Sefaria ref ("Exodus 3:1") from a source URL so we can route
  /// to the in-app reader at `/seforim/read/<ref>`.
  String? _refFromUrl(String url) {
    final m =
        RegExp(r'sefaria\.org/(.+)$', caseSensitive: false).firstMatch(url);
    if (m == null) return null;
    var ref = m.group(1)!;
    // Drop trailing punctuation the greedy URL match may have swept up.
    ref = ref.replaceAll(RegExp(r'[.,;:)\]]+$'), '');
    ref = Uri.decodeFull(ref).replaceAll('_', ' ').trim();
    return ref.isEmpty ? null : ref;
  }

  void _open(String url) {
    final ref = _refFromUrl(url);
    if (ref == null) return;
    context.push('/source/${Uri.encodeComponent(ref)}');
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final base = widget.style ?? const TextStyle();
    final linkStyle = base.copyWith(
      color: AppColors.indigo,
      fontWeight: FontWeight.w600,
    );

    final text = widget.text;
    final spans = <InlineSpan>[];
    var i = 0;
    for (final m in _urlRe.allMatches(text)) {
      if (m.start > i) {
        spans.add(TextSpan(text: text.substring(i, m.start)));
      }
      final url = m.group(0)!;
      final rec = TapGestureRecognizer()..onTap = () => _open(url);
      _recognizers.add(rec);
      spans.add(TextSpan(text: 'מקור ↗', style: linkStyle, recognizer: rec));
      i = m.end;
    }
    if (i < text.length) {
      spans.add(TextSpan(text: text.substring(i)));
    }

    return Text.rich(TextSpan(style: base, children: spans));
  }
}

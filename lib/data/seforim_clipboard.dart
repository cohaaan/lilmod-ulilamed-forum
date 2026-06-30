import 'package:flutter/foundation.dart';

import '../config/seforim_config.dart';
import '../models/seforim.dart';

/// A small in-memory queue of sources copied from the Seforim reader, waiting
/// to be inserted into a reply. It's a [ChangeNotifier] so the reply bar can
/// react and show an "Insert" affordance when something is waiting.
///
/// This is the bridge that lets a user browse Seforim, tap "Copy to reply",
/// return to the thread, and drop the source into their in-progress reply.
class SeforimClipboard extends ChangeNotifier {
  final List<String> _blocks = [];

  /// Set when the user opens Seforim from a thread reply bar. The next
  /// "copy to reply" returns to that thread and inserts the source there.
  String? returnThreadId;

  /// Thread detail listens for this to splice queued sources into the reply.
  bool pendingAutoInsert = false;

  int get count => _blocks.length;
  bool get isEmpty => _blocks.isEmpty;
  bool get isNotEmpty => _blocks.isNotEmpty;

  void beginReplyPick(String threadId) => returnThreadId = threadId;

  void cancelReplyPick() {
    returnThreadId = null;
    pendingAutoInsert = false;
  }

  /// Queue a source; returns the thread to navigate back to when this pick was
  /// started from a reply bar, otherwise null.
  String? addSegmentForReply({
    required String ref,
    required String heRef,
    required SeforimSegment segment,
  }) {
    final threadId = returnThreadId;
    addSegment(ref: ref, heRef: heRef, segment: segment);
    if (threadId == null) return null;
    returnThreadId = null;
    pendingAutoInsert = true;
    notifyListeners();
    return threadId;
  }

  /// Queue a formatted source block built from a single segment.
  void addSegment({
    required String ref,
    required String heRef,
    required SeforimSegment segment,
  }) {
    final block = _format(ref: ref, heRef: heRef, segment: segment);
    // Skip an exact duplicate (e.g. an accidental double-tap of "Copy to
    // reply"); distinct sources still queue normally.
    if (_blocks.contains(block)) return;
    _blocks.add(block);
    notifyListeners();
  }

  /// The combined text of all queued blocks, ready to splice into a reply.
  String drain() {
    final text = _blocks.join('\n\n');
    _blocks.clear();
    notifyListeners();
    return text;
  }

  void clear() {
    if (_blocks.isEmpty) return;
    _blocks.clear();
    notifyListeners();
  }

  /// Plain-text source block: the Hebrew text only, followed by a citation
  /// line carrying the source URL. The reply renderer (`SourceBodyText`)
  /// detects that URL and opens the in-app Seforim reader instead of the web.
  String _format({
    required String ref,
    required String heRef,
    required SeforimSegment segment,
  }) {
    final cite = heRef.isNotEmpty ? heRef : ref;
    final lines = <String>[];
    if (segment.hasHe) lines.add(segment.he);
    lines.add('— $cite  ${SeforimConfig.webUrl(ref)}');
    return lines.join('\n');
  }
}

/// Global singleton, mirrors the repository pattern.
final seforimClipboard = SeforimClipboard();

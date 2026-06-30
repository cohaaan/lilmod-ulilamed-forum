import 'package:flutter_test/flutter_test.dart';
import 'package:lilmod_ulilamed/data/composer_draft_store.dart';
import 'package:lilmod_ulilamed/data/seforim_clipboard.dart';
import 'package:lilmod_ulilamed/models/seforim.dart';

void main() {
  group('SeforimClipboard', () {
    test('skips an exact duplicate add (double-tap)', () {
      final c = SeforimClipboard();
      const seg = SeforimSegment(
        number: '1',
        he: 'בְּרֵאשִׁית',
        en: 'In the beginning',
      );
      c.addSegment(ref: 'Genesis 1:1', heRef: 'בראשית א:א', segment: seg);
      c.addSegment(ref: 'Genesis 1:1', heRef: 'בראשית א:א', segment: seg);
      expect(c.count, 1);
    });

    test('queues distinct sources', () {
      final c = SeforimClipboard();
      c.addSegment(
        ref: 'Genesis 1:1',
        heRef: 'a',
        segment: const SeforimSegment(number: '1', he: 'x', en: ''),
      );
      c.addSegment(
        ref: 'Genesis 1:2',
        heRef: 'b',
        segment: const SeforimSegment(number: '2', he: 'y', en: ''),
      );
      expect(c.count, 2);
    });

    test('drain returns combined text and clears', () {
      final c = SeforimClipboard();
      c.addSegment(
        ref: 'Genesis 1:1',
        heRef: 'a',
        segment: const SeforimSegment(number: '1', he: 'x', en: ''),
      );
      final out = c.drain();
      expect(out, contains('x'));
      expect(c.isEmpty, isTrue);
    });

    test('addSegmentForReply returns thread id when picking from a reply', () {
      final c = SeforimClipboard();
      c.beginReplyPick('thread-abc');
      final back = c.addSegmentForReply(
        ref: 'Genesis 1:1',
        heRef: 'a',
        segment: const SeforimSegment(number: '1', he: 'x', en: ''),
      );
      expect(back, 'thread-abc');
      expect(c.returnThreadId, isNull);
      expect(c.pendingAutoInsert, isTrue);
      expect(c.count, 1);
    });

    test('addSegmentForReply without pick stays on seforim flow', () {
      final c = SeforimClipboard();
      final back = c.addSegmentForReply(
        ref: 'Genesis 1:1',
        heRef: 'a',
        segment: const SeforimSegment(number: '1', he: 'x', en: ''),
      );
      expect(back, isNull);
      expect(c.pendingAutoInsert, isFalse);
    });
  });

  group('ComposerDraftStore', () {
    test('returns null when no draft / empty', () {
      final s = ComposerDraftStore();
      expect(s.get('t1'), isNull);
    });

    test('round-trips a draft', () {
      final s = ComposerDraftStore();
      s.set('t1', 'half a reply');
      expect(s.get('t1'), 'half a reply');
    });

    test('whitespace-only text is treated as no draft', () {
      final s = ComposerDraftStore();
      s.set('t1', '   ');
      expect(s.get('t1'), isNull);
    });

    test('setting empty string clears the draft', () {
      final s = ComposerDraftStore();
      s.set('t1', 'something');
      s.set('t1', '');
      expect(s.get('t1'), isNull);
    });

    test('clear removes the draft, others untouched', () {
      final s = ComposerDraftStore();
      s.set('t1', 'a');
      s.set('t2', 'b');
      s.clear('t1');
      expect(s.get('t1'), isNull);
      expect(s.get('t2'), 'b');
    });
  });

  group('SeforimNode.fromJson', () {
    test('parses a category with nested book contents', () {
      final node = SeforimNode.fromJson({
        'category': 'Talmud',
        'heCategory': 'תלמוד',
        'contents': [
          {
            'title': 'Berakhot',
            'heTitle': 'ברכות',
            'categories': ['Talmud', 'Bavli'],
          },
          'not-a-map', // should be filtered by whereType
        ],
      });

      expect(node.isCategory, isTrue);
      expect(node.isBook, isFalse);
      expect(node.label, 'Talmud');
      expect(node.heLabel, 'תלמוד');
      expect(node.contents.length, 1);

      final book = node.contents.first;
      expect(book.isBook, isTrue);
      expect(book.label, 'Berakhot');
      expect(book.isTalmud, isTrue);
    });

    test('a non-Talmud book is not flagged as Talmud', () {
      final node = SeforimNode.fromJson({
        'title': 'Genesis',
        'categories': ['Tanakh', 'Torah'],
      });
      expect(node.isBook, isTrue);
      expect(node.isTalmud, isFalse);
      expect(node.label, 'Genesis');
    });

    test('missing fields default to empty, no throw', () {
      final node = SeforimNode.fromJson({});
      expect(node.contents, isEmpty);
      expect(node.categories, isEmpty);
      expect(node.label, '');
      expect(node.heLabel, '');
    });
  });

  group('ShapeNode.fromJson', () {
    test('simple text parses chapters and defaults length', () {
      final shape = ShapeNode.fromJson({
        'title': 'Berakhot',
        'heTitle': 'ברכות',
        'chapters': [0, 0, 14, 19, 15],
      });
      expect(shape.isComplex, isFalse);
      expect(shape.isSimple, isTrue);
      expect(shape.chapters, [0, 0, 14, 19, 15]);
      expect(shape.length, 5); // defaults to chapters.length when absent
    });

    test('numeric (double) chapter counts are coerced to int', () {
      final shape = ShapeNode.fromJson({
        'title': 'X',
        'heTitle': 'X',
        'chapters': [1.0, 2.0, 3.0],
      });
      expect(shape.chapters, [1, 2, 3]);
    });

    test('complex chapters (nested) clear the flat list / not simple', () {
      final shape = ShapeNode.fromJson({
        'title': 'Complex',
        'heTitle': 'Complex',
        'chapters': [
          [1, 2],
          [3, 4],
        ],
        'isComplex': true,
      });
      expect(shape.chapters, isEmpty);
      expect(shape.isSimple, isFalse);
    });

    test('falls back to book/heBook keys for the title', () {
      final shape = ShapeNode.fromJson({
        'book': 'Genesis',
        'heBook': 'בראשית',
        'chapters': [31, 25],
      });
      expect(shape.title, 'Genesis');
      expect(shape.heTitle, 'בראשית');
    });
  });
}

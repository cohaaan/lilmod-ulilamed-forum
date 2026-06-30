import 'package:flutter_test/flutter_test.dart';
import 'package:lilmod_ulilamed/models/post.dart';
import 'package:lilmod_ulilamed/models/thread.dart';
import 'package:lilmod_ulilamed/util/format.dart';

void main() {
  group('Thread.fromMap', () {
    test('parses joined author + subforum and counts', () {
      final thread = Thread.fromMap({
        'id': 't1',
        'subforum_id': 'gemara',
        'author_id': 'u1',
        'title': 'A sugya',
        'body': 'text',
        'type': 'Question',
        'reply_count': 3,
        'like_count': 2,
        'view_count': 11,
        'last_activity_at': '2026-06-29T12:00:00Z',
        'created_at': '2026-06-29T11:00:00Z',
        'author': {'display_name': 'Philo', 'avatar_url': null},
        'subforum': {'id': 'gemara', 'name': 'Gemara'},
      });

      expect(thread.title, 'A sugya');
      expect(thread.authorName, 'Philo');
      expect(thread.subforumName, 'Gemara');
      expect(thread.replyCount, 3);
      expect(thread.likeCount, 2);
      expect(thread.type, 'Question');
    });

    test('falls back to Member when author is missing', () {
      final thread = Thread.fromMap({
        'id': 't2',
        'subforum_id': 's',
        'author_id': 'u',
        'title': 'x',
        'reply_count': 0,
        'like_count': 0,
        'view_count': 0,
        'last_activity_at': '2026-06-29T12:00:00Z',
        'created_at': '2026-06-29T12:00:00Z',
      });
      expect(thread.authorName, 'Member');
    });
  });

  group('Post.fromMap', () {
    test('marks likedByMe from the liked set', () {
      final post = Post.fromMap(
        {
          'id': 'p1',
          'thread_id': 't1',
          'author_id': 'u1',
          'parent_post_id': null,
          'body': 'hello',
          'like_count': 1,
          'created_at': '2026-06-29T12:00:00Z',
          'author': {'display_name': 'Leib'},
        },
        likedPostIds: {'p1'},
      );
      expect(post.likedByMe, isTrue);
      expect(post.isReply, isFalse);
      expect(post.authorName, 'Leib');
    });
  });

  group('helpers', () {
    test('relativeTime buckets', () {
      expect(relativeTime(DateTime.now()), 'just now');
      expect(
        relativeTime(DateTime.now().subtract(const Duration(minutes: 5))),
        '5 minutes ago',
      );
      expect(
        relativeTime(DateTime.now().subtract(const Duration(hours: 2))),
        '2 hours ago',
      );
    });

    test('accentForId is deterministic', () {
      expect(accentForId('gemara'), accentForId('gemara'));
    });
  });
}

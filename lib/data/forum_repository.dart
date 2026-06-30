import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/category.dart';
import '../models/post.dart';
import '../models/profile.dart';
import '../models/thread.dart';

// Pin the FK explicitly: threads/posts each have multiple relationships to
// profiles (author + likes/bookmarks join tables), so the embed is otherwise
// ambiguous and PostgREST rejects it (PGRST201).
const _threadSelect =
    '*, author:profiles!threads_author_id_fkey(id,display_name,avatar_url), '
    'subforum:subforums(id,name)';
const _postSelect =
    '*, author:profiles!posts_author_id_fkey(id,display_name,avatar_url)';

/// Categories hidden from browse lists (meta / off-topic for launch).
const _hiddenCategoryIds = {
  'technical-help',
  'marketplace',
  'community-site',
};

/// All forum reads/writes go through here. Backed by Supabase + RLS.
class ForumRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  // ---------------------------------------------------------------- taxonomy
  Future<List<Category>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select('id,name,description,position,'
            'subforums(id,category_id,name,description,position)')
        .order('position');

    final counts = await _fetchSubforumCounts();

    return rows
        .where((c) => !_hiddenCategoryIds.contains(c['id'] as String))
        .map<Category>((c) {
          final subs = ((c['subforums'] as List?) ?? const [])
              .cast<Map<String, dynamic>>()
              .map((s) => Subforum.fromMap(s)
                  .copyWith(threadCount: counts[s['id']] ?? 0))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));
          return Category.fromMap(c).withSubforums(subs);
        })
        .toList();
  }

  Future<Map<String, int>> _fetchSubforumCounts() async {
    final rows = await _client
        .from('subforum_thread_counts')
        .select('subforum_id,thread_count');
    return {
      for (final r in rows)
        r['subforum_id'] as String: (r['thread_count'] as num).toInt(),
    };
  }

  /// Subforum ids that belong to a hidden category. Cached for the session so
  /// "Latest" and Search can exclude hidden content the same way Browse does.
  Set<String>? _hiddenSubIds;
  Future<Set<String>> _hiddenSubforumIds() async {
    if (_hiddenSubIds != null) return _hiddenSubIds!;
    if (_hiddenCategoryIds.isEmpty) return _hiddenSubIds = {};
    final rows = await _client
        .from('subforums')
        .select('id')
        .inFilter('category_id', _hiddenCategoryIds.toList());
    return _hiddenSubIds = rows.map<String>((r) => r['id'] as String).toSet();
  }

  Future<Category?> fetchCategory(String id) async {
    final all = await fetchCategories();
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<Subforum?> fetchSubforum(String id) async {
    final row = await _client
        .from('subforums')
        .select('id,category_id,name,description')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Subforum.fromMap(row);
  }

  // ------------------------------------------------------------------ threads
  Future<List<Thread>> fetchRecentThreads({int limit = 12}) async {
    final hidden = await _hiddenSubforumIds();
    var query = _client.from('threads').select(_threadSelect);
    if (hidden.isNotEmpty) {
      query = query.not('subforum_id', 'in', '(${hidden.join(',')})');
    }
    final rows =
        await query.order('last_activity_at', ascending: false).limit(limit);
    return rows.map<Thread>((m) => Thread.fromMap(m)).toList();
  }

  Future<List<Thread>> fetchThreadsForSubforum(String subforumId) async {
    final rows = await _client
        .from('threads')
        .select(_threadSelect)
        .eq('subforum_id', subforumId)
        .order('is_pinned', ascending: false)
        .order('last_activity_at', ascending: false)
        .limit(100);
    return rows.map<Thread>((m) => Thread.fromMap(m)).toList();
  }

  Future<Thread?> fetchThread(String id) async {
    final row = await _client
        .from('threads')
        .select(_threadSelect)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Thread.fromMap(row);
  }

  Future<List<Thread>> searchThreads(String query) async {
    final q = query.trim();
    if (q.isEmpty) return fetchRecentThreads(limit: 20);
    // Quote the value so PostgREST treats reserved characters (comma,
    // parentheses) as literal text rather than filter syntax; escape any
    // embedded backslashes/quotes first.
    final safe = q.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    final hidden = await _hiddenSubforumIds();
    var req = _client
        .from('threads')
        .select(_threadSelect)
        .or('title.ilike."%$safe%",body.ilike."%$safe%"');
    if (hidden.isNotEmpty) {
      req = req.not('subforum_id', 'in', '(${hidden.join(',')})');
    }
    final rows =
        await req.order('last_activity_at', ascending: false).limit(30);
    return rows.map<Thread>((m) => Thread.fromMap(m)).toList();
  }

  Future<String> createThread({
    required String subforumId,
    required String title,
    required String body,
    String type = 'Discussion',
  }) async {
    final row = await _client
        .from('threads')
        .insert({
          'subforum_id': subforumId,
          'author_id': _uid,
          'title': title.trim(),
          'body': body.trim(),
          'type': type,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> updateThread(
    String id, {
    String? title,
    String? body,
    String? type,
  }) async {
    final patch = <String, dynamic>{};
    if (title != null) patch['title'] = title.trim();
    if (body != null) patch['body'] = body.trim();
    if (type != null) patch['type'] = type;
    if (patch.isEmpty) return;
    await _client.from('threads').update(patch).eq('id', id);
  }

  Future<void> deleteThread(String id) =>
      _client.from('threads').delete().eq('id', id);

  /// Threads the current user has bookmarked, most recent first.
  Future<List<Thread>> fetchBookmarkedThreads() async {
    final uid = _uid;
    if (uid == null) return [];
    final rows = await _client
        .from('bookmarks')
        .select('created_at, thread:threads($_threadSelect)')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return rows
        .where((r) => r['thread'] != null)
        .map<Thread>((r) => Thread.fromMap(r['thread'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> incrementView(String threadId) async {
    try {
      await _client.rpc('increment_thread_view',
          params: {'p_thread_id': threadId});
    } catch (_) {
      // View counting is best-effort; never block the UI on it.
    }
  }

  // -------------------------------------------------------------------- posts
  Future<List<Post>> fetchPosts(String threadId) async {
    final rows = await _client
        .from('posts')
        .select(_postSelect)
        .eq('thread_id', threadId)
        .order('created_at', ascending: true)
        .limit(500);
    return rows.map<Post>((m) => Post.fromMap(m)).toList();
  }

  Future<void> createPost({
    required String threadId,
    required String body,
    String? parentPostId,
  }) async {
    await _client.from('posts').insert({
      'thread_id': threadId,
      'author_id': _uid,
      'parent_post_id': parentPostId,
      'body': body.trim(),
    });
  }

  Future<void> updatePost(String id, String body) =>
      _client.from('posts').update({'body': body.trim()}).eq('id', id);

  Future<void> deletePost(String id) =>
      _client.from('posts').delete().eq('id', id);

  // ----------------------------------------------------------------- profile
  Future<Profile?> fetchMyProfile() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('profiles')
        .select('id,display_name,avatar_url')
        .eq('id', uid)
        .maybeSingle();
    return row == null ? null : Profile.fromMap(row);
  }

  Future<void> updateMyProfile({required String displayName}) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('profiles')
        .update({'display_name': displayName.trim()}).eq('id', uid);
  }

  // ------------------------------------------------------------------ bookmarks
  Future<bool> isBookmarked(String threadId) async {
    final uid = _uid;
    if (uid == null) return false;
    final row = await _client
        .from('bookmarks')
        .select('thread_id')
        .eq('thread_id', threadId)
        .eq('user_id', uid)
        .maybeSingle();
    return row != null;
  }

  Future<bool> toggleBookmark(String threadId, bool currentlyBookmarked) async {
    final uid = _uid;
    if (uid == null) return currentlyBookmarked;
    if (currentlyBookmarked) {
      await _client
          .from('bookmarks')
          .delete()
          .eq('thread_id', threadId)
          .eq('user_id', uid);
      return false;
    }
    await _client.from('bookmarks').insert({'thread_id': threadId, 'user_id': uid});
    return true;
  }
}

class Thread {
  const Thread({
    required this.id,
    required this.subforumId,
    required this.authorId,
    required this.title,
    required this.body,
    required this.type,
    required this.replyCount,
    required this.likeCount,
    required this.viewCount,
    required this.lastActivityAt,
    required this.createdAt,
    required this.authorName,
    this.authorAvatar,
    this.subforumName,
  });

  final String id;
  final String subforumId;
  final String authorId;
  final String title;
  final String body;
  final String type;
  final int replyCount;
  final int likeCount;
  final int viewCount;
  final DateTime lastActivityAt;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatar;
  final String? subforumName;

  bool get isNew =>
      DateTime.now().difference(createdAt) < const Duration(hours: 24);

  factory Thread.fromMap(Map<String, dynamic> map) {
    final author = map['author'] as Map<String, dynamic>?;
    final subforum = map['subforum'] as Map<String, dynamic>?;
    return Thread(
      id: map['id'] as String,
      subforumId: map['subforum_id'] as String,
      authorId: map['author_id'] as String,
      title: map['title'] as String,
      body: map['body'] as String? ?? '',
      type: map['type'] as String? ?? 'Discussion',
      replyCount: (map['reply_count'] as num?)?.toInt() ?? 0,
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      viewCount: (map['view_count'] as num?)?.toInt() ?? 0,
      lastActivityAt: DateTime.parse(map['last_activity_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      authorName: (author?['display_name'] as String?) ?? 'Member',
      authorAvatar: author?['avatar_url'] as String?,
      subforumName: subforum?['name'] as String?,
    );
  }
}

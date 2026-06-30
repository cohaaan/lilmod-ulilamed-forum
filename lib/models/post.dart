class Post {
  const Post({
    required this.id,
    required this.threadId,
    required this.authorId,
    required this.body,
    required this.likeCount,
    required this.createdAt,
    required this.authorName,
    this.parentPostId,
    this.authorAvatar,
    this.likedByMe = false,
  });

  final String id;
  final String threadId;
  final String authorId;
  final String? parentPostId;
  final String body;
  final int likeCount;
  final DateTime createdAt;
  final String authorName;
  final String? authorAvatar;
  final bool likedByMe;

  bool get isReply => parentPostId != null;

  factory Post.fromMap(
    Map<String, dynamic> map, {
    Set<String> likedPostIds = const {},
  }) {
    final author = map['author'] as Map<String, dynamic>?;
    final id = map['id'] as String;
    return Post(
      id: id,
      threadId: map['thread_id'] as String,
      authorId: map['author_id'] as String,
      parentPostId: map['parent_post_id'] as String?,
      body: map['body'] as String? ?? '',
      likeCount: (map['like_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      authorName: (author?['display_name'] as String?) ?? 'Member',
      authorAvatar: author?['avatar_url'] as String?,
      likedByMe: likedPostIds.contains(id),
    );
  }
}

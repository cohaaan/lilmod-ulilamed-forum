import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/composer_draft_store.dart';
import '../data/repositories.dart';
import '../data/seforim_clipboard.dart';
import '../models/post.dart';
import '../models/thread.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../util/format.dart';
import 'edit_thread_screen.dart';
import '../utils/share_link.dart';
import '../widgets/avatar.dart';
import '../widgets/soft_card.dart';
import '../widgets/source_body_text.dart';

class ThreadDetailScreen extends StatefulWidget {
  const ThreadDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ThreadDetailScreen> createState() => _ThreadDetailScreenState();
}

class _ThreadDetailScreenState extends State<ThreadDetailScreen> {
  final _replyController = TextEditingController();
  final _scrollController = ScrollController();
  final _replyFocus = FocusNode();

  Thread? _thread;
  List<Post> _posts = [];
  bool _loading = true;
  bool _error = false;
  bool _bookmarked = false;
  bool _sending = false;

  /// When set, the next reply is posted as a child of this post.
  Post? _replyingTo;

  /// Per-reply keys so tapping "Replying to …" can scroll to the parent, and
  /// the id of the reply currently flashed after such a jump.
  final Map<String, GlobalKey> _postKeys = {};
  String? _highlightedPostId;

  /// Replies whose descendant subtree is hidden (keyed by post id). Threads are
  /// expanded by default; collapsing hides everything below that reply.
  final Set<String> _collapsed = {};

  GlobalKey _keyFor(String postId) =>
      _postKeys.putIfAbsent(postId, () => GlobalKey());

  List<Post> _childrenOf(String? parentId) {
    final out = _posts.where((p) => p.parentPostId == parentId).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return out;
  }

  Post? _postById(String id) {
    for (final p in _posts) {
      if (p.id == id) return p;
    }
    return null;
  }

  int _descendantCount(String postId) {
    var n = 0;
    for (final child in _childrenOf(postId)) {
      n += 1 + _descendantCount(child.id);
    }
    return n;
  }

  /// A one-line preview of the reply being answered, for the "Replying to …"
  /// chip. Source URLs collapse to a short label so the chip stays readable.
  String _replySnippet(Post parent) {
    final text = parent.body
        .replaceAll(
          RegExp(r'https?://(?:www\.)?sefaria\.org/\S+', caseSensitive: false),
          'מקור',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return '';
    if (text.length <= 42) return text;
    return '${text.substring(0, 42)}…';
  }

  /// Flattens the reply tree into a single reading-order column. Each reply
  /// carries its own `Replying to <author>` chip, so context travels with the
  /// reply instead of relying on deep indentation. A collapsed reply hides its
  /// whole subtree.
  List<Widget> _replyWidgets() {
    final widgets = <Widget>[];
    final placed = <String>{};

    void walk(Post post, int depth) {
      if (!placed.add(post.id)) return;
      final parent = post.parentPostId == null
          ? null
          : _postById(post.parentPostId!);
      final childCount = _descendantCount(post.id);
      final collapsed = _collapsed.contains(post.id);
      widgets.add(
        _FlatReply(
          key: _keyFor(post.id),
          post: post,
          parentName: parent?.authorName,
          parentSnippet: parent == null ? null : _replySnippet(parent),
          depth: depth,
          highlighted: _highlightedPostId == post.id,
          isMine: post.authorId == _uid,
          descendantCount: childCount,
          collapsed: collapsed,
          onToggleCollapse: childCount == 0
              ? null
              : () => setState(() {
                    if (!_collapsed.remove(post.id)) _collapsed.add(post.id);
                  }),
          onReply: () => _startReply(post),
          onJumpToParent:
              parent == null ? null : () => _jumpToParent(parent.id),
          onEdit: () => _editPost(post),
          onDelete: () => _deletePost(post),
        ),
      );
      if (!collapsed) {
        for (final child in _childrenOf(post.id)) {
          walk(child, depth + 1);
        }
      }
    }

    for (final top in _childrenOf(null)) {
      walk(top, 0);
    }
    // Any orphaned replies (parent no longer loaded) still get shown.
    for (final p in _posts) {
      if (!placed.contains(p.id)) walk(p, 0);
    }
    return widgets;
  }

  /// Scrolls to the parent reply and briefly highlights it, so a reader can
  /// confirm exactly what a reply is answering.
  void _jumpToParent(String parentId) {
    final ctx = _postKeys[parentId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }
    setState(() => _highlightedPostId = parentId);
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted && _highlightedPostId == parentId) {
        setState(() => _highlightedPostId = null);
      }
    });
  }

  String? get _uid => authRepository.currentUser?.id;

  void _startReply(Post post) {
    setState(() => _replyingTo = post);
    _replyFocus.requestFocus();
  }

  /// Reply to the opening post / thread itself (a top-level reply).
  void _replyToThread() {
    setState(() => _replyingTo = null);
    _replyFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() => _replyingTo = null);
    _replyFocus.unfocus();
  }

  @override
  void initState() {
    super.initState();
    // Restore any in-progress reply for this thread (e.g. after a trip to the
    // Seforim tab), then keep the draft store in sync as the user types.
    final draft = composerDraftStore.get(widget.threadId);
    if (draft != null) _replyController.text = draft;
    _replyController.addListener(_persistDraft);
    seforimClipboard.addListener(_onSeforimClipboardChanged);
    _load();
    forumRepository.incrementView(widget.threadId);
  }

  /// When Seforim "copy to reply" was started from this thread's reply bar,
  /// splice the queued source into the reply box as soon as it lands.
  void _onSeforimClipboardChanged() {
    if (!mounted || !seforimClipboard.pendingAutoInsert) return;
    seforimClipboard.pendingAutoInsert = false;
    if (seforimClipboard.isNotEmpty) _insertSources();
  }

  void _persistDraft() =>
      composerDraftStore.set(widget.threadId, _replyController.text);

  /// Splice any sources copied from the Seforim reader into the reply box at
  /// the cursor, then clear the queue.
  void _insertSources() {
    final sources = seforimClipboard.drain();
    if (sources.isEmpty) return;
    final current = _replyController.text;
    final sel = _replyController.selection;
    final at = sel.isValid ? sel.start : current.length;
    final end = sel.isValid ? sel.end : current.length;
    final before = current.substring(0, at);
    final needsLead = before.isNotEmpty && !before.endsWith('\n');
    final block = '${needsLead ? '\n' : ''}$sources\n';
    _replyController.value = TextEditingValue(
      text: current.replaceRange(at, end, block),
      selection: TextSelection.collapsed(offset: at + block.length),
    );
    _replyFocus.requestFocus();
  }

  @override
  void dispose() {
    seforimClipboard.removeListener(_onSeforimClipboardChanged);
    if (seforimClipboard.returnThreadId == widget.threadId) {
      seforimClipboard.cancelReplyPick();
    }
    _replyController.removeListener(_persistDraft);
    _replyController.dispose();
    _scrollController.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final results = await Future.wait([
        forumRepository.fetchThread(widget.threadId),
        forumRepository.fetchPosts(widget.threadId),
        forumRepository.isBookmarked(widget.threadId),
      ]);
      if (!mounted) return;
      setState(() {
        _thread = results[0] as Thread?;
        _posts = results[1] as List<Post>;
        _bookmarked = results[2] as bool;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _toggleBookmark() async {
    final t = _thread;
    if (t == null) return;
    final was = _bookmarked;
    setState(() => _bookmarked = !was);
    try {
      await forumRepository.toggleBookmark(t.id, was);
    } catch (_) {
      if (mounted) setState(() => _bookmarked = was);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    // Only thread the reply if the target still exists in the loaded list.
    final target = _replyingTo;
    final parentId =
        (target != null && _posts.any((p) => p.id == target.id))
            ? target.id
            : null;
    try {
      await forumRepository.createPost(
        threadId: widget.threadId,
        body: text,
        parentPostId: parentId,
      );
      _replyController.clear();
      composerDraftStore.clear(widget.threadId);
      if (mounted) {
        setState(() => _replyingTo = null);
        FocusScope.of(context).unfocus();
      }
      await _load();
      // Make sure the new reply is visible: un-collapse its whole ancestry.
      if (parentId != null && mounted) {
        setState(() {
          var cur = _postById(parentId);
          while (cur != null) {
            _collapsed.remove(cur.id);
            cur = cur.parentPostId == null ? null : _postById(cur.parentPostId!);
          }
        });
      }
      // Scroll to the newest reply.
      await Future.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post your reply.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteThread() async {
    final ok = await _confirm('Delete this thread?',
        'This removes the thread and all its replies.');
    if (ok != true) return;
    try {
      await forumRepository.deleteThread(widget.threadId);
      if (!mounted) return;
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the thread.')),
        );
      }
    }
  }

  Future<void> _deletePost(Post post) async {
    final ok = await _confirm('Delete this reply?',
        'This cannot be undone. Any replies to it are removed too.');
    if (ok != true) return;
    // If we were replying to this post, drop the target so the reply bar
    // doesn't point at a deleted reply.
    if (_replyingTo?.id == post.id) {
      setState(() => _replyingTo = null);
    }
    try {
      await forumRepository.deletePost(post.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete the reply.')),
        );
      }
    }
  }

  Future<void> _editThread() async {
    final t = _thread;
    if (t == null) return;
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditThreadScreen(
          threadId: t.id,
          initialTitle: t.title,
          initialBody: t.body,
          initialType: t.type,
        ),
      ),
    );
    if (updated == true && mounted) await _load();
  }

  Future<void> _editPost(Post post) async {
    final controller = TextEditingController(text: post.body);
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit reply',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        content: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Edit your reply…'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    final newBody = controller.text.trim();
    controller.dispose();
    if (saved != true) return;
    if (newBody.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply can’t be empty.')),
        );
      }
      return;
    }
    if (newBody == post.body.trim()) return;
    try {
      await forumRepository.updatePost(post.id, newBody);
      if (mounted) await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the reply.')),
        );
      }
    }
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(message, style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.like),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final thread = _thread;
    final isAuthor = thread != null && thread.authorId == _uid;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: Text(
          _thread?.subforumName ?? 'Thread',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.section.copyWith(
            fontSize: 16,
            color: AppColors.useAubergineHeader ? Colors.white : AppColors.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _bookmarked ? 'Bookmarked' : 'Bookmark',
            icon: Icon(
              _bookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 20,
              color: _bookmarked
                  ? (AppColors.useAubergineHeader ? Colors.white : AppColors.indigo)
                  : (AppColors.useAubergineHeader ? Colors.white : AppColors.ink),
            ),
            onPressed: thread == null ? null : _toggleBookmark,
          ),
          IconButton(
            tooltip: 'Copy link',
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () => copyForumLink(
              context,
              '/threads/${widget.threadId}',
              label: 'Thread link copied',
            ),
          ),
          if (isAuthor)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _editThread();
                if (v == 'delete') _deleteThread();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit thread')),
                PopupMenuItem(value: 'delete', child: Text('Delete thread')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.4))
          : _error || thread == null
              ? _ErrorBody(onRetry: _load)
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          children: [
                            _OriginalPost(
                              thread: thread,
                              onReply: _replyToThread,
                            ),
                            const SizedBox(height: 20),
                            Divider(height: 1, color: AppColors.line),
                            const SizedBox(height: 16),
                            Text(
                              '${thread.replyCount} '
                              '${thread.replyCount == 1 ? 'reply' : 'replies'}',
                              style: AppText.section.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_posts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  'No replies yet. Start the conversation.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppColors.muted,
                                  ),
                                ),
                              )
                            else
                              ..._replyWidgets(),
                          ],
                        ),
                      ),
                    ),
                    _ReplyBar(
                      controller: _replyController,
                      focusNode: _replyFocus,
                      sending: _sending,
                      replyingToName: _replyingTo?.authorName,
                      onCancelReply: _cancelReply,
                      onSend: _sendReply,
                      onInsertSources: _insertSources,
                      onOpenSeforim: () {
                        seforimClipboard.beginReplyPick(widget.threadId);
                        context.go('/seforim');
                      },
                    ),
                  ],
                ),
    );
  }

}

class _OriginalPost extends StatelessWidget {
  const _OriginalPost({required this.thread, required this.onReply});

  final Thread thread;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    // Rendered as a full-width "document" (no card chrome) so the opening
    // post reads like an article — the subforum context now lives in the
    // AppBar title, so the location tag here is redundant and removed.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Avatar(name: thread.authorName, size: 42),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread.authorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(relativeTime(thread.createdAt), style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ReplyChip(onTap: onReply),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(thread.title, style: AppText.title),
        if (thread.body.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md - 4),
          SourceBodyText(thread.body, style: AppText.reading),
        ],
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: Tag(label: thread.type),
        ),
        Divider(height: 28, color: AppColors.line),
        Row(
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 16, color: AppColors.muted),
            const SizedBox(width: 5),
            Text('${thread.replyCount}', style: AppText.caption),
            const SizedBox(width: 18),
            Icon(Icons.remove_red_eye_outlined,
                size: 16, color: AppColors.muted),
            const SizedBox(width: 5),
            Text('${thread.viewCount}', style: AppText.caption),
          ],
        ),
      ],
    );
  }
}

class _ReplyChip extends StatelessWidget {
  const _ReplyChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.indigo.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reply_rounded, size: 15, color: AppColors.indigo),
              const SizedBox(width: 5),
              Text(
                'Reply',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.indigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlatReply extends StatelessWidget {
  const _FlatReply({
    super.key,
    required this.post,
    this.parentName,
    this.parentSnippet,
    required this.depth,
    required this.highlighted,
    required this.isMine,
    required this.descendantCount,
    required this.collapsed,
    this.onToggleCollapse,
    required this.onReply,
    this.onJumpToParent,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final String? parentName;
  final String? parentSnippet;
  final int depth;
  final bool highlighted;
  final bool isMine;
  final int descendantCount;
  final bool collapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback onReply;
  final VoidCallback? onJumpToParent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const _depthIndent = 14.0;
  static const _maxDepthIndent = 56.0;

  @override
  Widget build(BuildContext context) {
    final leftPad = (depth * _depthIndent).clamp(0.0, _maxDepthIndent);
    final avatarSize = depth == 0 ? 34.0 : (depth == 1 ? 30.0 : 26.0);

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parentName != null && onJumpToParent != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: _ReplyingToHeader(
              authorName: parentName!,
              snippet: parentSnippet ?? '',
              onTap: onJumpToParent!,
              compact: depth > 1,
            ),
          ),
          const SizedBox(height: 6),
        ],
        _ReplyHighlight(
          highlighted: highlighted,
          child: _CommentRow(
            post: post,
            avatarSize: avatarSize,
            isMine: isMine,
            onReply: onReply,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
        ),
        if (descendantCount > 0 && onToggleCollapse != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onToggleCollapse,
              borderRadius: BorderRadius.circular(5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      collapsed ? '▶' : '▼',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.indigo,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      collapsed
                          ? 'Show $descendantCount '
                              '${descendantCount == 1 ? 'reply' : 'replies'}'
                          : 'Hide ${descendantCount == 1 ? 'reply' : 'replies'}',
                      style: AppText.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );

    // Nested replies get a thin left rail so the eye can still see the branch,
    // but context lives in the "Replying to" chip — so we never indent deeply.
    if (depth == 0) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: column,
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: leftPad, bottom: 4),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.line, width: 2),
          ),
        ),
        child: column,
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.post,
    required this.avatarSize,
    required this.isMine,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final double avatarSize;
  final bool isMine;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: post.authorName, size: avatarSize),
          const SizedBox(width: 12),
          Expanded(
            child: _CommentBody(
              post: post,
              isMine: isMine,
              nameSize: 13,
              onReply: onReply,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBody extends StatelessWidget {
  const _CommentBody({
    required this.post,
    required this.isMine,
    required this.nameSize,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final bool isMine;
  final double nameSize;
  final VoidCallback onReply;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                post.authorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.label.copyWith(
                  fontSize: nameSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              relativeTime(post.createdAt),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(fontSize: 11),
            ),
            if (isMine) ...[
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                tooltip: 'Options',
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                child: Icon(Icons.more_horiz_rounded,
                    size: 18, color: AppColors.muted),
              ),
            ],
          ],
        ),
        const SizedBox(height: 5),
        SourceBodyText(
          post.body,
          style: AppText.body.copyWith(fontSize: 14, height: 1.45),
        ),
        const SizedBox(height: 9),
        _ReplyLinkButton(onTap: onReply),
      ],
    );
  }
}

/// The `↳ Replying to <author>: <snippet>` chip. The author name is the
/// primary who-answers-whom signal; the snippet is a secondary preview and is
/// dropped when the parent has no text (e.g. a source-only reply).
class _ReplyingToHeader extends StatelessWidget {
  const _ReplyingToHeader({
    required this.authorName,
    required this.snippet,
    required this.onTap,
    this.compact = false,
  });

  final String authorName;
  final String snippet;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final quoteStyle = TextStyle(
      fontWeight: FontWeight.w600,
      color: AppColors.body.withValues(alpha: 0.85),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.indigo.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: AppText.caption.copyWith(
              fontSize: compact ? 10.5 : 11,
              fontWeight: FontWeight.w800,
              color: AppColors.indigo,
            ),
            children: [
              const TextSpan(text: '↳ Replying to '),
              TextSpan(text: authorName),
              if (snippet.isNotEmpty) ...[
                TextSpan(text: ': ', style: quoteStyle),
                TextSpan(text: '“$snippet”', style: quoteStyle),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReplyLinkButton extends StatelessWidget {
  const _ReplyLinkButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '↩ Reply',
          style: AppText.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF5D6878),
          ),
        ),
      ),
    );
  }
}

class _ReplyHighlight extends StatelessWidget {
  const _ReplyHighlight({required this.highlighted, required this.child});

  final bool highlighted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.indigo.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlighted
              ? AppColors.indigo.withValues(alpha: 0.45)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

class _ReplyBar extends StatelessWidget {
  const _ReplyBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onInsertSources,
    required this.onOpenSeforim,
    this.replyingToName,
    this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onInsertSources;
  final VoidCallback onOpenSeforim;
  final String? replyingToName;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    final replying = replyingToName != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replying)
              Container(
                width: double.infinity,
                color: AppColors.surfaceMuted,
                padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 15, color: AppColors.indigo),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to $replyingToName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.indigo,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onCancelReply,
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            // Shows when the user has copied source(s) from the Seforim reader.
            ListenableBuilder(
              listenable: seforimClipboard,
              builder: (context, _) {
                if (seforimClipboard.isEmpty) return const SizedBox.shrink();
                final n = seforimClipboard.count;
                return InkWell(
                  onTap: onInsertSources,
                  child: Container(
                    width: double.infinity,
                    color: AppColors.indigo.withValues(alpha: 0.08),
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    child: Row(
                      children: [
                        Icon(Icons.auto_stories_rounded,
                            size: 15, color: AppColors.indigo),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$n source${n == 1 ? '' : 's'} ready',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo,
                            ),
                          ),
                        ),
                        Text(
                          'Insert',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.add_rounded,
                            size: 16, color: AppColors.indigo),
                      ],
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Browse seforim',
                    onPressed: onOpenSeforim,
                    icon: Icon(Icons.auto_stories_outlined,
                        color: AppColors.indigo),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText:
                            replying ? 'Reply to $replyingToName…' : 'Write a reply…',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: sending ? null : onSend,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.indigo,
                        shape: BoxShape.circle,
                      ),
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.muted),
          const SizedBox(height: 12),
          Text(
            "Couldn't load this discussion.",
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

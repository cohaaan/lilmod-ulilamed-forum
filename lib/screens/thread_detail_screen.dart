import 'package:flutter/foundation.dart';
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

  GlobalKey _keyFor(String postId) =>
      _postKeys.putIfAbsent(postId, () => GlobalKey());

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

  /// Posts arranged as a tree (each parent immediately followed by its
  /// descendants), with the nesting depth and per-level connector state used to
  /// draw the threading lines.
  ///
  /// `lanes` has one entry per indentation level (length == depth). For an outer
  /// lane it says whether that ancestor's vertical line should keep running past
  /// this row (i.e. the ancestor has a later sibling). The last entry is the
  /// node's own "elbow" lane and says whether THIS node has a following sibling,
  /// so the spine continues down to it.
  List<
      ({
        Post post,
        int depth,
        String? parentName,
        List<bool> lanes,
        bool hasChildren
      })> _threadedPosts() {
    final byParent = <String?, List<Post>>{};
    final byId = {for (final p in _posts) p.id: p};
    for (final p in _posts) {
      byParent.putIfAbsent(p.parentPostId, () => []).add(p);
    }
    final result = <({
      Post post,
      int depth,
      String? parentName,
      List<bool> lanes,
      bool hasChildren
    })>[];
    final seen = <String>{};
    void walk(String? parentId, int depth, List<bool> parentLanes) {
      final children = byParent[parentId] ?? const <Post>[];
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        if (!seen.add(child.id)) continue; // guard against any cycle
        final hasNext = i < children.length - 1;
        // Top-level replies aren't connected to each other, so they carry no
        // lanes; deeper replies inherit their parent's lanes plus their own.
        final lanes = depth == 0 ? const <bool>[] : [...parentLanes, hasNext];
        final parentName = child.parentPostId == null
            ? null
            : byId[child.parentPostId]?.authorName;
        result.add((
          post: child,
          depth: depth,
          parentName: parentName,
          lanes: lanes,
          hasChildren: byParent[child.id]?.isNotEmpty ?? false,
        ));
        walk(child.id, depth + 1, lanes);
      }
    }
    walk(null, 0, const <bool>[]);
    // Surface any reply whose parent isn't present (e.g. dangling parent)
    // as a top-level reply rather than dropping it.
    for (final p in _posts) {
      if (seen.add(p.id)) {
        result.add((
          post: p,
          depth: 0,
          parentName: null,
          lanes: const <bool>[],
          hasChildren: false,
        ));
      }
    }
    return result;
  }

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
                              style: AppText.section.copyWith(fontSize: 15),
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
                              ..._threadedPosts().map((e) => _ReplyTile(
                                    key: _keyFor(e.post.id),
                                    post: e.post,
                                    depth: e.depth,
                                    lanes: e.lanes,
                                    hasChildren: e.hasChildren,
                                    parentName: e.parentName,
                                    highlighted:
                                        _highlightedPostId == e.post.id,
                                    isMine: e.post.authorId == _uid,
                                    onReply: () => _startReply(e.post),
                                    onJumpToParent: e.post.parentPostId == null
                                        ? null
                                        : () => _jumpToParent(
                                            e.post.parentPostId!),
                                    onEdit: () => _editPost(e.post),
                                    onDelete: () => _deletePost(e.post),
                                  )),
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

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    super.key,
    required this.post,
    required this.depth,
    required this.lanes,
    required this.hasChildren,
    required this.parentName,
    required this.highlighted,
    required this.isMine,
    required this.onReply,
    required this.onJumpToParent,
    required this.onEdit,
    required this.onDelete,
  });

  final Post post;
  final int depth;

  /// Per-level connector state (see `_threadedPosts`). Drives the threading
  /// lines drawn to the left of nested replies.
  final List<bool> lanes;

  /// Whether this reply has its own replies — draws a descender under the
  /// avatar so the spine reaches the first child.
  final bool hasChildren;
  final String? parentName;

  /// Whether this reply is currently flashed (after a jump from a child's
  /// "Replying to …").
  final bool highlighted;
  final bool isMine;
  final VoidCallback onReply;

  /// Scrolls to and highlights the reply this one answers; null for top-level
  /// replies (which answer the main post and have nothing to jump to).
  final VoidCallback? onJumpToParent;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Vertical centre of the 34px avatar within `content` (top padding + radius).
  /// The connector's elbow hooks into the avatar at this height.
  static const double _hookY = 12 + 17;

  @override
  Widget build(BuildContext context) {
    // The connector line shows the parent→child link visually; we also always
    // name who's being answered so the relationship is unambiguous even after
    // the list scrolls.
    final showParentHeader = parentName != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: post.authorName, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showParentHeader) ...[
                  InkWell(
                    onTap: onJumpToParent,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        children: [
                          Icon(Icons.subdirectory_arrow_right_rounded,
                              size: 14, color: AppColors.indigo),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Replying to $parentName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label.copyWith(
                          fontSize: 13.5,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      relativeTime(post.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 11.5),
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
                SourceBodyText(post.body, style: AppText.body),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: onReply,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.reply_rounded,
                                size: 15, color: AppColors.muted),
                            const SizedBox(width: 5),
                            Text(
                              'Reply',
                              style: AppText.caption
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Flash a background when this reply is jumped to from a child's
    // "Replying to …".
    Widget highlight(Widget child) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: highlighted
                ? AppColors.indigo.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: highlighted
                  ? AppColors.indigo.withValues(alpha: 0.55)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: child,
        );

    // A top-level reply with no children needs no connector at all.
    if (depth == 0 && !hasChildren) return highlight(content);

    // Nested replies get an elbow connector: a vertical spine down each
    // ancestor lane and a curved hook into this reply's avatar, plus a descender
    // under the avatar when this reply has its own replies — so the parent→child
    // link is explicit at any depth. The painter spans the full row (behind the
    // avatar) so the descender can sit directly under it. A top-level reply that
    // has children draws only the descender (no incoming elbow).
    const step = _ThreadConnectorPainter.step;
    return highlight(IntrinsicHeight(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ThreadConnectorPainter(
                depth: depth,
                lanes: lanes,
                hasChildren: hasChildren,
                color: AppColors.line,
                hookY: _hookY,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: depth * step),
            child: content,
          ),
        ],
      ),
    ));
  }
}

/// Draws the threading lines for a nested reply across the full width of the
/// row, so a parent's spine can run beneath its avatar down to its first child.
///
/// Each indentation level L owns a vertical line at x = L·step + step/2 (just
/// under that level's avatar). For this reply at `depth` d:
///  - levels 0..d-2 draw a full-height line when that ancestor has a later
///    sibling (`lanes[L]`);
///  - level d-1 (the parent's line) draws from the top to the avatar and curves
///    in (the elbow), continuing below only when this reply has a next sibling;
///  - level d (under this reply's own avatar) draws a descender when this reply
///    has children.
class _ThreadConnectorPainter extends CustomPainter {
  const _ThreadConnectorPainter({
    required this.depth,
    required this.lanes,
    required this.hasChildren,
    required this.color,
    required this.hookY,
  });

  final int depth;
  final List<bool> lanes;
  final bool hasChildren;
  final Color color;
  final double hookY;

  /// Width of one indentation level. A clear step per level (close to an avatar
  /// width) so the elbows read as a tree, while staying compact enough to nest
  /// several levels deep on a phone.
  static const double step = 26;

  /// Radius of the rounded corner where the spine turns into the avatar.
  static const double _corner = 7;

  /// Avatar radius — the descender to a reply's children leaves from the bottom
  /// of the avatar (not its centre) so the line clearly originates *from* the
  /// parent rather than appearing to pass through it.
  static const double _avatarRadius = 17;

  double _laneX(int level) => level * step + step / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Pass-through ancestor lines (levels above the immediate parent).
    for (var level = 0; level < depth - 1; level++) {
      if (lanes[level]) {
        final x = _laneX(level);
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }

    // The elbow from the parent's line into this reply's avatar (nested only;
    // top-level replies have no incoming connector).
    if (depth >= 1) {
      final parentX = _laneX(depth - 1);
      final avatarLeft = depth * step;
      final elbow = Path()
        ..moveTo(parentX, 0)
        ..lineTo(parentX, hookY - _corner)
        ..quadraticBezierTo(parentX, hookY, parentX + _corner, hookY)
        ..lineTo(avatarLeft + 4, hookY);
      canvas.drawPath(elbow, paint);

      // Parent's line continues down to this reply's next sibling.
      if (lanes.isNotEmpty && lanes.last) {
        canvas.drawLine(
            Offset(parentX, hookY), Offset(parentX, size.height), paint);
      }
    }

    // Descender from the bottom of this reply's avatar down to its own first
    // child, so the line visibly grows out of the parent.
    if (hasChildren) {
      final x = _laneX(depth);
      canvas.drawLine(
          Offset(x, hookY + _avatarRadius), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_ThreadConnectorPainter old) =>
      old.depth != depth ||
      old.hasChildren != hasChildren ||
      old.color != color ||
      old.hookY != hookY ||
      !listEquals(old.lanes, lanes);
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

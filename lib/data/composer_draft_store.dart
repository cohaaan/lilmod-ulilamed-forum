/// Remembers in-progress reply drafts per thread so a user can leave a thread
/// (e.g. to browse Seforim) and come back to find their reply intact.
///
/// The bottom-tab shell already keeps the thread screen alive across tab
/// switches; this store is the belt-and-suspenders layer that also survives a
/// full pop/re-open of the thread.
class ComposerDraftStore {
  final Map<String, String> _drafts = {};

  String? get(String threadId) {
    final v = _drafts[threadId];
    return (v == null || v.isEmpty) ? null : v;
  }

  void set(String threadId, String text) {
    if (text.trim().isEmpty) {
      _drafts.remove(threadId);
    } else {
      _drafts[threadId] = text;
    }
  }

  void clear(String threadId) => _drafts.remove(threadId);
}

final composerDraftStore = ComposerDraftStore();

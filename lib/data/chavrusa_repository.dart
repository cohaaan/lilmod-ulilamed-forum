import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chavrusa_listing.dart';

/// Chavrusa partner listings. Auth required for all reads (RLS).
class ChavrusaRepository {
  final SupabaseClient _client = Supabase.instance.client;

  String? get _uid => _client.auth.currentUser?.id;

  /// Best-effort daily unique visit counter (see Supabase dashboard for totals).
  Future<void> recordPageVisit() async {
    try {
      await _client.rpc('record_chavrusa_page_visit');
    } catch (_) {
      // Never block the UI on analytics.
    }
  }

  Future<List<ChavrusaListing>> fetchAvailableListings() async {
    final rows = await _client
        .from('chavrusa_listings')
        .select()
        .eq('status', ChavrusaStatus.available.dbValue)
        .order('updated_at', ascending: false)
        .limit(100);
    return rows
        .map<ChavrusaListing>((m) => ChavrusaListing.fromMap(m))
        .toList();
  }

  Future<ChavrusaListing?> fetchMyListing() async {
    final uid = _uid;
    if (uid == null) return null;
    final row = await _client
        .from('chavrusa_listings')
        .select()
        .eq('user_id', uid)
        .maybeSingle();
    return row == null ? null : ChavrusaListing.fromMap(row);
  }

  Future<void> upsertListing(ChavrusaListing draft) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final payload = draft.toInsertMap(userId: uid);
    await _client.from('chavrusa_listings').upsert(payload, onConflict: 'user_id');
  }

  Future<void> updateStatus(ChavrusaStatus status) async {
    final uid = _uid;
    if (uid == null) return;
    await _client
        .from('chavrusa_listings')
        .update({'status': status.dbValue}).eq('user_id', uid);
  }

  Future<void> deleteMyListing() async {
    final uid = _uid;
    if (uid == null) return;
    await _client.from('chavrusa_listings').delete().eq('user_id', uid);
  }
}

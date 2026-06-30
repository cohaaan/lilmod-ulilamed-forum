import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'chavrusa_invite_store.dart';
import 'repositories.dart';

export 'chavrusa_invite_store.dart' show ChavrusaInviteStore;

/// Cached Chavrusas membership check for router redirects.
///
/// The router redirect MUST stay synchronous: an async redirect that awaits
/// Supabase RPCs and then notifies its own `refreshListenable` (this class is
/// in it) re-triggers itself forever and the page never settles — that was the
/// Chavrusas "freezing" bug. So all DB work happens here, off the redirect
/// path, via [ensureResolved] (fire-and-forget). The redirect only reads the
/// cached, synchronous [gateResolved] / [showInviteGate] flags; we notify once
/// when resolution finishes so the redirect re-runs with fresh state.
class ChavrusaAccess extends ChangeNotifier {
  ChavrusaAccess._();
  static final instance = ChavrusaAccess._();

  static bool? _isMember;
  static bool? _requiresInvite;
  static bool _gateResolved = false;
  static bool _showInviteGate = false;
  static Future<void>? _resolveFuture;

  static bool get gateResolved => _gateResolved;
  static bool get showInviteGate => _showInviteGate;

  static void invalidate() {
    _isMember = null;
    _requiresInvite = null;
    _gateResolved = false;
    _showInviteGate = false;
    _resolveFuture = null;
    instance.notifyListeners();
  }

  static void markMember() {
    _isMember = true;
    _showInviteGate = false;
    _gateResolved = true;
    _resolveFuture = null;
    instance.notifyListeners();
  }

  /// Fire-and-forget resolution for the synchronous router redirect. Safe to
  /// call on every redirect run: the actual work runs at most once per
  /// [invalidate] cycle, and listeners are notified once it completes.
  static void ensureResolved() {
    resolveLoginGate();
  }

  /// Awaitable variant for explicit callers (e.g. the login screen). Shares the
  /// single in-flight resolution so concurrent callers don't double-run RPCs.
  static Future<void> resolveLoginGate() {
    if (_gateResolved) return Future<void>.value();
    return _resolveFuture ??= _runResolve();
  }

  static Future<void> _runResolve() async {
    try {
      await _resolve();
    } finally {
      _resolveFuture = null;
      // Notify exactly once per resolution so the (synchronous) redirect
      // re-evaluates with the freshly cached gate state.
      instance.notifyListeners();
    }
  }

  static Future<void> _resolve() async {
    if (_gateResolved) return;
    try {
      if (!AppConfig.isChavrusasSite || !authRepository.isSignedIn) {
        _showInviteGate = false;
        _gateResolved = true;
        return;
      }

      await redeemPendingInviteIfAny();

      if (!await requiresInvite()) {
        _showInviteGate = false;
        _gateResolved = true;
        return;
      }

      final member = await isMember();
      _showInviteGate = !member;
      _gateResolved = true;
    } catch (_) {
      // A DB/RPC failure must not hang routing. Mark resolved but deny access
      // (land on the invite gate); a later sign-in/out invalidates and retries.
      _showInviteGate = true;
      _gateResolved = true;
    }
  }

  static Future<bool> requiresInvite() async {
    if (!AppConfig.isChavrusasSite) return false;
    _requiresInvite ??= await chavrusaRepository.requiresInvite();
    return _requiresInvite!;
  }

  static Future<bool> isMember() async {
    if (!AppConfig.isChavrusasSite || !authRepository.isSignedIn) return true;
    _isMember ??= await chavrusaRepository.isMember();
    return _isMember!;
  }

  static Future<bool> hasAccess() async {
    if (!AppConfig.isChavrusasSite) return true;
    if (!authRepository.isSignedIn) return false;
    try {
      if (!await requiresInvite()) return true;
      return isMember();
    } catch (_) {
      return false;
    }
  }

  static Future<void> redeemPendingInviteIfAny() async {
    if (!AppConfig.isChavrusasSite || !authRepository.isSignedIn) return;
    final code = await ChavrusaInviteStore.takePendingCode();
    if (code == null) return;
    try {
      await chavrusaRepository.redeemInvite(code);
      markMember();
    } catch (_) {
      await ChavrusaInviteStore.savePendingCode(code);
    }
  }
}

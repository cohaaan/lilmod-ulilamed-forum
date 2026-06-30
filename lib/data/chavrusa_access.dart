import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import 'chavrusa_invite_store.dart';
import 'repositories.dart';

export 'chavrusa_invite_store.dart' show ChavrusaInviteStore;

/// Cached Chavrusas membership check for router redirects.
class ChavrusaAccess extends ChangeNotifier {
  ChavrusaAccess._();
  static final instance = ChavrusaAccess._();

  static bool? _isMember;
  static bool? _requiresInvite;
  static bool _gateResolved = false;
  static bool _showInviteGate = false;

  static bool get gateResolved => _gateResolved;
  static bool get showInviteGate => _showInviteGate;

  static void invalidate() {
    _isMember = null;
    _requiresInvite = null;
    _gateResolved = false;
    _showInviteGate = false;
    instance.notifyListeners();
  }

  static void markMember() {
    _isMember = true;
    _showInviteGate = false;
    _gateResolved = true;
    instance.notifyListeners();
  }

  static Future<void> resolveLoginGate() async {
    // Already resolved — do NOT notify again. resolveLoginGate() runs inside the
    // router redirect, and ChavrusaAccess.instance is in refreshListenable, so an
    // unconditional notifyListeners() here triggers a redirect→notify→redirect
    // infinite loop. invalidate() (on sign-in/out) is what re-opens the gate.
    if (_gateResolved) return;

    try {
      if (!AppConfig.isChavrusasSite) {
        _gateResolved = true;
        _showInviteGate = false;
        instance.notifyListeners();
        return;
      }

      if (!authRepository.isSignedIn) {
        _gateResolved = true;
        _showInviteGate = false;
        instance.notifyListeners();
        return;
      }

      await redeemPendingInviteIfAny();

      if (!await requiresInvite()) {
        _gateResolved = true;
        _showInviteGate = false;
        instance.notifyListeners();
        return;
      }

      final member = await isMember();
      _gateResolved = true;
      _showInviteGate = !member;
      instance.notifyListeners();
    } catch (_) {
      _gateResolved = true;
      _showInviteGate = false;
      instance.notifyListeners();
      rethrow;
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

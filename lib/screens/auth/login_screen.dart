import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../data/chavrusa_access.dart';
import '../../data/repositories.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chavrusa/brutalist_button.dart';
import '../../widgets/google_logo.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invite = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _isSignUp = AppConfig.isChavrusasSite;
  bool _busy = false;
  bool _inviteUnlocked = false;
  String? _error;
  String? _info;

  bool get _isChavrusas => AppConfig.isChavrusasSite;

  /// Signed in via Google/email but not yet a Chavrusas member.
  bool get _showInviteGate =>
      _isChavrusas &&
      authRepository.isSignedIn &&
      ChavrusaAccess.gateResolved &&
      ChavrusaAccess.showInviteGate;

  /// New visitor — validate invite before showing Google or signup.
  bool get _showInviteFirst =>
      _isChavrusas &&
      !authRepository.isSignedIn &&
      _isSignUp &&
      !_inviteUnlocked;

  static bool _isValidInviteCode(String code) =>
      RegExp(r'^\d{4,6}$').hasMatch(code.trim());

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _email.text = 'philo@demo.lilmod.app';
      _password.text = 'Lilmod2026!';
    }
    // Gate resolution runs in the background (off the router redirect). Rebuild
    // when it settles so the "resolving" spinner can never get stuck.
    ChavrusaAccess.instance.addListener(_onAccessChanged);
    _restoreInviteUnlock();
  }

  void _onAccessChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _restoreInviteUnlock() async {
    final pending = await ChavrusaInviteStore.peekPendingCode();
    if (pending != null && mounted) {
      setState(() => _inviteUnlocked = true);
    }
  }

  @override
  void dispose() {
    ChavrusaAccess.instance.removeListener(_onAccessChanged);
    _invite.dispose();
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await action();
      if (_isChavrusas) {
        await _finishChavrusasAccess();
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishChavrusasAccess() async {
    final pending = await ChavrusaInviteStore.peekPendingCode();
    if (pending != null) {
      await chavrusaRepository.redeemInvite(pending);
      await ChavrusaInviteStore.clearPendingCode();
      ChavrusaAccess.markMember();
    } else if (_isValidInviteCode(_invite.text)) {
      await chavrusaRepository.redeemInvite(_invite.text.trim());
      ChavrusaAccess.markMember();
    }

    if (!await ChavrusaAccess.hasAccess()) {
      await ChavrusaAccess.resolveLoginGate();
      throw Exception('Enter a valid invite code to join Chavrusas');
    }
  }

  Future<bool> _validateInviteForSignup() async {
    if (!_isChavrusas) return true;
    if (!await ChavrusaAccess.requiresInvite()) return true;

    final code = _invite.text.trim();
    if (!_isValidInviteCode(code)) {
      setState(() => _error = 'Enter your invite code');
      return false;
    }

    final message = await chavrusaRepository.validateInvite(code);
    if (message != null) {
      setState(() => _error = message);
      return false;
    }

    await ChavrusaInviteStore.savePendingCode(code);
    return true;
  }

  Future<void> _unlockInviteForSignup() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _validateInviteForSignup()) return;
      if (mounted) setState(() => _inviteUnlocked = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitEmail() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_isSignUp && _isChavrusas && !_inviteUnlocked) {
      if (!await _validateInviteForSignup()) return;
    }

    await _runAuth(() async {
      if (_isSignUp) {
        final res = await authRepository.signUpWithEmail(
          email: _email.text,
          password: _password.text,
          displayName: _name.text.trim(),
        );
        if (res.session == null && mounted) {
          setState(() => _info =
              'Check your email to confirm your account, then sign in.');
        }
      } else {
        await authRepository.signInWithEmail(
          email: _email.text,
          password: _password.text,
        );
      }
    });
  }

  Future<void> _google() async {
    if (_isChavrusas && _isSignUp && !_inviteUnlocked) {
      setState(() => _error = 'Enter your invite code first');
      return;
    }
    if (_isSignUp && _isChavrusas) {
      await ChavrusaInviteStore.savePendingCode(_invite.text.trim());
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await authRepository.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _redeemInviteOnly() async {
    final code = _invite.text.trim();
    if (!_isValidInviteCode(code)) {
      setState(() => _error = 'Enter your invite code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await chavrusaRepository.redeemInvite(code);
      ChavrusaAccess.markMember();
      if (!mounted) return;
      context.go(AppConfig.defaultSignedInRoute);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _busyIndicator({Color color = Colors.white}) {
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }

  Widget _primaryAuthButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    if (AppColors.useBrutalistChrome) {
      return BrutalistButton(
        label: _busy ? '' : label,
        expandWidth: true,
        onPressed: _busy ? null : onPressed,
        icon: _busy ? _busyIndicator() : null,
      );
    }

    return ElevatedButton(
      onPressed: _busy ? null : onPressed,
      child: _busy ? _busyIndicator() : Text(label),
    );
  }

  Widget _googleAuthButton() {
    if (AppColors.useBrutalistChrome) {
      return BrutalistButton(
        label: 'Continue with Google',
        style: BrutalistButtonStyle.secondary,
        expandWidth: true,
        onPressed: _busy ? null : _google,
        icon: const GoogleLogo(size: 20),
      );
    }

    return OutlinedButton.icon(
      onPressed: _busy ? null : _google,
      icon: const GoogleLogo(size: 20),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        side: BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.cardRadius),
        ),
        textStyle: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChavrusas &&
        authRepository.isSignedIn &&
        !ChavrusaAccess.gateResolved) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    _isChavrusas ? 'Chavrusas' : 'Lilmod Ulilamed',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _showInviteGate
                        ? 'You need an invite code to access Chavrusas'
                        : _showInviteFirst
                            ? 'Enter the invite code you received'
                            : _isChavrusas
                                ? 'Find a learning partner — invite only for now'
                                : 'Serious, respectful Torah discourse',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 36),

                  if (_showInviteGate) ...[
                    _InviteCodeField(controller: _invite, enabled: !_busy),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _Banner(text: _error!, color: AppColors.like),
                    ],
                    const SizedBox(height: 20),
                    _primaryAuthButton(
                      label: 'Continue with invite code',
                      onPressed: _redeemInviteOnly,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () async {
                              ChavrusaAccess.invalidate();
                              await ChavrusaInviteStore.clearPendingCode();
                              await authRepository.signOut();
                            },
                      child: const Text('Sign out'),
                    ),
                  ] else if (_showInviteFirst) ...[
                    _InviteCodeField(controller: _invite, enabled: !_busy),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _Banner(text: _error!, color: AppColors.like),
                    ],
                    const SizedBox(height: 20),
                    _primaryAuthButton(
                      label: 'Continue',
                      onPressed: _unlockInviteForSignup,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _isSignUp = false;
                                _error = null;
                              }),
                      child: const Text('Already have an account? Sign in'),
                    ),
                  ] else ...[
                    _googleAuthButton(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.line)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: GoogleFonts.inter(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.line)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _name,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                hintText: 'Display name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Enter a display name'
                                      : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: const InputDecoration(
                              hintText: 'Email',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                            validator: (v) =>
                                (v == null || !v.contains('@'))
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'At least 6 characters'
                                : null,
                            onFieldSubmitted: (_) => _submitEmail(),
                          ),
                        ],
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _Banner(text: _error!, color: AppColors.like),
                    ],
                    if (_info != null) ...[
                      const SizedBox(height: 14),
                      _Banner(text: _info!, color: AppColors.mint),
                    ],
                    const SizedBox(height: 20),
                    _primaryAuthButton(
                      label: _isSignUp ? 'Create account' : 'Sign in',
                      onPressed: _submitEmail,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                                _isSignUp = !_isSignUp;
                                _error = null;
                                _info = null;
                                if (_isSignUp && _isChavrusas) {
                                  _inviteUnlocked = false;
                                }
                              }),
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign in'
                            : _isChavrusas
                                ? 'New here? Enter invite code'
                                : 'New here? Create an account',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteCodeField extends StatelessWidget {
  const _InviteCodeField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: 6,
      obscureText: true,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 8,
      ),
      decoration: const InputDecoration(
        labelText: 'Invite code',
        counterText: '',
        prefixIcon: Icon(Icons.vpn_key_outlined),
      ),
      validator: (v) {
        if (v == null || !RegExp(r'^\d{4,6}$').hasMatch(v)) {
          return 'Enter your invite code';
        }
        return null;
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          height: 1.4,
          color: color == AppColors.mint ? AppColors.ink : color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

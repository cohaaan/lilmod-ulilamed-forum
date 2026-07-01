import 'package:flutter/material.dart';

import '../data/repositories.dart';
import '../models/profile.dart';
import '../theme/app_colors.dart';
import '../widgets/avatar.dart';
import '../theme/app_text.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _displayName.addListener(_onNameChanged);
    _load();
  }

  Future<void> _load() async {
    final Profile? profile = await forumRepository.fetchMyProfile();
    if (!mounted) return;
    setState(() {
      _displayName.text = profile?.displayName ?? '';
      _loading = false;
    });
  }

  void _onNameChanged() => setState(() {});

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await forumRepository.updateMyProfile(
        displayName: _displayName.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _displayName.removeListener(_onNameChanged);
    _displayName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit profile',
          style: AppText.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  Center(
                    child: Avatar(name: _displayName.text, size: 72),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _displayName,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      hintText: 'Display name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().length < 2)
                        ? 'Enter a display name'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppText.inter(
                        color: AppColors.like,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

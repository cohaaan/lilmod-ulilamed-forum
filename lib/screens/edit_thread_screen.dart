import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/repositories.dart';
import '../theme/app_colors.dart';

class EditThreadScreen extends StatefulWidget {
  const EditThreadScreen({
    super.key,
    required this.threadId,
    required this.initialTitle,
    required this.initialBody,
    required this.initialType,
  });

  final String threadId;
  final String initialTitle;
  final String initialBody;
  final String initialType;

  @override
  State<EditThreadScreen> createState() => _EditThreadScreenState();
}

class _EditThreadScreenState extends State<EditThreadScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initialTitle);
  late final _body = TextEditingController(text: widget.initialBody);
  late String _type = widget.initialType;
  bool _busy = false;
  String? _error;

  static const _types = ['Discussion', 'Question', 'Note'];

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await forumRepository.updateThread(
        widget.threadId,
        title: _title.text,
        body: _body.text,
        type: _type,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit thread',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _busy ? null : _submit,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Wrap(
              spacing: 8,
              children: _types.map((t) {
                final selected = t == _type;
                return ChoiceChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (_) => setState(() => _type = t),
                  showCheckmark: false,
                  selectedColor: AppColors.indigo.withValues(alpha: 0.12),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.indigo : AppColors.body,
                  ),
                  side: BorderSide(
                    color: selected ? AppColors.indigo : AppColors.line,
                  ),
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Title'),
              maxLength: 200,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Give your thread a title'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _body,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Share your question, source, or chiddush…',
                alignLabelWithHint: true,
              ),
              minLines: 6,
              maxLines: 16,
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Add some detail'
                  : null,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(color: AppColors.like, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/repositories.dart';
import '../../models/chavrusa_listing.dart';
import '../../theme/chavrusa_directory_theme.dart';
import 'brutalist_button.dart';

/// Post / edit chavrusa availability — used in modal (web) or full-screen route.
class ChavrusaPostForm extends StatefulWidget {
  const ChavrusaPostForm({
    super.key,
    this.existing,
    this.onSaved,
    this.onCancel,
    this.embedded = false,
  });

  final ChavrusaListing? existing;
  final VoidCallback? onSaved;
  final VoidCallback? onCancel;
  final bool embedded;

  @override
  State<ChavrusaPostForm> createState() => ChavrusaPostFormState();
}

class ChavrusaPostFormState extends State<ChavrusaPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _sefer = TextEditingController();
  final _details = TextEditingController();
  final _availabilityNote = TextEditingController();
  final _phone = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  bool _consent = false;

  bool _okWhatsapp = true;
  bool _okText = true;
  bool _okCall = false;
  ChavrusaContactMethod _preferred = ChavrusaContactMethod.whatsapp;
  ChavrusaStatus _status = ChavrusaStatus.available;
  String? _subject;
  String? _sessionLength;
  List<ChavrusaAvailabilitySlot> _slots = [const ChavrusaAvailabilitySlot()];

  ChavrusaListing? get existing => widget.existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await forumRepository.fetchMyProfile();
    final listing = widget.existing ?? await chavrusaRepository.fetchMyListing();
    if (!mounted) return;

    _name.text = listing?.displayName ?? profile?.displayName ?? '';
    if (listing != null) {
      _age.text = '${listing.age}';
      _subject = chavrusaSubjects.contains(listing.learningInterests)
          ? listing.learningInterests
          : listing.learningInterests.isNotEmpty
              ? listing.learningInterests
              : null;
      _sessionLength = chavrusaSessionLengths.contains(listing.sessionLength)
          ? listing.sessionLength
          : null;
      _sefer.text = listing.topic;
      _details.text = listing.learningDetails;
      final parsed = parseChavrusaAvailability(listing.availability);
      _slots = parsed.slots;
      if (parsed.note != null) _availabilityNote.text = parsed.note!;
      _phone.text = listing.phone;
      _okWhatsapp = listing.okWhatsapp;
      _okText = listing.okText;
      _okCall = listing.okCall;
      _preferred = listing.preferredContact;
      _status = listing.status;
      _consent = true;
    }

    setState(() => _loading = false);
  }

  List<ChavrusaContactMethod> get _allowedContacts => [
        if (_okWhatsapp) ChavrusaContactMethod.whatsapp,
        if (_okText) ChavrusaContactMethod.text,
        if (_okCall) ChavrusaContactMethod.call,
      ];

  void _syncPreferredContact() {
    final allowed = _allowedContacts;
    if (allowed.isEmpty) return;
    if (!allowed.contains(_preferred)) _preferred = allowed.first;
  }

  Future<void> save() => _save();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      setState(() => _error = 'Please confirm the contact consent.');
      return;
    }
    if (_allowedContacts.isEmpty) {
      setState(() => _error = 'Choose at least one way to contact you.');
      return;
    }
    _syncPreferredContact();
    if (_slots.every((s) => !s.isComplete)) {
      setState(() => _error = 'Add at least one day and time slot.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final draft = ChavrusaListing(
      id: existing?.id ?? '',
      userId: existing?.userId ?? '',
      displayName: _name.text.trim(),
      age: int.parse(_age.text.trim()),
      learningInterests: _subject!,
      sessionLength: _sessionLength!,
      topic: _sefer.text.trim(),
      learningDetails: _details.text.trim(),
      availability: encodeChavrusaAvailability(
        slots: _slots,
        note: _availabilityNote.text,
      ),
      phone: _phone.text.trim(),
      okWhatsapp: _okWhatsapp,
      okText: _okText,
      okCall: _okCall,
      preferredContact: _preferred,
      status: _status,
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await chavrusaRepository.upsertListing(draft);
      if (mounted) widget.onSaved?.call();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _removeListing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove listing?'),
        content: const Text(
          'This deletes your availability post. You can create a new one anytime.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await chavrusaRepository.deleteMyListing();
      if (mounted) widget.onSaved?.call();
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not remove listing.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _sefer.dispose();
    _details.dispose();
    _availabilityNote.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 620;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = wide ? 2 : 1;
              return Wrap(
                spacing: 18,
                runSpacing: 18,
                children: [
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _nameField()),
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _ageField()),
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _subjectField()),
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _seferField()),
                  _field(
                    width: constraints.maxWidth,
                    child: _detailsField(),
                  ),
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _sessionField()),
                  _field(width: constraints.maxWidth, child: _slotsSection()),
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _phoneField()),
                  _field(width: _colWidth(constraints.maxWidth, cols), child: _contactChecks()),
                  if (_allowedContacts.isNotEmpty)
                    _field(width: _colWidth(constraints.maxWidth, cols), child: _preferredField()),
                  _field(width: constraints.maxWidth, child: _statusSection()),
                  _field(width: constraints.maxWidth, child: _consentRow()),
                ],
              );
            },
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.only(top: 18),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: ChavrusaDirectoryTheme.soft)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (existing != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: BrutalistButton(
                      label: 'Remove',
                      style: BrutalistButtonStyle.secondary,
                      onPressed: _busy ? null : _removeListing,
                    ),
                  ),
                BrutalistButton(
                  label: 'Cancel',
                  style: BrutalistButtonStyle.secondary,
                  onPressed: _busy ? null : widget.onCancel,
                ),
                const SizedBox(width: 10),
                BrutalistButton(
                  label: _busy ? 'Saving…' : 'Publish availability',
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _colWidth(double max, int cols) =>
      cols == 1 ? max : (max - 18) / 2;

  Widget _field({required double width, required Widget child}) =>
      SizedBox(width: width, child: child);

  Widget _nameField() => TextFormField(
        controller: _name,
        decoration: ChavrusaDirectoryTheme.fieldDecoration('Name', hint: 'e.g. Yaakov Friedman'),
        validator: (v) => (v == null || v.trim().length < 2) ? 'Enter your name' : null,
      );

  Widget _ageField() => TextFormField(
        controller: _age,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: ChavrusaDirectoryTheme.fieldDecoration('Age', hint: '34'),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'Enter your age';
          final n = int.tryParse(v.trim());
          if (n == null || n < 13 || n > 120) return 'Enter a valid age (13–120)';
          return null;
        },
      );

  Widget _subjectField() => DropdownButtonFormField<String>(
        value: _subject != null && chavrusaSubjects.contains(_subject) ? _subject : null,
        decoration: ChavrusaDirectoryTheme.fieldDecoration('Subject / category'),
        hint: const Text('Gemara, Halacha, Hashkafa…'),
        items: [
          for (final s in chavrusaSubjects)
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (v) => setState(() => _subject = v),
        validator: (v) => v == null ? 'Choose a subject' : null,
      );

  Widget _seferField() => TextFormField(
        controller: _sefer,
        decoration: ChavrusaDirectoryTheme.fieldDecoration(
          'Sefer or sugya',
          hint: 'Maseches Berachos',
        ),
        validator: (v) => (v == null || v.trim().length < 2) ? 'Enter a sefer or sugya' : null,
      );

  Widget _detailsField() => TextFormField(
        controller: _details,
        minLines: 3,
        maxLines: 5,
        decoration: ChavrusaDirectoryTheme.fieldDecoration(
          'What would you like to learn?',
          hint: 'Pace, level, goal, or specific area you want to cover.',
        ),
      );

  Widget _sessionField() => DropdownButtonFormField<String>(
        value: _sessionLength,
        decoration: ChavrusaDirectoryTheme.fieldDecoration('Preferred learning length'),
        items: [
          for (final length in chavrusaSessionLengths)
            DropdownMenuItem(value: length, child: Text(length)),
        ],
        onChanged: (v) => setState(() => _sessionLength = v),
        validator: (v) => v == null ? 'Choose session length' : null,
      );

  Widget _phoneField() => TextFormField(
        controller: _phone,
        keyboardType: TextInputType.phone,
        decoration: ChavrusaDirectoryTheme.fieldDecoration(
          'Phone number',
          hint: 'Visible to signed-in members',
        ),
        validator: (v) => (v == null || v.trim().length < 7) ? 'Enter a phone number' : null,
      );

  Widget _preferredField() => DropdownButtonFormField<ChavrusaContactMethod>(
        value: _preferred,
        decoration: ChavrusaDirectoryTheme.fieldDecoration('Preferred contact'),
        items: [
          for (final method in _allowedContacts)
            DropdownMenuItem(value: method, child: Text(method.label)),
        ],
        onChanged: (v) => setState(() => _preferred = v!),
      );

  Widget _contactChecks() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OK to contact via', style: ChavrusaDirectoryTheme.fieldLabel.copyWith(color: ChavrusaDirectoryTheme.muted)),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('WhatsApp'),
            value: _okWhatsapp,
            onChanged: (v) => setState(() {
              _okWhatsapp = v ?? false;
              _syncPreferredContact();
            }),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Text message'),
            value: _okText,
            onChanged: (v) => setState(() {
              _okText = v ?? false;
              _syncPreferredContact();
            }),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Phone call'),
            value: _okCall,
            onChanged: (v) => setState(() {
              _okCall = v ?? false;
              _syncPreferredContact();
            }),
          ),
        ],
      );

  Widget _statusSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing status', style: ChavrusaDirectoryTheme.fieldLabel),
          ...ChavrusaStatus.values.map(
            (status) => RadioListTile<ChavrusaStatus>(
              contentPadding: EdgeInsets.zero,
              title: Text(status.label),
              subtitle: switch (status) {
                ChavrusaStatus.available => const Text('Visible to others looking for a chavrusa'),
                ChavrusaStatus.matched => const Text('Hide — you found a chavrusa'),
                ChavrusaStatus.paused => const Text('Hide temporarily'),
              },
              value: status,
              groupValue: _status,
              onChanged: (v) => setState(() => _status = v!),
            ),
          ),
        ],
      );

  Widget _consentRow() => CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _consent,
        onChanged: (v) => setState(() => _consent = v ?? false),
        title: const Text(
          'I am okay with registered users contacting me through the method selected above. '
          'I can edit, pause, or remove this listing after I find a chavrusa.',
          style: TextStyle(fontSize: 12, color: ChavrusaDirectoryTheme.muted, height: 1.45),
        ),
      );

  Widget _slotsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When are you available?', style: ChavrusaDirectoryTheme.fieldLabel),
          const SizedBox(height: 4),
          const Text(
            'Add day + time slots. Different days can have different times.',
            style: TextStyle(fontSize: 12, color: ChavrusaDirectoryTheme.muted),
          ),
          const SizedBox(height: 12),
          ...List.generate(_slots.length, (index) {
            final slot = _slots[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: chavrusaDays.contains(slot.day) ? slot.day : null,
                      decoration: ChavrusaDirectoryTheme.fieldDecoration('Day'),
                      items: [
                        for (final day in chavrusaDays)
                          DropdownMenuItem(value: day, child: Text(day)),
                      ],
                      onChanged: (v) => setState(() => _slots[index] = slot.copyWith(day: v)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: chavrusaTimeSlots.contains(slot.time) ? slot.time : null,
                      decoration: ChavrusaDirectoryTheme.fieldDecoration('Time'),
                      items: [
                        for (final time in chavrusaTimeSlots)
                          DropdownMenuItem(value: time, child: Text(time)),
                      ],
                      onChanged: (v) => setState(() => _slots[index] = slot.copyWith(time: v)),
                    ),
                  ),
                  if (_slots.length > 1)
                    IconButton(
                      onPressed: () => setState(() => _slots.removeAt(index)),
                      icon: const Icon(Icons.close_rounded),
                    ),
                ],
              ),
            );
          }),
          TextButton.icon(
            onPressed: () => setState(() => _slots.add(const ChavrusaAvailabilitySlot())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add another time slot'),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _availabilityNote,
            minLines: 2,
            maxLines: 3,
            decoration: ChavrusaDirectoryTheme.fieldDecoration(
              'Schedule notes (optional)',
              hint: 'e.g. only during lunch break',
            ),
          ),
        ],
      );
}

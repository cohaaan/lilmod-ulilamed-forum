import 'dart:convert';

/// Top-level subject categories (stored in `learning_interests`).
const chavrusaSubjects = [
  'Gemara',
  'Gemara B\'Iyun',
  'Daf Yomi',
  'Halacha',
  'Shulchan Aruch',
  'Musar',
  'Chasidus',
  'Hashkafa',
  'Tanach',
  'Parsha',
  'Mishnah',
  'Mishnayos',
  'Rambam',
];

/// Sidebar day filters (abbrev → full names matched in availability slots).
const chavrusaDayFilterOptions = {
  'Mon': ['Monday', 'Weekdays'],
  'Tue': ['Tuesday', 'Weekdays'],
  'Wed': ['Wednesday', 'Weekdays'],
  'Thu': ['Thursday', 'Weekdays'],
  'Fri': ['Friday', 'Weekdays'],
  'Sun': ['Sunday', 'Weekends'],
  'מוצ"ש': ['מוצאי שבת'],
};

const chavrusaSessionLengths = [
  '5 min',
  '10 min',
  '15 min',
  '20 min',
  '30 min',
  '45 min',
  '1 hour',
  '1.5 hours',
  '2 hours',
];

const chavrusaDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Sunday',
  'Weekdays',
  'Weekends',
  'מוצאי שבת',
];

/// Hourly slots starting at 7 AM, covering a full 24-hour cycle.
final chavrusaTimeSlots = List<String>.generate(24, (i) {
  final start = (7 + i) % 24;
  final end = (start + 1) % 24;
  return '${_chavrusaHourLabel(start)} – ${_chavrusaHourLabel(end)}';
});

String _chavrusaHourLabel(int hour24) {
  if (hour24 == 0) return '12 AM';
  if (hour24 == 12) return '12 PM';
  if (hour24 < 12) return '$hour24 AM';
  return '${hour24 - 12} PM';
}

class ChavrusaAvailabilitySlot {
  const ChavrusaAvailabilitySlot({this.day, this.time});

  final String? day;
  final String? time;

  bool get isComplete =>
      day != null &&
      time != null &&
      chavrusaDays.contains(day) &&
      chavrusaTimeSlots.contains(time);

  ChavrusaAvailabilitySlot copyWith({String? day, String? time}) =>
      ChavrusaAvailabilitySlot(day: day ?? this.day, time: time ?? this.time);

  Map<String, String> toJson() => {'day': day!, 'time': time!};

  factory ChavrusaAvailabilitySlot.fromJson(Map<String, dynamic> json) =>
      ChavrusaAvailabilitySlot(
        day: json['day'] as String?,
        time: json['time'] as String?,
      );
}

/// Parses stored availability — JSON slots, optionally followed by a free-text note.
({List<ChavrusaAvailabilitySlot> slots, String? note}) parseChavrusaAvailability(
  String raw,
) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (slots: [const ChavrusaAvailabilitySlot()], note: null);
  }

  final lines = trimmed.split('\n');
  final first = lines.first.trim();
  if (first.startsWith('[')) {
    try {
      final decoded = jsonDecode(first) as List<dynamic>;
      final slots = decoded
          .map((e) =>
              ChavrusaAvailabilitySlot.fromJson(e as Map<String, dynamic>))
          .where((s) => s.isComplete)
          .toList();
      final note = lines.length > 1 ? lines.sublist(1).join('\n').trim() : null;
      return (
        slots: slots.isEmpty ? [const ChavrusaAvailabilitySlot()] : slots,
        note: (note?.isEmpty ?? true) ? null : note,
      );
    } catch (_) {
      // Fall through to legacy text.
    }
  }

  return (slots: [const ChavrusaAvailabilitySlot()], note: trimmed);
}

String encodeChavrusaAvailability({
  required List<ChavrusaAvailabilitySlot> slots,
  String? note,
}) {
  final complete = slots.where((s) => s.isComplete).toList();
  final buffer = StringBuffer(jsonEncode(complete.map((s) => s.toJson()).toList()));
  final trimmedNote = note?.trim();
  if (trimmedNote != null && trimmedNote.isNotEmpty) {
    buffer.write('\n$trimmedNote');
  }
  return buffer.toString();
}

String formatChavrusaAvailability(String raw) {
  final parsed = parseChavrusaAvailability(raw);
  final parts = <String>[
    for (final slot in parsed.slots.where((s) => s.isComplete))
      '${slot.day}, ${slot.time}',
  ];
  if (parsed.note != null) parts.add(parsed.note!);
  if (parts.isEmpty) return raw.trim();
  return parts.join('; ');
}

/// Third meta line on directory cards — learning goal / style / level.
String chavrusaCardNotes(ChavrusaListing listing) {
  if (listing.learningDetails.trim().isNotEmpty) {
    return listing.learningDetails.trim();
  }
  final note = parseChavrusaAvailability(listing.availability).note;
  if (note != null && note.trim().isNotEmpty) return note.trim();
  return 'Open to discussing pace and learning style.';
}

bool chavrusaListingMatchesDayFilters(
  ChavrusaListing listing,
  Set<String> selectedAbbrevs,
) {
  if (selectedAbbrevs.isEmpty) return true;
  final slots = parseChavrusaAvailability(listing.availability).slots;
  for (final slot in slots) {
    final day = slot.day;
    if (day == null) continue;
    for (final abbrev in selectedAbbrevs) {
      final names = chavrusaDayFilterOptions[abbrev];
      if (names != null && names.contains(day)) return true;
    }
  }
  return false;
}

int chavrusaEarliestSlotHour(String availability) {
  final slots = parseChavrusaAvailability(availability).slots;
  var earliest = 999;
  for (final slot in slots) {
    final time = slot.time;
    if (time == null) continue;
    final start = time.split('–').first.trim();
    final hour = _parseChavrusaHourStart(start);
    if (hour != null && hour < earliest) earliest = hour;
  }
  return earliest == 999 ? 999 : earliest;
}

int? _parseChavrusaHourStart(String label) {
  final match = RegExp(r'^(\d{1,2})\s*(AM|PM)?').firstMatch(label);
  if (match == null) return null;
  var hour = int.parse(match.group(1)!);
  final suffix = match.group(2);
  if (suffix == 'PM' && hour != 12) hour += 12;
  if (suffix == 'AM' && hour == 12) hour = 0;
  return hour;
}

enum ChavrusaContactMethod { whatsapp, text, call }

enum ChavrusaStatus { available, matched, paused }

extension ChavrusaContactMethodX on ChavrusaContactMethod {
  String get label => switch (this) {
        ChavrusaContactMethod.whatsapp => 'WhatsApp',
        ChavrusaContactMethod.text => 'Text',
        ChavrusaContactMethod.call => 'Call',
      };

  String get dbValue => name;
}

extension ChavrusaStatusX on ChavrusaStatus {
  String get label => switch (this) {
        ChavrusaStatus.available => 'Available',
        ChavrusaStatus.matched => 'Found a chavrusa',
        ChavrusaStatus.paused => 'Paused',
      };

  String get dbValue => name;
}

ChavrusaContactMethod contactMethodFromDb(String value) =>
    ChavrusaContactMethod.values.firstWhere((m) => m.dbValue == value);

ChavrusaStatus chavrusaStatusFromDb(String value) =>
    ChavrusaStatus.values.firstWhere((s) => s.dbValue == value);

class ChavrusaListing {
  const ChavrusaListing({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.age,
    required this.learningInterests,
    required this.sessionLength,
    required this.topic,
    required this.learningDetails,
    required this.availability,
    required this.phone,
    required this.okWhatsapp,
    required this.okText,
    required this.okCall,
    required this.preferredContact,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final int age;
  final String learningInterests;
  final String sessionLength;
  final String topic;
  final String learningDetails;
  final String availability;
  final String phone;
  final bool okWhatsapp;
  final bool okText;
  final bool okCall;
  final ChavrusaContactMethod preferredContact;
  final ChavrusaStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAvailable => status == ChavrusaStatus.available;

  List<ChavrusaContactMethod> get allowedContacts => [
        if (okWhatsapp) ChavrusaContactMethod.whatsapp,
        if (okText) ChavrusaContactMethod.text,
        if (okCall) ChavrusaContactMethod.call,
      ];

  factory ChavrusaListing.fromMap(Map<String, dynamic> map) => ChavrusaListing(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        displayName: map['display_name'] as String,
        age: (map['age'] as num).toInt(),
        learningInterests: map['learning_interests'] as String,
        sessionLength: map['session_length'] as String,
        topic: map['topic'] as String,
        learningDetails: map['learning_details'] as String? ?? '',
        availability: map['availability'] as String,
        phone: map['phone'] as String,
        okWhatsapp: map['ok_whatsapp'] as bool? ?? false,
        okText: map['ok_text'] as bool? ?? false,
        okCall: map['ok_call'] as bool? ?? false,
        preferredContact:
            contactMethodFromDb(map['preferred_contact'] as String),
        status: chavrusaStatusFromDb(map['status'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toInsertMap({required String userId}) => {
        'user_id': userId,
        'display_name': displayName,
        'age': age,
        'learning_interests': learningInterests,
        'session_length': sessionLength,
        'topic': topic,
        'learning_details': learningDetails,
        'availability': availability,
        'phone': phone,
        'ok_whatsapp': okWhatsapp,
        'ok_text': okText,
        'ok_call': okCall,
        'preferred_contact': preferredContact.dbValue,
        'status': status.dbValue,
      };
}

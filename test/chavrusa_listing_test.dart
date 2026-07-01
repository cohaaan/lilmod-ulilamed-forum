import 'package:flutter_test/flutter_test.dart';

import 'package:lilmod_ulilamed/models/chavrusa_listing.dart';

void main() {
  test('ChavrusaListing round-trips from map', () {
    final map = {
      'id': 'abc',
      'user_id': 'user-1',
      'display_name': 'Yitzchak',
      'age': 28,
      'learning_interests': 'Gemara',
      'session_length': '45 min',
      'topic': 'Berachos',
      'learning_details': 'Chazarah and clarity',
      'availability': 'Weekdays 12:00–12:30',
      'phone': '+15551234567',
      'ok_whatsapp': true,
      'ok_text': true,
      'ok_call': false,
      'preferred_contact': 'whatsapp',
      'status': 'available',
      'created_at': '2026-06-30T12:00:00.000Z',
      'updated_at': '2026-06-30T12:00:00.000Z',
    };

    final listing = ChavrusaListing.fromMap(map);
    expect(listing.displayName, 'Yitzchak');
    expect(listing.learningDetails, 'Chazarah and clarity');
    expect(listing.preferredContact, ChavrusaContactMethod.whatsapp);
    expect(listing.allowedContacts, [
      ChavrusaContactMethod.whatsapp,
      ChavrusaContactMethod.text,
    ]);

    final insert = listing.toInsertMap(userId: 'user-1');
    expect(insert['user_id'], 'user-1');
    expect(insert['learning_details'], 'Chazarah and clarity');
    expect(insert['preferred_contact'], 'whatsapp');
  });

  test('availability slots encode and format', () {
    expect(chavrusaTimeSlots.length, 24);
    expect(chavrusaTimeSlots.first, '7 AM – 8 AM');
    expect(chavrusaTimeSlots.last, '6 AM – 7 AM');

    final encoded = encodeChavrusaAvailability(
      slots: const [
        ChavrusaAvailabilitySlot(day: 'Tuesday', time: '12 PM – 1 PM'),
        ChavrusaAvailabilitySlot(day: 'Thursday', time: '7 AM – 8 AM'),
      ],
      note: 'Lunch break only',
    );
    final parsed = parseChavrusaAvailability(encoded);
    expect(parsed.slots.length, 2);
    expect(parsed.note, 'Lunch break only');
    expect(
      formatChavrusaAvailability(encoded),
      'Tuesday, 12 PM – 1 PM; Thursday, 7 AM – 8 AM; Lunch break only',
    );
  });

  test('legacy availability text is preserved', () {
    const legacy = 'Weekdays 12:00–12:30';
    final parsed = parseChavrusaAvailability(legacy);
    expect(parsed.slots.length, 1);
    expect(parsed.note, legacy);
    expect(formatChavrusaAvailability(legacy), legacy);
  });

  test('availability query matches day and time window', () {
    final listing = ChavrusaListing.fromMap({
      'id': 'x',
      'user_id': 'u',
      'display_name': 'Test',
      'age': 30,
      'learning_interests': 'Gemara',
      'session_length': '30 min',
      'topic': 'Berachos',
      'learning_details': '',
      'availability':
          '[{"day":"Monday","time":"12 PM – 1 PM"},{"day":"Thursday","time":"7 AM – 8 AM"}]',
      'phone': '555',
      'ok_whatsapp': true,
      'ok_text': false,
      'ok_call': false,
      'preferred_contact': 'whatsapp',
      'status': 'available',
      'created_at': '2026-06-30T12:00:00.000Z',
      'updated_at': '2026-06-30T12:00:00.000Z',
    });

    expect(
      chavrusaListingMatchesAvailabilityQuery(listing, day: 'Monday'),
      isTrue,
    );
    expect(
      chavrusaListingMatchesAvailabilityQuery(listing, day: 'Friday'),
      isFalse,
    );
    expect(
      chavrusaListingMatchesAvailabilityQuery(
        listing,
        day: 'Monday',
        time: '12 PM – 1 PM',
      ),
      isTrue,
    );
    expect(
      chavrusaListingMatchesAvailabilityQuery(
        listing,
        day: 'Monday',
        time: '7 AM – 8 AM',
      ),
      isFalse,
    );
    expect(
      chavrusaListingMatchesAvailabilityQuery(
        listing,
        day: 'Tuesday',
        time: '12 PM – 1 PM',
      ),
      isFalse,
    );
    expect(
      chavrusaListingMatchesAvailabilityQuery(
        listing,
        time: '12 PM – 1 PM',
      ),
      isTrue,
    );
  });

  test('weekday groups overlap for availability query', () {
    final listing = ChavrusaListing.fromMap({
      'id': 'x',
      'user_id': 'u',
      'display_name': 'Test',
      'age': 30,
      'learning_interests': 'Halacha',
      'session_length': '30 min',
      'topic': 'Berachos',
      'learning_details': '',
      'availability': '[{"day":"Weekdays","time":"12 PM – 1 PM"}]',
      'phone': '555',
      'ok_whatsapp': true,
      'ok_text': false,
      'ok_call': false,
      'preferred_contact': 'whatsapp',
      'status': 'available',
      'created_at': '2026-06-30T12:00:00.000Z',
      'updated_at': '2026-06-30T12:00:00.000Z',
    });

    expect(
      chavrusaListingMatchesAvailabilityQuery(listing, day: 'Wednesday'),
      isTrue,
    );
    expect(
      chavrusaListingMatchesAvailabilityQuery(listing, day: 'Sunday'),
      isFalse,
    );
  });
}

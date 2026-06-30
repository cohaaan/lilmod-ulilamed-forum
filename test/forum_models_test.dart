import 'package:flutter_test/flutter_test.dart';
import 'package:lilmod_ulilamed/models/category.dart';
import 'package:lilmod_ulilamed/models/profile.dart';

void main() {
  group('Profile.fromMap', () {
    test('uses display_name when present', () {
      final p = Profile.fromMap({'id': 'u1', 'display_name': 'Philo'});
      expect(p.displayName, 'Philo');
    });

    test('falls back to Member on empty/missing name', () {
      expect(Profile.fromMap({'id': 'u', 'display_name': ''}).displayName,
          'Member');
      expect(Profile.fromMap({'id': 'u'}).displayName, 'Member');
      expect(Profile.fromMap({'id': 'u', 'display_name': '   '}).displayName,
          'Member');
    });
  });

  group('Subforum', () {
    test('fromMap parses fields and defaults threadCount to 0', () {
      final s = Subforum.fromMap({
        'id': 'gemara',
        'category_id': 'beis-hamidrash',
        'name': 'Gemara',
        'description': 'Sugya discussion',
      });
      expect(s.id, 'gemara');
      expect(s.categoryId, 'beis-hamidrash');
      expect(s.threadCount, 0);
    });

    test('copyWith overrides threadCount only', () {
      const s = Subforum(
        id: 'gemara',
        categoryId: 'beis-hamidrash',
        name: 'Gemara',
        description: 'd',
      );
      final s2 = s.copyWith(threadCount: 7);
      expect(s2.threadCount, 7);
      expect(s2.id, 'gemara');
      expect(s2.name, 'Gemara');
    });
  });

  group('Category', () {
    test('threadCount sums subforum counts', () {
      const cat = Category(
        id: 'c',
        name: 'N',
        description: 'd',
        subforums: [
          Subforum(id: 'a', categoryId: 'c', name: 'A', description: '', threadCount: 3),
          Subforum(id: 'b', categoryId: 'c', name: 'B', description: '', threadCount: 2),
        ],
      );
      expect(cat.threadCount, 5);
    });

    test('withSubforums replaces subforums, keeps identity', () {
      const cat = Category(id: 'c', name: 'N', description: 'd');
      final updated = cat.withSubforums(const [
        Subforum(id: 'a', categoryId: 'c', name: 'A', description: ''),
      ]);
      expect(updated.id, 'c');
      expect(updated.subforums.length, 1);
    });

    test('fromMap parses nested subforums', () {
      final cat = Category.fromMap({
        'id': 'c',
        'name': 'N',
        'description': 'd',
        'subforums': [
          {'id': 's', 'category_id': 'c', 'name': 'S', 'description': 'sd'},
        ],
      });
      expect(cat.subforums.single.id, 's');
    });
  });
}

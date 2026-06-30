class Subforum {
  const Subforum({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    this.threadCount = 0,
  });

  final String id;
  final String categoryId;
  final String name;
  final String description;
  final int threadCount;

  factory Subforum.fromMap(Map<String, dynamic> map) => Subforum(
        id: map['id'] as String,
        categoryId: map['category_id'] as String? ?? '',
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
      );

  Subforum copyWith({int? threadCount}) => Subforum(
        id: id,
        categoryId: categoryId,
        name: name,
        description: description,
        threadCount: threadCount ?? this.threadCount,
      );
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
    this.subforums = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<Subforum> subforums;

  int get threadCount =>
      subforums.fold(0, (sum, s) => sum + s.threadCount);

  factory Category.fromMap(Map<String, dynamic> map) => Category(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String? ?? '',
        subforums: ((map['subforums'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Subforum.fromMap)
            .toList(),
      );

  Category withSubforums(List<Subforum> subs) => Category(
        id: id,
        name: name,
        description: description,
        subforums: subs,
      );
}

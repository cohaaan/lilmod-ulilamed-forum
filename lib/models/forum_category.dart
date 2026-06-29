class ForumSubforum {
  const ForumSubforum({
    required this.name,
    required this.description,
    required this.threadCount,
    required this.postCount,
  });

  final String name;
  final String description;
  final int threadCount;
  final int postCount;
}

class ForumCategory {
  const ForumCategory({
    required this.name,
    required this.description,
    required this.subforums,
  });

  final String name;
  final String description;
  final List<ForumSubforum> subforums;
}

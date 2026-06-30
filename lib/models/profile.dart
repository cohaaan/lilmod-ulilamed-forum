class Profile {
  const Profile({required this.id, required this.displayName, this.avatarUrl});

  final String id;
  final String displayName;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
        id: map['id'] as String,
        displayName: (map['display_name'] as String?)?.trim().isNotEmpty == true
            ? map['display_name'] as String
            : 'Member',
        avatarUrl: map['avatar_url'] as String?,
      );
}

/// Entity người dùng ánh xạ từ backend User / UserPublic.
class User {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final String? school;
  final String? major;
  final String role;
  final DateTime createdAt;
  final int friendsCount;
  final int documentsCount;
  final int postsCount;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.school,
    this.major,
    this.role = 'user',
    required this.createdAt,
    this.friendsCount = 0,
    this.documentsCount = 0,
    this.postsCount = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      school: json['school'] as String?,
      major: json['major'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: DateTime.parse(json['created_at'] as String),
      friendsCount: json['friends_count'] as int? ?? 0,
      documentsCount: json['documents_count'] as int? ?? 0,
      postsCount: json['posts_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
      'school': school,
      'major': major,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'friends_count': friendsCount,
      'documents_count': documentsCount,
      'posts_count': postsCount,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? bio,
    String? school,
    String? major,
    String? role,
    DateTime? createdAt,
    int? friendsCount,
    int? documentsCount,
    int? postsCount,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      school: school ?? this.school,
      major: major ?? this.major,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      friendsCount: friendsCount ?? this.friendsCount,
      documentsCount: documentsCount ?? this.documentsCount,
      postsCount: postsCount ?? this.postsCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

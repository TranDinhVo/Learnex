class RoomModel {
  final String id;
  final String ownerId;
  final String name;
  final String? description;
  final String? avatarUrl;
  final String privacyMode;
  final String? ownerName;
  final String? ownerUsername;
  final String? ownerAvatar;
  final int memberCount;
  final bool isMember;
  final bool isPending;
  final String? userRole;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.description,
    this.avatarUrl,
    required this.privacyMode,
    this.ownerName,
    this.ownerUsername,
    this.ownerAvatar,
    required this.memberCount,
    required this.isMember,
    this.isPending = false,
    this.userRole,
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      privacyMode: json['privacy_mode'] as String? ?? 'public',
      ownerName: json['owner_name'] as String?,
      ownerUsername: json['owner_username'] as String?,
      ownerAvatar: json['owner_avatar'] as String?,
      memberCount: json['member_count'] as int? ?? 0,
      isMember: json['is_member'] as bool? ?? false,
      isPending: json['is_pending'] as bool? ?? false,
      userRole: json['user_role'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class RoomMemberModel {
  final String id;
  final String role;
  final String userId;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final DateTime joinedAt;

  RoomMemberModel({
    required this.id,
    required this.role,
    required this.userId,
    this.fullName,
    this.username,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory RoomMemberModel.fromJson(Map<String, dynamic> json) {
    return RoomMemberModel(
      id: json['id'] as String,
      role: json['role'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class RoomMessageModel {
  final String id;
  final String roomId;
  final String? senderId;
  final String? content;
  final String? fileUrl;
  final String? senderName;
  final String? senderUsername;
  final String? senderAvatar;
  final DateTime createdAt;

  RoomMessageModel({
    required this.id,
    required this.roomId,
    this.senderId,
    this.content,
    this.fileUrl,
    this.senderName,
    this.senderUsername,
    this.senderAvatar,
    required this.createdAt,
  });

  factory RoomMessageModel.fromJson(Map<String, dynamic> json) {
    return RoomMessageModel(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      senderId: json['sender_id'] as String?,
      content: json['content'] as String?,
      fileUrl: json['file_url'] as String?,
      senderName: json['sender_name'] as String?,
      senderUsername: json['sender_username'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

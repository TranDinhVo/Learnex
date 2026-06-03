class StoryModel {
  final String id;
  final String userId;
  final String? mediaUrl;
  final String mediaType;
  final String? textContent;
  final String? textColor;
  final String? bgColor;
  final String? bgGradient;
  final int durationSec;
  final String visibility;
  final bool isActive;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isViewed;
  final String? excludedUserIds;

  StoryModel({
    required this.id,
    required this.userId,
    this.mediaUrl,
    this.mediaType = 'image',
    this.textContent,
    this.textColor,
    this.bgColor,
    this.bgGradient,
    this.durationSec = 5,
    this.visibility = 'friends',
    this.isActive = true,
    this.isArchived = false,
    required this.createdAt,
    required this.expiresAt,
    this.isViewed = false,
    this.excludedUserIds,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    int parsedDuration = 5;
    if (json['duration_sec'] != null) {
      if (json['duration_sec'] is int) parsedDuration = json['duration_sec'];
      else if (json['duration_sec'] is String) parsedDuration = int.tryParse(json['duration_sec']) ?? 5;
      else if (json['duration_sec'] is double) parsedDuration = (json['duration_sec'] as double).toInt();
    }

    return StoryModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      mediaUrl: json['media_url'],
      mediaType: json['media_type'] ?? 'image',
      textContent: json['text_content'],
      textColor: json['text_color'],
      bgColor: json['bg_color'],
      bgGradient: json['bg_gradient'],
      durationSec: parsedDuration,
      visibility: json['visibility'] ?? 'friends',
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : DateTime.now(),
      isViewed: json['is_viewed'] ?? false,
      excludedUserIds: json['excluded_user_ids'] != null ? json['excluded_user_ids'].toString() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'text_content': textContent,
      'text_color': textColor,
      'bg_color': bgColor,
      'bg_gradient': bgGradient,
      'duration_sec': durationSec,
      'visibility': visibility,
      'is_active': isActive,
      'is_archived': isArchived,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'is_viewed': isViewed,
      'excluded_user_ids': excludedUserIds,
    };
  }
}

class FriendStoryGroup {
  final String userId;
  final String userName;
  final String? userAvatar;
  final bool hasUnseen;
  final List<StoryModel> stories;

  FriendStoryGroup({
    required this.userId,
    required this.userName,
    this.userAvatar,
    this.hasUnseen = false,
    required this.stories,
  });

  factory FriendStoryGroup.fromJson(Map<String, dynamic> json) {
    var list = json['stories'] as List? ?? [];
    List<StoryModel> storiesList = list.map((i) => StoryModel.fromJson(i)).toList();

    return FriendStoryGroup(
      userId: json['user_id'] ?? '',
      userName: json['user_name'] ?? 'Học viên',
      userAvatar: json['user_avatar'],
      hasUnseen: json['has_unseen'] ?? false,
      stories: storiesList,
    );
  }
}

class StoryViewerModel {
  final String id;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final DateTime viewedAt;
  final String? reaction;

  StoryViewerModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    required this.viewedAt,
    this.reaction,
  });

  factory StoryViewerModel.fromJson(Map<String, dynamic> json) {
    return StoryViewerModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'],
      viewedAt: json['viewed_at'] != null ? DateTime.parse(json['viewed_at']) : DateTime.now(),
      reaction: json['reaction'],
    );
  }
}

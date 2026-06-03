abstract class StoryEvent {}

class LoadStoryFeedEvent extends StoryEvent {}

class CreateStoryEvent extends StoryEvent {
  final String? mediaPath; // Path on device, will be uploaded first
  final String mediaType;
  final String? textContent;
  final String? textColor;
  final String? bgColor;
  final String? bgGradient;
  final int durationSec;
  final String visibility;
  final List<String>? excludedUserIds;

  CreateStoryEvent({
    this.mediaPath,
    this.mediaType = 'image',
    this.textContent,
    this.textColor,
    this.bgColor,
    this.bgGradient,
    this.durationSec = 5,
    this.visibility = 'friends',
    this.excludedUserIds,
  });
}

class ViewStoryEvent extends StoryEvent {
  final String storyId;
  ViewStoryEvent({required this.storyId});
}

class ReactStoryEvent extends StoryEvent {
  final String storyId;
  final String emoji;
  ReactStoryEvent({required this.storyId, required this.emoji});
}

class WsNewStoryReceivedEvent extends StoryEvent {
  final String userId;
  final String storyId;

  WsNewStoryReceivedEvent({required this.userId, required this.storyId});
}

class WsStoryReactionReceivedEvent extends StoryEvent {
  final String storyId;
  final String userId;
  final String emoji;

  WsStoryReactionReceivedEvent({
    required this.storyId,
    required this.userId,
    required this.emoji,
  });
}

class WsStoryViewUpdateEvent extends StoryEvent {
  final String storyId;
  final String storyOwnerId;
  final int viewCount;

  WsStoryViewUpdateEvent({
    required this.storyId,
    required this.storyOwnerId,
    required this.viewCount,
  });
}

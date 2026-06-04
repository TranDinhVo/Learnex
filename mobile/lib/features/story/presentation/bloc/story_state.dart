import '../../domain/models/story_model.dart';

abstract class StoryState {}

class StoryInitial extends StoryState {}

class StoryFeedLoading extends StoryState {}

class StoryFeedLoaded extends StoryState {
  final List<StoryModel> myStories;
  final List<FriendStoryGroup> friendStories;

  StoryFeedLoaded({required this.myStories, required this.friendStories});

  StoryFeedLoaded copyWith({
    List<StoryModel>? myStories,
    List<FriendStoryGroup>? friendStories,
  }) {
    return StoryFeedLoaded(
      myStories: myStories ?? this.myStories,
      friendStories: friendStories ?? this.friendStories,
    );
  }
}

class StoryFeedError extends StoryState {
  final String message;
  StoryFeedError(this.message);
}

// Separate states for creating
class StoryCreating extends StoryState {}

class StoryCreated extends StoryState {}

class StoryCreateError extends StoryState {
  final String message;
  StoryCreateError(this.message);
}

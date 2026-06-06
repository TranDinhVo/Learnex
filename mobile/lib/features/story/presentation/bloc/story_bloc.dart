import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'story_event.dart';
import 'story_state.dart';
import '../../domain/models/story_model.dart';
import '../../data/repositories/story_repository_impl.dart';
import '../../../../../core/services/websocket_service.dart';

class StoryBloc extends Bloc<StoryEvent, StoryState> {
  final StoryRepositoryImpl repository;
  final WebSocketService wsService;
  final Dio dio;
  StreamSubscription? _wsSubscription;

  StoryBloc({
    required this.repository,
    required this.wsService,
    required this.dio,
  }) : super(StoryInitial()) {
    on<LoadStoryFeedEvent>(_onLoadStoryFeed);
    on<CreateStoryEvent>(_onCreateStory);
    on<ViewStoryEvent>(_onViewStory);
    on<ReactStoryEvent>(_onReactStory);
    on<WsNewStoryReceivedEvent>(_onWsNewStory);
    on<WsStoryReactionReceivedEvent>(_onWsStoryReaction);
    on<WsStoryViewUpdateEvent>(_onWsStoryViewUpdate);

    _wsSubscription = wsService.messages.listen((message) {
      if (message['type'] == 'story_new_feed') {
        final data = message['data'];
        add(WsNewStoryReceivedEvent(
          userId: data['userId'],
          storyId: data['storyId'],
        ));
      } else if (message['type'] == 'story_reaction') {
        final data = message['data'];
        add(WsStoryReactionReceivedEvent(
          storyId: data['storyId'],
          userId: data['userId'],
          emoji: data['emoji'],
        ));
      } else if (message['type'] == 'story_view_update') {
        final data = message['data'];
        add(WsStoryViewUpdateEvent(
          storyId: data['storyId'],
          storyOwnerId: data['storyOwnerId'],
          viewCount: data['viewCount'] as int? ?? 0,
        ));
      } else if (message['type'] == 'story_deleted' || message['type'] == 'story_privacy_updated') {
        add(LoadStoryFeedEvent());
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadStoryFeed(LoadStoryFeedEvent event, Emitter<StoryState> emit) async {
    emit(StoryFeedLoading());
    try {
      final data = await repository.getFeedStories();
      final myRaw = data['data']['my_stories'] as List? ?? [];
      final friendRaw = data['data']['friend_stories'] as List? ?? [];

      final myStories = myRaw.map((e) => StoryModel.fromJson(e)).toList();
      final friendStories = friendRaw.map((e) => FriendStoryGroup.fromJson(e)).toList();

      emit(StoryFeedLoaded(myStories: myStories, friendStories: friendStories));
    } catch (e) {
      emit(StoryFeedError('Failed to load stories: $e'));
    }
  }

  Future<void> _onCreateStory(CreateStoryEvent event, Emitter<StoryState> emit) async {
    final currentState = state;
    emit(StoryCreating());
    try {
      String? mediaUrl;

      // 1. Upload media if exists
      if (event.mediaPath != null) {
        if (event.mediaType == 'video') {
          final formData = FormData.fromMap({
            'document': await MultipartFile.fromFile(event.mediaPath!),
          });
          final uploadRes = await dio.post('/upload/document', data: formData);
          mediaUrl = uploadRes.data['data']['url'];
        } else {
          final formData = FormData.fromMap({
            'image': await MultipartFile.fromFile(event.mediaPath!),
          });
          final uploadRes = await dio.post('/upload/image', data: formData);
          mediaUrl = uploadRes.data['data']['url'];
        }
      }

      // 2. Create story
      await repository.createStory(
        mediaUrl: mediaUrl,
        mediaType: event.mediaType,
        textContent: event.textContent,
        textColor: event.textColor,
        bgColor: event.bgColor,
        bgGradient: event.bgGradient,
        durationSec: event.durationSec,
        visibility: event.visibility,
        excludedUserIds: event.excludedUserIds,
      );

      emit(StoryCreated());
      
      // Reload feed to get the new story immediately
      add(LoadStoryFeedEvent());
      
    } catch (e) {
      emit(StoryCreateError('Failed to create story'));
      if (currentState is StoryFeedLoaded) {
        // revert to previous loaded state after showing error
        await Future.delayed(const Duration(seconds: 1));
        emit(currentState);
      }
    }
  }

  Future<void> _onViewStory(ViewStoryEvent event, Emitter<StoryState> emit) async {
    try {
      await repository.viewStory(event.storyId);
      // We could update local state to mark as viewed
    } catch (e) {
      // Ignore
    }
  }

  Future<void> _onReactStory(ReactStoryEvent event, Emitter<StoryState> emit) async {
    try {
      await repository.reactStory(event.storyId, event.emoji);
    } catch (e) {
      // Ignore
    }
  }

  void _onWsNewStory(WsNewStoryReceivedEvent event, Emitter<StoryState> emit) {
    // A new story was posted, just reload feed
    // In a more complex app, we could insert it into the current state
    add(LoadStoryFeedEvent());
  }

  void _onWsStoryReaction(WsStoryReactionReceivedEvent event, Emitter<StoryState> emit) {
    // Reactions don't need to trigger a full reload unless we are currently viewing the story
  }

  void _onWsStoryViewUpdate(WsStoryViewUpdateEvent event, Emitter<StoryState> emit) {
    // StoryViewerScreen lắng nghe event này qua wsService.messages stream trực tiếp
    // để cập nhật _viewCount real-time mà không cần rebuild toàn bộ state
  }
}

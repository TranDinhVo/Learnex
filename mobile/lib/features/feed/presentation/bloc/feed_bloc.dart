import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/enums/post_visibility.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// BLoC xử lý feed bài viết: tải, phân trang, CRUD, like/save.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepositoryImpl _repository;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  FeedBloc({
    required FeedRepositoryImpl repository,
    required WebSocketService wsService,
  })  : _repository = repository,
        _wsService = wsService,
        super(FeedInitial()) {
    on<LoadFeedEvent>(_onLoadFeed);
    on<LoadMoreFeedEvent>(_onLoadMore);
    on<RefreshFeedEvent>(_onRefresh);
    on<CreatePostEvent>(_onCreatePost);
    on<EditPostEvent>(_onEditPost);
    on<LikePostEvent>(_onLikePost);
    on<SavePostEvent>(_onSavePost);
    on<DeletePostEvent>(_onDeletePost);
    on<LoadCommentsEvent>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<UpdatePostInListEvent>(_onUpdatePostInList);
    on<UploadImagesEvent>(_onUploadImages);
    on<MergePendingPostsEvent>(_onMergePendingPosts);

    on<WsNewPostReceivedEvent>(_onWsNewPostReceived);
    on<WsPostLikeUpdatedEvent>(_onWsPostLikeUpdated);
    on<WsCommentAddedEvent>(_onWsCommentAdded);
    on<WsCommentDeletedEvent>(_onWsCommentDeleted);
    on<WsPostDeletedEvent>(_onWsPostDeleted);

    _wsSubscription = _wsService.messages.listen((message) {
      final type = message['type'];
      final data = message['data'] ?? {};
      
      switch (type) {
        case 'feed_new_post':
          if (data['post'] != null) {
            add(WsNewPostReceivedEvent(post: data['post']));
          }
          break;
        case 'feed_post_liked':
          add(WsPostLikeUpdatedEvent(
            postId: data['postId']?.toString() ?? '',
            likedBy: data['likedBy']?.toString() ?? '',
            liked: data['liked'] == true,
            likeCount: data['likeCount'] ?? 0,
          ));
          break;
        case 'feed_comment_added':
          add(WsCommentAddedEvent(
            postId: data['postId']?.toString() ?? '',
            comment: data['comment'] ?? {},
          ));
          break;
        case 'feed_comment_deleted':
          add(WsCommentDeletedEvent(
            postId: data['postId']?.toString() ?? '',
            commentId: data['commentId']?.toString() ?? '',
          ));
          break;
        case 'feed_post_deleted':
          add(WsPostDeletedEvent(postId: data['postId']?.toString() ?? ''));
          break;
      }
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadFeed(
    LoadFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(FeedLoading());
    try {
      final result = await _repository.getFeed(page: 1);
      final posts = _extractPosts(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = (pagination?['page'] ?? 1) < (pagination?['totalPages'] ?? 1);

      emit(FeedLoaded(posts: posts, hasMore: hasMore, currentPage: 1));
    } on DioException catch (e) {
      emit(FeedError(_extractError(e)));
    } catch (e) {
      emit(FeedError('Không thể tải bài viết. Vui lòng thử lại.'));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    if (currentState is! FeedLoaded || !currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;
    emit(FeedLoadingMore(
      currentPosts: currentState.posts,
      currentPage: currentState.currentPage,
    ));

    try {
      final result = await _repository.getFeed(page: nextPage);
      final newPosts = _extractPosts(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = nextPage < (pagination?['totalPages'] ?? 1);

      emit(FeedLoaded(
        posts: [...currentState.posts, ...newPosts],
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (e) {
      // Nếu load more lỗi, giữ nguyên state hiện tại
      emit(currentState);
    }
  }

  Future<void> _onRefresh(
    RefreshFeedEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final result = await _repository.getFeed(page: 1);
      final posts = _extractPosts(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = 1 < (pagination?['totalPages'] ?? 1);

      emit(FeedLoaded(posts: posts, hasMore: hasMore, currentPage: 1));
    } catch (e) {
      // Giữ nguyên state nếu refresh lỗi
    }
  }

  Future<void> _onCreatePost(
    CreatePostEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(PostCreating());
    try {
      await Future.delayed(const Duration(milliseconds: 800)); // Hiệu ứng delay giả lập mạng
      final result = await _repository.createPost(
        content: event.content,
        imageUrls: event.imageUrls,
        documentId: event.documentId,
        visibility: event.visibility.value,
        location: event.location,
        taggedUserIds: event.taggedUserIds,
      );
      final data = result['data'] ?? result;
      final postData = data as Map<String, dynamic>;
      
      final currentState = state; // Wait, state is currently PostCreating, but we need previous FeedLoaded.
      // Actually, we can't get FeedLoaded directly if we emitted PostCreating.
      // Let's just emit PostCreated to close the dialog.
      emit(PostCreated(postData));

      // After a short delay, to make sure UI is ready, we dispatch an event to insert it locally
      // if we don't want to wait for WS, but since we are emitting PostCreated, we might lose the FeedLoaded state entirely!
      // Wait, FeedBloc state replaces FeedLoaded with PostCreated, then it is stuck in PostCreated?
      // Yes, if we don't restore FeedLoaded!
      // This is why add(LoadFeedEvent()) was used!
      // Let's create an event to insert post.
      add(WsNewPostReceivedEvent(post: postData, isLocal: true));
      
    } on DioException catch (e) {
      emit(PostCreateError(_extractError(e)));
    } catch (e) {
      emit(PostCreateError('Không thể tạo bài viết.'));
    }
  }

  Future<void> _onEditPost(
    EditPostEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(PostEditing());
    try {
      final result = await _repository.updatePost(
        event.postId,
        content: event.content,
        imageUrls: event.imageUrls,
        documentId: event.documentId,
        visibility: event.visibility.value,
        location: event.location,
        taggedUserIds: event.taggedUserIds,
      );
      final data = result['data'] ?? result;
      emit(PostEdited(data as Map<String, dynamic>));

      // Cập nhật lại post trong danh sách nếu FeedLoaded
      add(UpdatePostInListEvent(updatedPost: data));
    } on DioException catch (e) {
      emit(PostEditError(_extractError(e)));
    } catch (e) {
      emit(PostEditError('Không thể sửa bài viết.'));
    }
  }

  Future<void> _onLikePost(
    LikePostEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is FeedLoaded) {
        final updatedPosts = currentState.posts.map((post) {
          if (post['id'].toString() == event.postId) {
            final isCurrentlyLiked = post['is_liked'] == true;
            final currentLikeCount = post['like_count'] as int? ?? 0;
            return {
              ...post,
              'is_liked': !isCurrentlyLiked,
              'like_count': isCurrentlyLiked
                  ? (currentLikeCount > 0 ? currentLikeCount - 1 : 0)
                  : currentLikeCount + 1,
            };
          }
          return post;
        }).toList();
        emit(currentState.copyWith(posts: updatedPosts));
      }
      await _repository.toggleLike(event.postId);
    } catch (_) {
      // Revert or ignore
    }
  }

  Future<void> _onSavePost(
    SavePostEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final currentState = state;
      if (currentState is FeedLoaded) {
        final updatedPosts = currentState.posts.map((post) {
          if (post['id'].toString() == event.postId) {
            final isCurrentlySaved = post['is_saved'] == true;
            return {
              ...post,
              'is_saved': !isCurrentlySaved,
            };
          }
          return post;
        }).toList();
        emit(currentState.copyWith(posts: updatedPosts));
      }
      await _repository.toggleSave(event.postId);
    } catch (_) {}
  }

  Future<void> _onDeletePost(
    DeletePostEvent event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    List<Map<String, dynamic>> previousPosts = [];

    if (currentState is FeedLoaded) {
      previousPosts = List<Map<String, dynamic>>.from(currentState.posts);
      final updatedPosts = currentState.posts.where((post) => post['id'].toString() != event.postId).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }

    try {
      await _repository.deletePost(event.postId);
      // We don't need to reload feed entirely if we optimistically removed it
      // But reloading can ensure data consistency.
      // add(LoadFeedEvent()); 
    } catch (_) {
      // Revert if error
      if (currentState is FeedLoaded) {
        emit(currentState.copyWith(posts: previousPosts));
      }
    }
  }

  Future<void> _onLoadComments(
    LoadCommentsEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final result = await _repository.getComments(event.postId);
      final comments = (result['data'] as List?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      emit(CommentsLoaded(postId: event.postId, comments: comments));
    } catch (_) {}
  }

  Future<void> _onAddComment(
    AddCommentEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _repository.addComment(event.postId, event.content);
      add(LoadCommentsEvent(postId: event.postId));
    } catch (_) {}
  }

  Future<void> _onDeleteComment(
    DeleteCommentEvent event,
    Emitter<FeedState> emit,
  ) async {
    try {
      await _repository.deleteComment(event.postId, event.commentId);
      add(LoadCommentsEvent(postId: event.postId));
    } catch (_) {}
  }

  void _onUpdatePostInList(
    UpdatePostInListEvent event,
    Emitter<FeedState> emit,
  ) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final updatedPosts = currentState.posts.map((post) {
        if (post['id'].toString() == event.updatedPost['id'].toString()) {
          return event.updatedPost;
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }

  // --- Realtime WebSocket Handlers ---
  
  void _onWsNewPostReceived(WsNewPostReceivedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final existsInPosts = currentState.posts.any((p) => p['id'].toString() == event.post['id'].toString());
      final existsInPending = currentState.pendingNewPosts.any((p) => p['id'].toString() == event.post['id'].toString());
      
      if (!existsInPosts && !existsInPending) {
        if (event.isLocal) {
          // If created locally by this user, insert directly
          emit(currentState.copyWith(posts: [event.post, ...currentState.posts]));
        } else {
          // If from others, put in pending list to show banner
          emit(currentState.copyWith(pendingNewPosts: [event.post, ...currentState.pendingNewPosts]));
        }
      }
    } else if (currentState is PostCreated && event.isLocal) {
       // If currently in PostCreated, wait a bit or we can't insert.
       // Actually, we need to recover the feed list. But we lost it because we didn't save it.
       // We should just call LoadFeedEvent if we lost the list.
       add(LoadFeedEvent());
    }
  }

  void _onMergePendingPosts(MergePendingPostsEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded && currentState.pendingNewPosts.isNotEmpty) {
      emit(currentState.copyWith(
        posts: [...currentState.pendingNewPosts, ...currentState.posts],
        pendingNewPosts: [],
      ));
    }
  }

  void _onWsPostLikeUpdated(WsPostLikeUpdatedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final updatedPosts = currentState.posts.map((post) {
        if (post['id'].toString() == event.postId) {
          return {
            ...post,
            'like_count': event.likeCount,
            // Only updating likeCount, keeping local is_liked optimistic
          };
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }

  void _onWsCommentAdded(WsCommentAddedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final updatedPosts = currentState.posts.map((post) {
        if (post['id'].toString() == event.postId) {
          return {
            ...post,
            'comment_count': (post['comment_count'] as int? ?? 0) + 1,
          };
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    } else if (currentState is CommentsLoaded && currentState.postId == event.postId) {
      final exists = currentState.comments.any((c) => c['id'].toString() == event.comment['id'].toString());
      if (!exists) {
        emit(CommentsLoaded(
          postId: event.postId,
          comments: [...currentState.comments, event.comment],
        ));
      }
    }
  }

  void _onWsCommentDeleted(WsCommentDeletedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final updatedPosts = currentState.posts.map((post) {
        if (post['id'].toString() == event.postId) {
          final currentCount = post['comment_count'] as int? ?? 1;
          return {
            ...post,
            'comment_count': currentCount > 0 ? currentCount - 1 : 0,
          };
        }
        return post;
      }).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    } else if (currentState is CommentsLoaded && currentState.postId == event.postId) {
      final updatedComments = currentState.comments.where((c) => c['id'].toString() != event.commentId).toList();
      emit(CommentsLoaded(postId: event.postId, comments: updatedComments));
    }
  }

  void _onWsPostDeleted(WsPostDeletedEvent event, Emitter<FeedState> emit) {
    final currentState = state;
    if (currentState is FeedLoaded) {
      final updatedPosts = currentState.posts.where((p) => p['id'].toString() != event.postId).toList();
      emit(currentState.copyWith(posts: updatedPosts));
    }
  }

  // ── Helpers ──

  List<Map<String, dynamic>> _extractPosts(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ?? 'Đã có lỗi xảy ra';
      }
    } catch (_) {}
    return e.message ?? 'Đã có lỗi xảy ra';
  }

  Future<void> _onUploadImages(
    UploadImagesEvent event,
    Emitter<FeedState> emit,
  ) async {
    emit(ImagesUploading());
    try {
      await Future.delayed(const Duration(milliseconds: 1500)); // Hiệu ứng delay giả lập upload mạng
      final urls = await _repository.uploadImages(event.files);
      emit(ImagesUploaded(urls));
    } catch (e) {
      emit(ImagesUploadError('Không thể tải ảnh lên. Vui lòng thử lại.'));
    }
  }
}

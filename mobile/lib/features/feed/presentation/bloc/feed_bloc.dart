import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../domain/enums/post_visibility.dart';
import 'feed_event.dart';
import 'feed_state.dart';

/// BLoC xử lý feed bài viết: tải, phân trang, CRUD, like/save.
class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final FeedRepositoryImpl _repository;

  FeedBloc({required FeedRepositoryImpl repository})
      : _repository = repository,
        super(FeedInitial()) {
    on<LoadFeedEvent>(_onLoadFeed);
    on<LoadMoreFeedEvent>(_onLoadMore);
    on<RefreshFeedEvent>(_onRefresh);
    on<CreatePostEvent>(_onCreatePost);
    on<LikePostEvent>(_onLikePost);
    on<SavePostEvent>(_onSavePost);
    on<DeletePostEvent>(_onDeletePost);
    on<LoadCommentsEvent>(_onLoadComments);
    on<AddCommentEvent>(_onAddComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<UpdatePostInListEvent>(_onUpdatePostInList);
    on<UploadImagesEvent>(_onUploadImages);
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
      final result = await _repository.createPost(
        content: event.content,
        imageUrls: event.imageUrls,
        documentId: event.documentId,
        visibility: event.visibility.value,
      );
      final data = result['data'] ?? result;
      emit(PostCreated(data as Map<String, dynamic>));

      // Reload feed sau khi tạo
      add(LoadFeedEvent());
    } on DioException catch (e) {
      emit(PostCreateError(_extractError(e)));
    } catch (e) {
      emit(PostCreateError('Không thể tạo bài viết.'));
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
    try {
      await _repository.deletePost(event.postId);
      // Reload feed
      add(LoadFeedEvent());
    } catch (_) {}
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
      final urls = await _repository.uploadImages(event.files);
      emit(ImagesUploaded(urls));
    } catch (e) {
      emit(ImagesUploadError('Không thể tải ảnh lên. Vui lòng thử lại.'));
    }
  }
}

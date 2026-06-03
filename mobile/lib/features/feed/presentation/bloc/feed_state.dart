/// States cho FeedBloc
abstract class FeedState {}

/// Trạng thái ban đầu
class FeedInitial extends FeedState {}

/// Đang tải feed lần đầu
class FeedLoading extends FeedState {}

/// Feed đã tải thành công
class FeedLoaded extends FeedState {
  final List<Map<String, dynamic>> posts;
  final List<Map<String, dynamic>> pendingNewPosts;
  final bool hasMore;
  final int currentPage;

  FeedLoaded({
    required this.posts,
    this.pendingNewPosts = const [],
    this.hasMore = true,
    this.currentPage = 1,
  });

  FeedLoaded copyWith({
    List<Map<String, dynamic>>? posts,
    List<Map<String, dynamic>>? pendingNewPosts,
    bool? hasMore,
    int? currentPage,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      pendingNewPosts: pendingNewPosts ?? this.pendingNewPosts,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Lỗi khi tải feed
class FeedError extends FeedState {
  final String message;
  FeedError(this.message);
}

/// Đang tải thêm bài viết (infinite scroll)
class FeedLoadingMore extends FeedState {
  final List<Map<String, dynamic>> currentPosts;
  final int currentPage;

  FeedLoadingMore({
    required this.currentPosts,
    required this.currentPage,
  });
}

/// Đang tạo bài viết
class PostCreating extends FeedState {}

/// Tạo bài viết thành công
class PostCreated extends FeedState {
  final Map<String, dynamic> post;
  PostCreated(this.post);
}

/// Lỗi khi tạo bài viết
class PostCreateError extends FeedState {
  final String message;
  PostCreateError(this.message);
}

/// Đang sửa bài viết
class PostEditing extends FeedState {}

/// Sửa bài viết thành công
class PostEdited extends FeedState {
  final Map<String, dynamic> post;
  PostEdited(this.post);
}

/// Lỗi khi sửa bài viết
class PostEditError extends FeedState {
  final String message;
  PostEditError(this.message);
}

/// Bình luận đã tải
class CommentsLoaded extends FeedState {
  final String postId;
  final List<Map<String, dynamic>> comments;
  CommentsLoaded({required this.postId, required this.comments});
}

/// Đang tải ảnh lên
class ImagesUploading extends FeedState {}

/// Tải ảnh lên thành công
class ImagesUploaded extends FeedState {
  final List<String> urls;
  ImagesUploaded(this.urls);
}

/// Lỗi tải ảnh
class ImagesUploadError extends FeedState {
  final String message;
  ImagesUploadError(this.message);
}

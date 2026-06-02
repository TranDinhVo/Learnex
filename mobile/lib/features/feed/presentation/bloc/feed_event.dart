import 'package:image_picker/image_picker.dart';
import '../../domain/enums/post_visibility.dart';

/// Events cho FeedBloc
abstract class FeedEvent {}

/// Tải feed lần đầu
class LoadFeedEvent extends FeedEvent {}

/// Tải thêm bài viết (infinite scroll)
class LoadMoreFeedEvent extends FeedEvent {}

/// Tạo bài viết mới
class CreatePostEvent extends FeedEvent {
  final String? content;
  final List<String>? imageUrls;
  final String? documentId;
  final PostVisibility visibility;
  final List<String>? taggedUserIds;

  CreatePostEvent({
    this.content, 
    this.imageUrls, 
    this.documentId,
    this.visibility = PostVisibility.public,
    this.taggedUserIds,
  });
}

/// Sửa bài viết
class EditPostEvent extends FeedEvent {
  final String postId;
  final String? content;
  final List<String>? imageUrls;
  final String? documentId;
  final PostVisibility visibility;
  final List<String>? taggedUserIds;

  EditPostEvent({
    required this.postId,
    this.content, 
    this.imageUrls, 
    this.documentId,
    this.visibility = PostVisibility.public,
    this.taggedUserIds,
  });
}

/// Like / Unlike bài viết
class LikePostEvent extends FeedEvent {
  final String postId;
  LikePostEvent({required this.postId});
}

/// Save / Unsave bài viết
class SavePostEvent extends FeedEvent {
  final String postId;
  SavePostEvent({required this.postId});
}

/// Xoá bài viết
class DeletePostEvent extends FeedEvent {
  final String postId;
  DeletePostEvent({required this.postId});
}

/// Tải bình luận của bài viết
class LoadCommentsEvent extends FeedEvent {
  final String postId;
  LoadCommentsEvent({required this.postId});
}

/// Thêm bình luận vào bài viết
class AddCommentEvent extends FeedEvent {
  final String postId;
  final String content;
  AddCommentEvent({required this.postId, required this.content});
}

/// Xoá bình luận
class DeleteCommentEvent extends FeedEvent {
  final String postId;
  final String commentId;
  DeleteCommentEvent({required this.postId, required this.commentId});
}

/// Refresh feed (pull to refresh)
class RefreshFeedEvent extends FeedEvent {}

/// Cập nhật cục bộ một bài viết trong danh sách feed
class UpdatePostInListEvent extends FeedEvent {
  final Map<String, dynamic> updatedPost;
  UpdatePostInListEvent({required this.updatedPost});
}

/// Tải ảnh lên
class UploadImagesEvent extends FeedEvent {
  final List<XFile> files;
  UploadImagesEvent({required this.files});
}

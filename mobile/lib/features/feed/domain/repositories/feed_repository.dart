import 'package:image_picker/image_picker.dart';

/// Abstract repository cho Feed feature.
/// Định nghĩa contract giữa domain và data layer.
abstract class FeedRepository {
  /// Lấy danh sách bài viết feed, có phân trang
  Future<Map<String, dynamic>> getFeed({int page = 1, int limit = 20, String? userId});

  /// Lấy danh sách bài viết đã lưu
  Future<Map<String, dynamic>> getSavedPosts({int page = 1, int limit = 20});

  /// Tạo bài viết mới
  Future<Map<String, dynamic>> createPost({
    String? content,
    List<String>? imageUrls,
    String? documentId,
    String visibility = 'public',
    String? location,
    List<String>? taggedUserIds,
  });

  /// Lấy chi tiết bài viết
  Future<Map<String, dynamic>> getPostById(String id);

  /// Cập nhật bài viết
  Future<Map<String, dynamic>> updatePost(
    String id, {
    String? content,
    List<String>? imageUrls,
    String? documentId,
    String? visibility,
    String? location,
    List<String>? taggedUserIds,
  });

  /// Xoá bài viết
  Future<void> deletePost(String id);

  /// Like / Unlike bài viết
  Future<Map<String, dynamic>> toggleLike(String postId);

  /// Save / Unsave bài viết
  Future<Map<String, dynamic>> toggleSave(String postId);

  /// Lấy bình luận của bài viết
  Future<Map<String, dynamic>> getComments(String postId, {int page = 1, int limit = 20});

  /// Thêm bình luận
  Future<Map<String, dynamic>> addComment(String postId, String content, {String? parentId, String? replyToCommentId});
  Future<Map<String, dynamic>> updateComment(String postId, String commentId, String content);

  /// Xoá bình luận
  Future<void> deleteComment(String postId, String commentId);

  /// Toggle like bình luận
  Future<Map<String, dynamic>> toggleCommentLike(String postId, String commentId);

  /// Lấy danh sách người đã like
  Future<List<dynamic>> getLikers(String postId);

  /// Upload ảnh
  Future<List<String>> uploadImages(List<XFile> files);
}

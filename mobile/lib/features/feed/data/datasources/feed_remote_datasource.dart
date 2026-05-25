import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote datasource gọi API feed/posts qua Dio.
class FeedRemoteDatasource {
  final Dio _dio;

  FeedRemoteDatasource(this._dio);

  /// Lấy feed bài viết có phân trang
  Future<Map<String, dynamic>> getFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.feed,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Lấy bài viết đã lưu
  Future<Map<String, dynamic>> getSavedPosts({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.savedPosts,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Tạo bài viết mới
  Future<Map<String, dynamic>> createPost({
    String? content,
    List<String>? imageUrls,
    String? documentId,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.createPost,
      data: {
        if (content != null) 'content': content,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (documentId != null) 'document_id': documentId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Lấy chi tiết bài viết
  Future<Map<String, dynamic>> getPostById(String id) async {
    final response = await _dio.get(ApiEndpoints.postById(id));
    return response.data as Map<String, dynamic>;
  }

  /// Cập nhật bài viết
  Future<Map<String, dynamic>> updatePost(
    String id, {
    String? content,
    List<String>? imageUrls,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.postById(id),
      data: {
        if (content != null) 'content': content,
        if (imageUrls != null) 'image_urls': imageUrls,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Xoá bài viết
  Future<void> deletePost(String id) async {
    await _dio.delete(ApiEndpoints.postById(id));
  }

  /// Toggle like
  Future<Map<String, dynamic>> toggleLike(String postId) async {
    final response = await _dio.post(ApiEndpoints.toggleLike(postId));
    return response.data as Map<String, dynamic>;
  }

  /// Toggle save
  Future<Map<String, dynamic>> toggleSave(String postId) async {
    final response = await _dio.post(ApiEndpoints.toggleSave(postId));
    return response.data as Map<String, dynamic>;
  }

  /// Lấy bình luận
  Future<Map<String, dynamic>> getComments(
    String postId, {
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.postComments(postId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Thêm bình luận
  Future<Map<String, dynamic>> addComment(
    String postId,
    String content,
  ) async {
    final response = await _dio.post(
      ApiEndpoints.postComments(postId),
      data: {'content': content},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Xoá bình luận
  Future<void> deleteComment(String postId, String commentId) async {
    await _dio.delete(ApiEndpoints.deleteComment(postId, commentId));
  }
}

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote datasource gọi API feed/posts qua Dio.
class FeedRemoteDatasource {
  final Dio _dio;

  FeedRemoteDatasource(this._dio);

  /// Lấy feed bài viết có phân trang
  Future<Map<String, dynamic>> getFeed({
    int page = 1,
    int limit = 20,
    String? userId,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.feed,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (userId != null) 'userId': userId,
      },
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

  Future<Map<String, dynamic>> createPost({
    String? content,
    List<String>? imageUrls,
    String? documentId,
    String visibility = 'public',
    String? location,
    List<String>? taggedUserIds,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.createPost,
      data: {
        if (content != null) 'content': content,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (documentId != null) 'document_id': documentId,
        'visibility': visibility,
        if (location != null) 'location': location,
        if (taggedUserIds != null && taggedUserIds.isNotEmpty) 'tagged_user_ids': taggedUserIds,
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
    String? documentId,
    String? visibility,
    String? location,
    List<String>? taggedUserIds,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.postById(id),
      data: {
        if (content != null) 'content': content,
        if (imageUrls != null) 'image_urls': imageUrls,
        if (documentId != null) 'document_id': documentId,
        if (visibility != null) 'visibility': visibility,
        if (location != null) 'location': location,
        if (taggedUserIds != null) 'tagged_user_ids': taggedUserIds,
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
  Future<Map<String, dynamic>> addComment(String postId, String content, {String? parentId, String? replyToCommentId}) async {
    final data = <String, dynamic>{
      'content': content,
    };
    if (parentId != null) {
      data['parent_id'] = parentId;
    }
    if (replyToCommentId != null) {
      data['reply_to_comment_id'] = replyToCommentId;
    }
    final response = await _dio.post(
      ApiEndpoints.postComments(postId),
      data: data,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Cập nhật bình luận
  Future<Map<String, dynamic>> updateComment(
    String postId,
    String commentId,
    String content,
  ) async {
    final response = await _dio.put(
      ApiEndpoints.deleteComment(postId, commentId), // Using deleteComment endpoint path since it matches /:id/comments/:commentId
      data: {'content': content},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Xoá bình luận
  Future<void> deleteComment(String postId, String commentId) async {
    await _dio.delete(ApiEndpoints.deleteComment(postId, commentId));
  }

  /// Toggle like bình luận
  Future<Map<String, dynamic>> toggleCommentLike(String postId, String commentId) async {
    final response = await _dio.post('${ApiEndpoints.postComments(postId)}/$commentId/like');
    return response.data as Map<String, dynamic>;
  }

  /// Lấy danh sách người đã like
  Future<List<dynamic>> getLikers(String postId) async {
    final response = await _dio.get('${ApiEndpoints.postById(postId)}/likers');
    return response.data['data'] as List<dynamic>;
  }

  /// Upload nhiều ảnh lên Cloudinary qua backend, trả về list URL
  Future<List<String>> uploadImages(List<XFile> files) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final bytes = await file.readAsBytes();
        final name = file.name;
        final extension = name.contains('.') ? name.split('.').last.toLowerCase() : 'png';
        
        multipartFiles.add(
          MultipartFile.fromBytes(
            bytes,
            filename: name.isEmpty ? 'image_$i.$extension' : name,
          ),
        );
      }
      
      final formData = FormData.fromMap({
        'images': multipartFiles,
      });

      final response = await _dio.post('/upload/images', data: formData);
      final data = response.data as Map<String, dynamic>;
      
      final urls = data['data']?['urls'] as List<dynamic>?;
      if (urls != null) {
        return urls.map((e) => e.toString()).toList();
      }
      return [];
    } catch (e) {
      print('Upload images error: $e');
      throw Exception('Không thể tải ảnh: $e');
    }
  }

  /// Tìm kiếm người dùng theo tên
  Future<List<Map<String, dynamic>>> searchUsers(String query, {bool friendsOnly = false}) async {
    final response = await _dio.get(
      '/users/search',
      queryParameters: {
        'q': query,
        if (friendsOnly) 'friends_only': 'true',
      },
    );
    final data = response.data['data'];
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
}

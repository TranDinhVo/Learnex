import 'package:image_picker/image_picker.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';

/// Triển khai FeedRepository, delegate sang FeedRemoteDatasource.
class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDatasource _datasource;

  FeedRepositoryImpl({required FeedRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Map<String, dynamic>> getFeed({int page = 1, int limit = 20, String? userId}) =>
      _datasource.getFeed(page: page, limit: limit, userId: userId);

  @override
  Future<Map<String, dynamic>> getSavedPosts({int page = 1, int limit = 20}) =>
      _datasource.getSavedPosts(page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> createPost({
    String? content,
    List<String>? imageUrls,
    String? documentId,
    String visibility = 'public',
    String? location,
    List<String>? taggedUserIds,
  }) =>
      _datasource.createPost(
        content: content,
        imageUrls: imageUrls,
        documentId: documentId,
        visibility: visibility,
        location: location,
        taggedUserIds: taggedUserIds,
      );

  @override
  Future<Map<String, dynamic>> getPostById(String id) =>
      _datasource.getPostById(id);

  @override
  Future<Map<String, dynamic>> updatePost(
    String id, {
    String? content,
    List<String>? imageUrls,
    String? documentId,
    String? visibility,
    String? location,
    List<String>? taggedUserIds,
  }) =>
      _datasource.updatePost(
        id,
        content: content,
        imageUrls: imageUrls,
        documentId: documentId,
        visibility: visibility,
        location: location,
        taggedUserIds: taggedUserIds,
      );

  @override
  Future<void> deletePost(String id) => _datasource.deletePost(id);

  @override
  Future<Map<String, dynamic>> toggleLike(String postId) =>
      _datasource.toggleLike(postId);

  @override
  Future<Map<String, dynamic>> toggleSave(String postId) =>
      _datasource.toggleSave(postId);

  @override
  Future<Map<String, dynamic>> getComments(String postId,
          {int page = 1, int limit = 20}) =>
      _datasource.getComments(postId, page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> addComment(String postId, String content, {String? parentId, String? replyToCommentId}) async {
    return await _datasource.addComment(postId, content, parentId: parentId, replyToCommentId: replyToCommentId);
  }

  @override
  Future<Map<String, dynamic>> updateComment(String postId, String commentId, String content) =>
      _datasource.updateComment(postId, commentId, content);

  @override
  Future<void> deleteComment(String postId, String commentId) =>
      _datasource.deleteComment(postId, commentId);

  @override
  Future<Map<String, dynamic>> toggleCommentLike(String postId, String commentId) =>
      _datasource.toggleCommentLike(postId, commentId);

  @override
  Future<List<dynamic>> getLikers(String postId) =>
      _datasource.getLikers(postId);

  @override
  Future<List<String>> uploadImages(List<XFile> files) =>
      _datasource.uploadImages(files);
}

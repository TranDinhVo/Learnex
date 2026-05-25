import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_datasource.dart';

/// Triển khai FeedRepository, delegate sang FeedRemoteDatasource.
class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDatasource _datasource;

  FeedRepositoryImpl({required FeedRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Map<String, dynamic>> getFeed({int page = 1, int limit = 20}) =>
      _datasource.getFeed(page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> getSavedPosts({int page = 1, int limit = 20}) =>
      _datasource.getSavedPosts(page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> createPost({
    String? content,
    List<String>? imageUrls,
    String? documentId,
  }) =>
      _datasource.createPost(
        content: content,
        imageUrls: imageUrls,
        documentId: documentId,
      );

  @override
  Future<Map<String, dynamic>> getPostById(String id) =>
      _datasource.getPostById(id);

  @override
  Future<Map<String, dynamic>> updatePost(String id,
          {String? content, List<String>? imageUrls}) =>
      _datasource.updatePost(id, content: content, imageUrls: imageUrls);

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
  Future<Map<String, dynamic>> addComment(String postId, String content) =>
      _datasource.addComment(postId, content);

  @override
  Future<void> deleteComment(String postId, String commentId) =>
      _datasource.deleteComment(postId, commentId);
}

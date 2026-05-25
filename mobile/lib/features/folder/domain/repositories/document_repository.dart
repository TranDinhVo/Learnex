/// Abstract repository cho Document feature.
abstract class DocumentRepository {
  Future<Map<String, dynamic>> getAll({int page, int limit, String? subject});
  Future<Map<String, dynamic>> search(String query);
  Future<Map<String, dynamic>> getRecommendations();
  Future<Map<String, dynamic>> getById(String id);
  Future<Map<String, dynamic>> upload({
    required String filePath,
    required String title,
    String? description,
    String? subject,
    List<String>? tags,
  });
  Future<String> download(String id);
  Future<void> trackView(String id);
  Future<void> delete(String id);
}

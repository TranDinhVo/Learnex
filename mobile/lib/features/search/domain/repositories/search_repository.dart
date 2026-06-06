abstract class SearchRepository {
  Future<Map<String, dynamic>> search(String query, String type, int page, int limit);
}

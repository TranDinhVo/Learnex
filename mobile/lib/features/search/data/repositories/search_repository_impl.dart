import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_datasource.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDatasource remoteDatasource;

  SearchRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Map<String, dynamic>> search(String query, String type, int page, int limit) async {
    try {
      return await remoteDatasource.search(query, type, page, limit);
    } catch (e) {
      throw Exception('Failed to search: $e');
    }
  }
}

import '../../domain/repositories/document_repository.dart';
import '../datasources/document_remote_datasource.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentRemoteDatasource _datasource;

  DocumentRepositoryImpl({required DocumentRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Map<String, dynamic>> getAll({int page = 1, int limit = 20, String? subject}) =>
      _datasource.getAll(page: page, limit: limit, subject: subject);

  @override
  Future<Map<String, dynamic>> getMine({int page = 1, int limit = 20, String? subject}) =>
      _datasource.getMine(page: page, limit: limit, subject: subject);

  @override
  Future<Map<String, dynamic>> getSaved({int page = 1, int limit = 20, String? subject}) =>
      _datasource.getSaved(page: page, limit: limit, subject: subject);

  @override
  Future<Map<String, dynamic>> search(String query) => _datasource.search(query);

  @override
  Future<List<dynamic>> getSubjects() => _datasource.getSubjects();

  @override
  Future<Map<String, dynamic>> getRecommendations() => _datasource.getRecommendations();

  @override
  Future<Map<String, dynamic>> getById(String id) => _datasource.getById(id);

  @override
  Future<Map<String, dynamic>> upload({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    required String title,
    String? description,
    String? subject,
    List<String>? tags,
  }) =>
      _datasource.upload(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        title: title,
        description: description,
        subject: subject,
        tags: tags,
      );

  @override
  Future<String> download(String id) => _datasource.download(id);

  @override
  Future<Map<String, dynamic>> toggleSave(String id) => _datasource.toggleSave(id);

  @override
  Future<void> trackView(String id) => _datasource.trackView(id);

  @override
  Future<void> delete(String id) => _datasource.delete(id);
}

import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote datasource cho Documents (thư mục tài liệu).
class DocumentRemoteDatasource {
  final Dio _dio;

  DocumentRemoteDatasource(this._dio);

  /// Lấy tất cả tài liệu (có filter)
  Future<Map<String, dynamic>> getAll({
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.documents,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (subject != null) 'subject': subject,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Lấy tài liệu của tôi
  Future<Map<String, dynamic>> getMine({
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.documents,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (subject != null) 'subject': subject,
        'mine': 'true',
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Lấy tài liệu đã lưu
  Future<Map<String, dynamic>> getSaved({
    int page = 1,
    int limit = 20,
    String? subject,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.savedDocuments,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (subject != null) 'subject': subject,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Bật/tắt lưu tài liệu
  Future<Map<String, dynamic>> toggleSave(String id) async {
    final response = await _dio.post(ApiEndpoints.toggleSaveDocument(id));
    return response.data as Map<String, dynamic>;
  }

  /// Lấy danh sách môn học
  Future<List<dynamic>> getSubjects() async {
    final response = await _dio.get(ApiEndpoints.documentSubjects);
    return response.data['data'] as List<dynamic>;
  }

  /// Tìm kiếm tài liệu
  Future<Map<String, dynamic>> search(String query) async {
    final response = await _dio.get(
      ApiEndpoints.searchDocuments,
      queryParameters: {'q': query},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Gợi ý tài liệu
  Future<Map<String, dynamic>> getRecommendations() async {
    final response = await _dio.get(ApiEndpoints.documentRecommendations);
    return response.data as Map<String, dynamic>;
  }

  /// Lấy chi tiết tài liệu
  Future<Map<String, dynamic>> getById(String id) async {
    final response = await _dio.get(ApiEndpoints.documentById(id));
    return response.data as Map<String, dynamic>;
  }

  /// Upload tài liệu
  Future<Map<String, dynamic>> upload({
    String? filePath,
    List<int>? fileBytes,
    required String fileName,
    required String title,
    String? description,
    String? subject,
    List<String>? tags,
  }) async {
    MultipartFile file;
    if (fileBytes != null) {
      file = MultipartFile.fromBytes(fileBytes, filename: fileName);
    } else if (filePath != null) {
      file = await MultipartFile.fromFile(filePath, filename: fileName);
    } else {
      throw Exception('Không có dữ liệu file');
    }

    final formData = FormData.fromMap({
      'file': file,
      'title': title,
      if (description != null) 'description': description,
      if (subject != null) 'subject': subject,
      if (tags != null) 'tags': tags,
    });
    final response = await _dio.post(
      ApiEndpoints.documents,
      data: formData,
    );
    return response.data as Map<String, dynamic>;
  }

  /// Tải tài liệu (tăng download count, trả về attachment URL)
  Future<String> download(String id) async {
    final response = await _dio.get(ApiEndpoints.downloadDocument(id));
    final data = response.data as Map<String, dynamic>;
    // Backend trả về { data: { file_url: '...' } }
    final fileUrl = (data['data']?['file_url'] ?? '') as String;
    return fileUrl;
  }

  /// Lấy URL stream tải trực tiếp từ backend (bypass Cloudinary)
  String streamUrl(String id) {
    return ApiEndpoints.streamDocument(id);
  }

  /// Track view
  Future<void> trackView(String id) async {
    await _dio.post(ApiEndpoints.viewDocument(id));
  }

  /// Xoá tài liệu
  Future<void> delete(String id) async {
    await _dio.delete(ApiEndpoints.documentById(id));
  }
}

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart'; // XFile works on both Web & Mobile
import '../network/api_endpoints.dart';

/// Dịch vụ upload ảnh/file lên backend — hoạt động trên cả Web lẫn Mobile.
///
/// Dùng [XFile.readAsBytes()] thay vì dart:io [File] để tương thích Web.
class MediaUploadService {
  final Dio _dio;

  MediaUploadService(this._dio);

  /// Upload ảnh, trả về URL Cloudinary.
  Future<String> uploadImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final fileName = _getFileName(imageFile);

    final formData = FormData.fromMap({
      'image': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    try {
      final response = await _dio.post(ApiEndpoints.uploadImage, data: formData);
      return response.data['data']['url'] as String;
    } on DioException catch (e) {
      throw _extractError(e);
    } catch (_) {
      throw Exception('Không thể tải ảnh lên. Vui lòng thử lại.');
    }
  }

  /// Upload tài liệu/video, trả về Map chứa url, file_size, file_type.
  Future<Map<String, dynamic>> uploadDocument(XFile documentFile) async {
    final bytes = await documentFile.readAsBytes();
    final fileName = _getFileName(documentFile);

    final formData = FormData.fromMap({
      'document': MultipartFile.fromBytes(bytes, filename: fileName),
    });

    try {
      final response = await _dio.post(ApiEndpoints.uploadDocument, data: formData);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _extractError(e);
    } catch (_) {
      throw Exception('Không thể tải tệp lên. Vui lòng thử lại.');
    }
  }

  String _getFileName(XFile xFile) {
    if (xFile.name.isNotEmpty) return xFile.name;
    final path = xFile.path;
    return path.contains('/') ? path.split('/').last : path;
  }

  Exception _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] != null) {
        return Exception(data['message']);
      }
    } catch (_) {}
    return Exception(e.message ?? 'Đã có lỗi kết nối khi tải lên.');
  }
}

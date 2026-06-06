import 'dart:convert';
import 'package:dio/dio.dart';

class AiRepository {
  final Dio _dio;

  AiRepository(this._dio);

  Future<String> chat({
    required String documentTitle,
    required String documentDescription,
    required String documentSubject,
    String fileUrl = '',
    required List<Map<String, String>> messages,
  }) async {
    try {
      final response = await _dio.post(
        '/ai/chat',
        data: jsonEncode({
          'documentTitle': documentTitle,
          'documentDescription': documentDescription,
          'documentSubject': documentSubject,
          'fileUrl': fileUrl,
          'messages': messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        // Backend returns: { status: 'success', message: '...', data: { reply: '...' } }
        if (data['status'] == 'success' && data['data'] != null) {
          return data['data']['reply'] as String;
        } else {
          throw Exception(data['message'] ?? 'Failed to chat with AI');
        }
      } else {
        throw Exception('Lỗi kết nối Learnex AI (Status: ${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Bạn chưa đăng nhập. Hãy đăng nhập để dùng Learnex AI.');
      }
      final msg = e.response?.data?['message'] ?? e.message ?? 'Không thể kết nối đến máy chủ';
      throw Exception(msg);
    }
  }
}

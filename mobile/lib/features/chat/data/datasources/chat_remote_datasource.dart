import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote datasource cho Chat (Direct Messages).
class ChatRemoteDatasource {
  final Dio _dio;

  ChatRemoteDatasource(this._dio);

  /// Lấy danh sách cuộc hội thoại
  Future<Map<String, dynamic>> getConversations({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.conversations,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Lấy tin nhắn trong cuộc hội thoại
  Future<Map<String, dynamic>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await _dio.get(
      ApiEndpoints.chatMessages(conversationId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Gửi tin nhắn text
  Future<Map<String, dynamic>> sendMessage(
    String conversationId, {
    String? content,
    String? fileUrl,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.sendMessage(conversationId),
      data: {
        if (content != null) 'content': content,
        if (fileUrl != null) 'file_url': fileUrl,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMessage(String messageId, {required String type}) async {
    await _dio.delete(
      ApiEndpoints.deleteMessage(messageId),
      data: {'type': type},
    );
  }

  Future<void> editMessage(String messageId, String content) async {
    await _dio.put(
      ApiEndpoints.editMessage(messageId),
      data: {'content': content},
    );
  }

  Future<void> toggleReaction(String messageId, String emoji) async {
    await _dio.post(
      ApiEndpoints.toggleReaction(messageId),
      data: {'emoji': emoji},
    );
  }
}

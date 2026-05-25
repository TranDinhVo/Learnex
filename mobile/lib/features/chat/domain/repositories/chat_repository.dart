/// Abstract repository cho Chat feature.
abstract class ChatRepository {
  Future<Map<String, dynamic>> getConversations({int page, int limit});
  Future<Map<String, dynamic>> getMessages(String conversationId, {int page, int limit});
  Future<Map<String, dynamic>> sendMessage(String conversationId, {String? content, String? fileUrl});
}

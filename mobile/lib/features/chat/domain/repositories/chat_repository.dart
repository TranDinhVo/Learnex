/// Abstract repository cho Chat feature.
abstract class ChatRepository {
  Future<Map<String, dynamic>> getConversations({int page, int limit});
  Future<Map<String, dynamic>> getMessages(String conversationId, {int page, int limit});
  Future<Map<String, dynamic>> sendMessage(String conversationId, {String? content, String? fileUrl});
  Future<void> deleteMessage(String messageId, {required String type});
  Future<void> editMessage(String messageId, String content);
  Future<void> toggleReaction(String messageId, String emoji);
}

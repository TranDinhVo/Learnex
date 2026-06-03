import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource _datasource;

  ChatRepositoryImpl({required ChatRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Map<String, dynamic>> getConversations({int page = 1, int limit = 20}) =>
      _datasource.getConversations(page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> getMessages(String conversationId, {int page = 1, int limit = 50}) =>
      _datasource.getMessages(conversationId, page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> sendMessage(String conversationId, {String? content, String? fileUrl}) =>
      _datasource.sendMessage(conversationId, content: content, fileUrl: fileUrl);

  @override
  Future<void> deleteMessage(String messageId, {required String type}) =>
      _datasource.deleteMessage(messageId, type: type);

  @override
  Future<void> editMessage(String messageId, String content) =>
      _datasource.editMessage(messageId, content);

  @override
  Future<void> toggleReaction(String messageId, String emoji) =>
      _datasource.toggleReaction(messageId, emoji);
}

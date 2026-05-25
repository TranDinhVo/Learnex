/// Events cho ChatBloc
abstract class ChatEvent {}

/// Tải danh sách cuộc hội thoại
class LoadConversationsEvent extends ChatEvent {}

/// Tải tin nhắn của một cuộc hội thoại
class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  LoadMessagesEvent({required this.conversationId});
}

/// Tải thêm tin nhắn cũ hơn
class LoadMoreMessagesEvent extends ChatEvent {
  final String conversationId;
  LoadMoreMessagesEvent({required this.conversationId});
}

/// Gửi tin nhắn
class SendMessageEvent extends ChatEvent {
  final String conversationId;
  final String? content;
  final String? fileUrl;
  SendMessageEvent({
    required this.conversationId,
    this.content,
    this.fileUrl,
  });
}

/// Nhận tin nhắn mới từ WebSocket
class ReceiveMessageEvent extends ChatEvent {
  final Map<String, dynamic> message;
  ReceiveMessageEvent({required this.message});
}

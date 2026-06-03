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

/// Gửi tín hiệu đang gõ
class SendTypingEvent extends ChatEvent {
  final String targetId;
  SendTypingEvent({required this.targetId});
}

/// Gửi tín hiệu ngừng gõ
class SendStopTypingEvent extends ChatEvent {
  final String targetId;
  SendStopTypingEvent({required this.targetId});
}

/// Nhận tín hiệu đang gõ từ đối phương
class PeerTypingStatusEvent extends ChatEvent {
  final String peerId;
  final bool isTyping;
  PeerTypingStatusEvent({required this.peerId, required this.isTyping});
}

/// Cập nhật danh sách online
class OnlineStatusReceivedEvent extends ChatEvent {
  final List<String> onlineUserIds;
  OnlineStatusReceivedEvent({required this.onlineUserIds});
}

/// Yêu cầu xóa tin nhắn (cho mình hoặc cả 2)
class DeleteMessageEvent extends ChatEvent {
  final String messageId;
  final String type; // 'for_me' or 'for_everyone'
  DeleteMessageEvent({required this.messageId, required this.type});
}

/// Yêu cầu sửa tin nhắn
class EditMessageEvent extends ChatEvent {
  final String messageId;
  final String content;
  EditMessageEvent({required this.messageId, required this.content});
}

/// Nhận thông báo đối phương đã xóa tin nhắn
class MessageDeletedByPeerEvent extends ChatEvent {
  final String messageId;
  MessageDeletedByPeerEvent({required this.messageId});
}

/// Nhận thông báo đối phương đã sửa tin nhắn
class MessageEditedByPeerEvent extends ChatEvent {
  final String messageId;
  final String newContent;
  MessageEditedByPeerEvent({required this.messageId, required this.newContent});
}

/// Yêu cầu thả cảm xúc
class ToggleReactionEvent extends ChatEvent {
  final String messageId;
  final String emoji;
  ToggleReactionEvent({required this.messageId, required this.emoji});
}

/// Nhận cập nhật cảm xúc từ đối phương
class MessageReactionUpdatedEvent extends ChatEvent {
  final String messageId;
  final dynamic reactions; // Có thể là Map<String, dynamic>
  MessageReactionUpdatedEvent({required this.messageId, required this.reactions});
}

/// States cho ChatBloc
abstract class ChatState {}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}

/// Danh sách cuộc hội thoại
class ConversationsLoaded extends ChatState {
  final List<Map<String, dynamic>> conversations;
  ConversationsLoaded(this.conversations);
}

/// Tin nhắn của cuộc hội thoại
class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<Map<String, dynamic>> messages;
  final bool hasMore;
  final int currentPage;

  MessagesLoaded({
    required this.conversationId,
    required this.messages,
    this.hasMore = true,
    this.currentPage = 1,
  });

  MessagesLoaded copyWith({
    List<Map<String, dynamic>>? messages,
    bool? hasMore,
    int? currentPage,
  }) {
    return MessagesLoaded(
      conversationId: conversationId,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

/// Tin nhắn đã gửi thành công
class MessageSent extends ChatState {
  final Map<String, dynamic> message;
  MessageSent(this.message);
}

class ChatError extends ChatState {
  final String message;
  ChatError(this.message);
}

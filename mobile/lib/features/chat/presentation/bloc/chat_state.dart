/// States cho ChatBloc
abstract class ChatState {}

class ChatInitial extends ChatState {}
class ChatLoading extends ChatState {}

/// Danh sách cuộc hội thoại
class ConversationsLoaded extends ChatState {
  final List<Map<String, dynamic>> conversations;
  final List<String> onlineUserIds;
  ConversationsLoaded(this.conversations, {this.onlineUserIds = const []});

  ConversationsLoaded copyWith({
    List<Map<String, dynamic>>? conversations,
    List<String>? onlineUserIds,
  }) {
    return ConversationsLoaded(
      conversations ?? this.conversations,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
    );
  }
}

/// Tin nhắn của cuộc hội thoại
class MessagesLoaded extends ChatState {
  final String conversationId;
  final List<Map<String, dynamic>> messages;
  final bool hasMore;
  final int currentPage;
  final List<String> onlineUserIds;
  final Set<String> typingUsers;

  MessagesLoaded({
    required this.conversationId,
    required this.messages,
    this.hasMore = true,
    this.currentPage = 1,
    this.onlineUserIds = const [],
    this.typingUsers = const {},
  });

  MessagesLoaded copyWith({
    List<Map<String, dynamic>>? messages,
    bool? hasMore,
    int? currentPage,
    List<String>? onlineUserIds,
    Set<String>? typingUsers,
  }) {
    return MessagesLoaded(
      conversationId: conversationId,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      onlineUserIds: onlineUserIds ?? this.onlineUserIds,
      typingUsers: typingUsers ?? this.typingUsers,
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

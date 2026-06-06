import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/websocket_service.dart';
import '../../data/repositories/chat_repository_impl.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC quản lý chat: conversations, messages, gửi/nhận qua REST + WebSocket.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepositoryImpl _repository;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;
  
  List<String> _latestOnlineUsers = [];

  ChatBloc({
    required ChatRepositoryImpl repository,
    required WebSocketService wsService,
  })  : _repository = repository,
        _wsService = wsService,
        super(ChatInitial()) {
    on<LoadConversationsEvent>(_onLoadConversations);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveMessageEvent>(_onReceiveMessage);
    on<SendTypingEvent>(_onSendTyping);
    on<SendStopTypingEvent>(_onSendStopTyping);
    on<PeerTypingStatusEvent>(_onPeerTypingStatus);
    on<OnlineStatusReceivedEvent>(_onOnlineStatusReceived);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<EditMessageEvent>(_onEditMessage);
    on<MessageDeletedByPeerEvent>(_onMessageDeletedByPeer);
    on<MessageEditedByPeerEvent>(_onMessageEditedByPeer);
    on<ToggleReactionEvent>(_onToggleReaction);
    on<MessageReactionUpdatedEvent>(_onMessageReactionUpdated);

    // Lắng nghe tin nhắn realtime từ WebSocket
    _wsSubscription = _wsService.messages.listen((data) {
      if (data['type'] == 'chat_message') {
        final messageData = data['data'] as Map<String, dynamic>;
        add(ReceiveMessageEvent(message: messageData));
      } else if (data['type'] == 'typing') {
        add(PeerTypingStatusEvent(peerId: data['data']['senderId'], isTyping: true));
      } else if (data['type'] == 'stop_typing') {
        add(PeerTypingStatusEvent(peerId: data['data']['senderId'], isTyping: false));
      } else if (data['type'] == 'online_status') {
        final users = List<String>.from(data['data']['onlineUsers'] ?? []);
        add(OnlineStatusReceivedEvent(onlineUserIds: users));
      } else if (data['type'] == 'message_deleted') {
        add(MessageDeletedByPeerEvent(messageId: data['data']['messageId']));
      } else if (data['type'] == 'message_edited') {
        add(MessageEditedByPeerEvent(
          messageId: data['data']['messageId'],
          newContent: data['data']['content'],
        ));
      } else if (data['type'] == 'message_reaction_updated') {
        add(MessageReactionUpdatedEvent(
          messageId: data['data']['messageId'],
          reactions: data['data']['reactions'],
        ));
      }
    });
  }

  Future<void> _onLoadConversations(
    LoadConversationsEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ConversationsLoaded) {
      emit(ChatLoading());
    }
    try {
      final result = await _repository.getConversations();
      final conversations = _extractList(result);
      emit(ConversationsLoaded(conversations, onlineUserIds: _latestOnlineUsers));
    } on DioException catch (e) {
      if (state is! ConversationsLoaded) emit(ChatError(_extractError(e)));
    } catch (e) {
      if (state is! ConversationsLoaded) emit(ChatError('Không thể tải cuộc hội thoại.'));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! MessagesLoaded) {
      emit(ChatLoading());
    }
    try {
      final result = await _repository.getMessages(event.conversationId);
      final messages = _extractList(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = 1 < (pagination?['totalPages'] ?? 1);
      emit(MessagesLoaded(
        conversationId: event.conversationId,
        messages: messages,
        hasMore: hasMore,
        currentPage: 1,
        onlineUserIds: _latestOnlineUsers,
      ));
    } catch (e) {
      emit(ChatError('Không thể tải tin nhắn.'));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded || !currentState.hasMore) return;
    final nextPage = currentState.currentPage + 1;
    try {
      final result = await _repository.getMessages(
        event.conversationId,
        page: nextPage,
      );
      final olderMessages = _extractList(result);
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = nextPage < (pagination?['totalPages'] ?? 1);
      emit(currentState.copyWith(
        messages: [...currentState.messages, ...olderMessages],
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (_) {
      emit(currentState);
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final result = await _repository.sendMessage(
        event.conversationId,
        content: event.content,
        fileUrl: event.fileUrl,
      );
      final data = (result['data'] ?? result) as Map<String, dynamic>;
      
      // Lạc quan thêm luôn vào danh sách
      add(ReceiveMessageEvent(message: data));
    } catch (e) {
      emit(ChatError('Gửi tin nhắn thất bại.'));
    }
  }

  void _onReceiveMessage(
    ReceiveMessageEvent event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      // Kiểm tra trùng lặp
      final msgId = event.message['id'];
      final exists = currentState.messages.any((m) => m['id'] == msgId);
      if (!exists) {
        emit(currentState.copyWith(
          messages: [event.message, ...currentState.messages],
        ));
      }
    } else if (currentState is ConversationsLoaded) {
      // Background load để làm mới tin nhắn/unread count
      add(LoadConversationsEvent());
    }
  }

  void _onSendTyping(SendTypingEvent event, Emitter<ChatState> emit) {
    _wsService.send({
      'type': 'typing',
      'data': {'receiverId': event.targetId}
    });
  }

  void _onSendStopTyping(SendStopTypingEvent event, Emitter<ChatState> emit) {
    _wsService.send({
      'type': 'stop_typing',
      'data': {'receiverId': event.targetId}
    });
  }

  void _onPeerTypingStatus(PeerTypingStatusEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final newTypingUsers = Set<String>.from(currentState.typingUsers);
      if (event.isTyping) {
        newTypingUsers.add(event.peerId);
      } else {
        newTypingUsers.remove(event.peerId);
      }
      emit(currentState.copyWith(typingUsers: newTypingUsers));
    }
  }

  void _onOnlineStatusReceived(OnlineStatusReceivedEvent event, Emitter<ChatState> emit) {
    _latestOnlineUsers = event.onlineUserIds;
    final currentState = state;
    if (currentState is ConversationsLoaded) {
      emit(currentState.copyWith(onlineUserIds: _latestOnlineUsers));
    } else if (currentState is MessagesLoaded) {
      emit(currentState.copyWith(onlineUserIds: _latestOnlineUsers));
    }
  }

  Future<void> _onDeleteMessage(DeleteMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    try {
      await _repository.deleteMessage(event.messageId, type: event.type);
      // Cập nhật state nội bộ
      final newMessages = currentState.messages.map((m) {
        if (m['id'] == event.messageId) {
          if (event.type == 'for_everyone') {
            return {...m, 'is_deleted': true, 'content': null, 'file_url': null};
          } else {
            // for_me -> ẩn tin nhắn
            return {...m, 'hidden_for_me': true};
          }
        }
        return m;
      }).where((m) => m['hidden_for_me'] != true).toList();
      emit(currentState.copyWith(messages: newMessages));
    } catch (_) {}
  }

  Future<void> _onEditMessage(EditMessageEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    try {
      await _repository.editMessage(event.messageId, event.content);
      final newMessages = currentState.messages.map((m) {
        if (m['id'] == event.messageId) {
          return {...m, 'content': event.content, 'edited_at': DateTime.now().toIso8601String()};
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: newMessages));
    } catch (_) {}
  }

  void _onMessageDeletedByPeer(MessageDeletedByPeerEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final newMessages = currentState.messages.map((m) {
        if (m['id'] == event.messageId) {
          return {...m, 'is_deleted': true, 'content': null, 'file_url': null};
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: newMessages));
    }
  }

  void _onMessageEditedByPeer(MessageEditedByPeerEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final newMessages = currentState.messages.map((m) {
        if (m['id'] == event.messageId) {
          return {...m, 'content': event.newContent, 'edited_at': DateTime.now().toIso8601String()};
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: newMessages));
    }
  }

  Future<void> _onToggleReaction(ToggleReactionEvent event, Emitter<ChatState> emit) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    try {
      await _repository.toggleReaction(event.messageId, event.emoji);
      // Let websocket event handle UI update, or we can optimistcally update it here.
    } catch (_) {}
  }

  void _onMessageReactionUpdated(MessageReactionUpdatedEvent event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      final newMessages = currentState.messages.map((m) {
        if (m['id'] == event.messageId) {
          return {...m, 'reactions': event.reactions};
        }
        return m;
      }).toList();
      emit(currentState.copyWith(messages: newMessages));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> result) {
    final data = result['data'];
    if (data is List) return data.map((e) => e as Map<String, dynamic>).toList();
    return [];
  }

  String _extractError(DioException e) {
    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) return data['message'] as String? ?? 'Lỗi';
    } catch (_) {}
    return e.message ?? 'Đã có lỗi xảy ra';
  }
}

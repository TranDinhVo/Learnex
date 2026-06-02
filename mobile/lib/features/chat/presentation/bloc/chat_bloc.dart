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

    // Lắng nghe tin nhắn realtime từ WebSocket
    _wsSubscription = _wsService.messages.listen((data) {
      if (data['type'] == 'chat_message') {
        add(ReceiveMessageEvent(message: data['data'] as Map<String, dynamic>));
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
      emit(ConversationsLoaded(conversations));
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

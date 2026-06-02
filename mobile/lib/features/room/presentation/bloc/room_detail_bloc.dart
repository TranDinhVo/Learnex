import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/websocket_service.dart';
import '../../domain/room_repository.dart';
import '../../data/models/room_model.dart';
import 'room_detail_event.dart';
import 'room_detail_state.dart';

class RoomDetailBloc extends Bloc<RoomDetailEvent, RoomDetailState> {
  final RoomRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  RoomModel? _currentRoom;
  List<RoomMessageModel> _currentMessages = [];
  List<RoomMemberModel> _currentMembers = [];
  bool _hasMoreMessages = true;
  int _currentMessagePage = 1;

  List<RoomMemberModel> get currentMembers => _currentMembers;

  RoomDetailBloc({
    required RoomRepository repository,
    required WebSocketService wsService,
  })  : _repository = repository,
        _wsService = wsService,
        super(RoomDetailInitial()) {
    on<LoadRoomDetailEvent>(_onLoadRoomDetail);
    on<LoadMessagesEvent>(_onLoadMessages);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<ReceiveRealtimeMessageEvent>(_onReceiveRealtimeMessage);
    on<LoadMembersEvent>(_onLoadMembers);
    on<KickMemberEvent>(_onKickMember);
    on<InviteMemberEvent>(_onInviteMember);
    on<UpdateMemberRoleEvent>(_onUpdateMemberRole);
    on<MarkMessagesReadEvent>(_onMarkMessagesRead);
    on<ReceiveRoomActiveStatusEvent>(_onReceiveRoomActiveStatus);
    on<TransferOwnershipEvent>(_onTransferOwnership);
    on<LeaveRoomEvent>(_onLeaveRoom);
    on<DeleteRoomEvent>(_onDeleteRoom);
    on<YouWereKickedEvent>((event, emit) => emit(RoomDetailKicked()));

    // Listen to WebSocket
    _wsSubscription = _wsService.messages.listen((data) {
      try {
        final type = data['type']?.toString();
        final payload = data['data'] as Map<String, dynamic>;
        
        if (type == 'room_message') {
          final msg = RoomMessageModel.fromJson(payload);
          add(ReceiveRealtimeMessageEvent(msg));
        } else if (type == 'room_active_status') {
          final roomId = payload['roomId']?.toString();
          if (roomId == _currentRoom?.id) {
            final users = (payload['activeUsers'] as List?)?.map((e) => e.toString()).toList() ?? [];
            add(ReceiveRoomActiveStatusEvent(roomId: roomId!, activeUsers: users));
          }
        } else if (type == 'room_kicked') {
          final roomId = payload['roomId']?.toString();
          if (roomId == _currentRoom?.id) {
            add(YouWereKickedEvent());
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _onLoadRoomDetail(
    LoadRoomDetailEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    emit(RoomDetailLoading());
    try {
      _currentRoom = await _repository.getRoomById(event.roomId);
      emit(RoomDetailLoaded(_currentRoom!));
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      final result = await _repository.getMessages(event.roomId, page: 1);
      final messages = result['messages'] as List<RoomMessageModel>;
      final pagination = result['pagination'] as Map<String, dynamic>?;
      _hasMoreMessages = 1 < (pagination?['totalPages'] ?? 1);
      _currentMessagePage = 1;
      _currentMessages = messages;
      
      emit(MessagesLoaded(
        messages: _currentMessages,
        hasMore: _hasMoreMessages,
        currentPage: 1,
      ));
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    if (!_hasMoreMessages) return;
    
    final nextPage = _currentMessagePage + 1;
    try {
      final result = await _repository.getMessages(event.roomId, page: nextPage);
      final olderMessages = result['messages'] as List<RoomMessageModel>;
      final pagination = result['pagination'] as Map<String, dynamic>?;
      
      _hasMoreMessages = nextPage < (pagination?['totalPages'] ?? 1);
      _currentMessagePage = nextPage;
      _currentMessages = [..._currentMessages, ...olderMessages];
      
      emit(MessagesLoaded(
        messages: _currentMessages,
        hasMore: _hasMoreMessages,
        currentPage: nextPage,
      ));
    } catch (_) {
      // ignore
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      // Send via WS
      _wsService.send({
        'type': 'room_message',
        'data': {
          'roomId': event.roomId,
          'content': event.content,
          'fileUrl': event.fileUrl,
        }
      });
    } catch (e) {
      emit(RoomDetailError('Gửi tin nhắn thất bại'));
    }
  }

  void _onReceiveRealtimeMessage(
    ReceiveRealtimeMessageEvent event,
    Emitter<RoomDetailState> emit,
  ) {
    if (_currentRoom == null || event.message.roomId != _currentRoom!.id) return;
    
    final exists = _currentMessages.any((m) => m.id == event.message.id);
    if (!exists) {
      _currentMessages = [event.message, ..._currentMessages];
      emit(MessagesLoaded(
        messages: _currentMessages,
        hasMore: _hasMoreMessages,
        currentPage: _currentMessagePage,
      ));
    }
  }

  Future<void> _onLoadMembers(
    LoadMembersEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      final members = await _repository.getMembers(event.roomId);
      _currentMembers = members;
      emit(MembersLoaded(members));
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onKickMember(
    KickMemberEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.kickMember(event.roomId, event.userId);
      _currentMembers.removeWhere((m) => m.userId == event.userId);
      emit(MembersLoaded(List.from(_currentMembers)));
      emit(RoomDetailOperationSuccess('Đã kick thành viên'));
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onInviteMember(
    InviteMemberEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.inviteMember(event.roomId, event.userId);
      emit(RoomDetailOperationSuccess('Đã gửi lời mời'));
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onUpdateMemberRole(
    UpdateMemberRoleEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.updateMemberRole(event.roomId, event.userId, event.role);
      emit(RoomDetailOperationSuccess('Đã cập nhật vai trò'));
      add(LoadMembersEvent(event.roomId)); // reload
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onMarkMessagesRead(
    MarkMessagesReadEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.markMessagesRead(event.roomId, event.messageIds);
      // Notify WS
      _wsService.send({
        'type': 'room_message_read',
        'data': {
          'roomId': event.roomId,
          'messageIds': event.messageIds,
        }
      });
    } catch (_) {}
  }

  void _onReceiveRoomActiveStatus(
    ReceiveRoomActiveStatusEvent event,
    Emitter<RoomDetailState> emit,
  ) {
    if (_currentRoom == null || event.roomId != _currentRoom!.id) return;
    emit(RoomActiveStatusUpdate(event.activeUsers));
  }

  Future<void> _onTransferOwnership(
    TransferOwnershipEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.transferOwnership(event.roomId, event.newOwnerId);
      emit(RoomDetailOperationSuccess('Đã chuyển quyền chủ phòng'));
      add(LoadRoomDetailEvent(event.roomId)); // reload room to get new owner
      add(LoadMembersEvent(event.roomId)); // reload members
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoomEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.leaveRoom(event.roomId);
      emit(RoomDetailLeft());
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  Future<void> _onDeleteRoom(
    DeleteRoomEvent event,
    Emitter<RoomDetailState> emit,
  ) async {
    try {
      await _repository.deleteRoom(event.roomId);
      emit(RoomDetailDeleted());
    } catch (e) {
      emit(RoomDetailError(_extractError(e)));
    }
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  String _extractError(dynamic e) {
    if (e is DioException) {
      try {
        final data = e.response?.data;
        if (data is Map<String, dynamic>) return data['message'] as String? ?? 'Lỗi kết nối';
      } catch (_) {}
      return e.message ?? 'Đã có lỗi xảy ra';
    }
    return e.toString();
  }
}

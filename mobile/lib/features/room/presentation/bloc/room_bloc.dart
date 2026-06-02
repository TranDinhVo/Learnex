import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/websocket_service.dart';
import '../../domain/room_repository.dart';
import 'room_event.dart';
import 'room_state.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final RoomRepository _repository;
  final WebSocketService _wsService;
  StreamSubscription? _wsSubscription;

  RoomBloc({
    required RoomRepository repository,
    required WebSocketService wsService,
  })  : _repository = repository,
        _wsService = wsService,
        super(RoomInitial()) {
    on<LoadRoomsEvent>(_onLoadRooms);
    on<LoadMoreRoomsEvent>(_onLoadMoreRooms);
    on<CreateRoomEvent>(_onCreateRoom);
    on<UpdateRoomEvent>(_onUpdateRoom);
    on<JoinRoomEvent>(_onJoinRoom);
    on<LeaveRoomEvent>(_onLeaveRoom);
    on<DeleteRoomEvent>(_onDeleteRoom);

    // Listen to WebSocket for refresh triggers
    _wsSubscription = _wsService.messages.listen((data) {
      try {
        final type = data['type']?.toString();
        if (type == 'room_kicked' || type == 'room_deleted') {
          add(LoadRoomsEvent(isRefresh: true));
        }
      } catch (_) {}
    });
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadRooms(
    LoadRoomsEvent event,
    Emitter<RoomState> emit,
  ) async {
    if (event.isRefresh || state is! RoomsLoaded) {
      emit(RoomLoading());
    }
    try {
      final result = await _repository.getRooms(page: 1, search: event.searchQuery);
      final rooms = result['rooms'] as List<dynamic>;
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = 1 < (pagination?['totalPages'] ?? 1);
      
      emit(RoomsLoaded(
        rooms: rooms.cast(),
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(RoomError(_extractError(e)));
    }
  }

  Future<void> _onLoadMoreRooms(
    LoadMoreRoomsEvent event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    if (currentState is! RoomsLoaded || !currentState.hasMore) return;
    
    final nextPage = currentState.currentPage + 1;
    try {
      final result = await _repository.getRooms(page: nextPage);
      final olderRooms = result['rooms'] as List<dynamic>;
      final pagination = result['pagination'] as Map<String, dynamic>?;
      final hasMore = nextPage < (pagination?['totalPages'] ?? 1);
      
      emit(currentState.copyWith(
        rooms: [...currentState.rooms, ...olderRooms.cast()],
        hasMore: hasMore,
        currentPage: nextPage,
      ));
    } catch (_) {
      emit(currentState);
    }
  }

  Future<void> _onCreateRoom(
    CreateRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    try {
      await _repository.createRoom(
        event.name,
        description: event.description,
        privacyMode: event.privacyMode,
      );
      emit(RoomOperationSuccess('Tạo phòng thành công'));
      add(LoadRoomsEvent(isRefresh: true));
    } catch (e) {
      emit(RoomError(_extractError(e)));
      if (currentState is RoomsLoaded) emit(currentState);
    }
  }

  Future<void> _onUpdateRoom(
    UpdateRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    try {
      await _repository.updateRoom(
        event.id,
        name: event.name,
        description: event.description,
        privacyMode: event.privacyMode,
      );
      emit(RoomOperationSuccess('Cập nhật phòng thành công'));
      add(LoadRoomsEvent(isRefresh: true));
    } catch (e) {
      emit(RoomError(_extractError(e)));
      if (currentState is RoomsLoaded) emit(currentState);
    }
  }

  Future<void> _onJoinRoom(
    JoinRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    try {
      final message = await _repository.joinRoom(event.roomId);
      emit(RoomOperationSuccess(message));
      add(LoadRoomsEvent(isRefresh: true));
    } catch (e) {
      emit(RoomError(_extractError(e)));
      if (currentState is RoomsLoaded) emit(currentState);
    }
  }

  Future<void> _onLeaveRoom(
    LeaveRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    try {
      await _repository.leaveRoom(event.roomId);
      emit(RoomOperationSuccess('Đã rời phòng'));
      add(LoadRoomsEvent(isRefresh: true));
    } catch (e) {
      emit(RoomError(_extractError(e)));
      if (currentState is RoomsLoaded) emit(currentState);
    }
  }

  Future<void> _onDeleteRoom(
    DeleteRoomEvent event,
    Emitter<RoomState> emit,
  ) async {
    final currentState = state;
    try {
      await _repository.deleteRoom(event.roomId);
      emit(RoomOperationSuccess('Đã xóa phòng'));
      add(LoadRoomsEvent(isRefresh: true));
    } catch (e) {
      emit(RoomError(_extractError(e)));
      if (currentState is RoomsLoaded) emit(currentState);
    }
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

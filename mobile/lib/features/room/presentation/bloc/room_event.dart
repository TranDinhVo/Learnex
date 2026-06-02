abstract class RoomEvent {}

class LoadRoomsEvent extends RoomEvent {
  final bool isRefresh;
  final String? searchQuery;
  LoadRoomsEvent({this.isRefresh = false, this.searchQuery});
}

class LoadMoreRoomsEvent extends RoomEvent {}

class CreateRoomEvent extends RoomEvent {
  final String name;
  final String? description;
  final String privacyMode;
  
  CreateRoomEvent({
    required this.name,
    this.description,
    this.privacyMode = 'public',
  });
}

class JoinRoomEvent extends RoomEvent {
  final String roomId;
  JoinRoomEvent({required this.roomId});
}

class LeaveRoomEvent extends RoomEvent {
  final String roomId;
  LeaveRoomEvent({required this.roomId});
}

class DeleteRoomEvent extends RoomEvent {
  final String roomId;
  DeleteRoomEvent({required this.roomId});
}

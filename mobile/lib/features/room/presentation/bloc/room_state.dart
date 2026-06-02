import '../../data/models/room_model.dart';

abstract class RoomState {}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomsLoaded extends RoomState {
  final List<RoomModel> rooms;
  final bool hasMore;
  final int currentPage;

  RoomsLoaded({
    required this.rooms,
    this.hasMore = true,
    this.currentPage = 1,
  });

  RoomsLoaded copyWith({
    List<RoomModel>? rooms,
    bool? hasMore,
    int? currentPage,
  }) {
    return RoomsLoaded(
      rooms: rooms ?? this.rooms,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class RoomOperationSuccess extends RoomState {
  final String message;
  RoomOperationSuccess(this.message);
}

class RoomError extends RoomState {
  final String message;
  RoomError(this.message);
}

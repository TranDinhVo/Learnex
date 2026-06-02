import '../../data/models/room_model.dart';

abstract class RoomDetailState {}

class RoomDetailInitial extends RoomDetailState {}

class RoomDetailLoading extends RoomDetailState {}

class RoomDetailLoaded extends RoomDetailState {
  final RoomModel room;
  RoomDetailLoaded(this.room);
}

class MessagesLoaded extends RoomDetailState {
  final List<RoomMessageModel> messages;
  final bool hasMore;
  final int currentPage;

  MessagesLoaded({
    required this.messages,
    this.hasMore = true,
    this.currentPage = 1,
  });

  MessagesLoaded copyWith({
    List<RoomMessageModel>? messages,
    bool? hasMore,
    int? currentPage,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class MembersLoaded extends RoomDetailState {
  final List<RoomMemberModel> members;
  MembersLoaded(this.members);
}

class RoomActiveStatusUpdate extends RoomDetailState {
  final List<String> activeUsers;
  RoomActiveStatusUpdate(this.activeUsers);
}

class RoomDetailOperationSuccess extends RoomDetailState {
  final String message;
  RoomDetailOperationSuccess(this.message);
}

class RoomDetailError extends RoomDetailState {
  final String message;
  RoomDetailError(this.message);
}

class RoomDetailLeft extends RoomDetailState {}

class RoomDetailDeleted extends RoomDetailState {}

class RoomDetailKicked extends RoomDetailState {}

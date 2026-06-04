import '../../data/models/room_model.dart';

abstract class RoomDetailEvent {}

class LoadRoomDetailEvent extends RoomDetailEvent {
  final String roomId;
  LoadRoomDetailEvent(this.roomId);
}

class LoadMessagesEvent extends RoomDetailEvent {
  final String roomId;
  LoadMessagesEvent(this.roomId);
}

class LoadMoreMessagesEvent extends RoomDetailEvent {
  final String roomId;
  LoadMoreMessagesEvent(this.roomId);
}

class SendMessageEvent extends RoomDetailEvent {
  final String roomId;
  final String? content;
  final String? fileUrl;
  SendMessageEvent({required this.roomId, this.content, this.fileUrl});
}

class ReceiveRealtimeMessageEvent extends RoomDetailEvent {
  final RoomMessageModel message;
  ReceiveRealtimeMessageEvent(this.message);
}

class LoadMembersEvent extends RoomDetailEvent {
  final String roomId;
  LoadMembersEvent(this.roomId);
}

class KickMemberEvent extends RoomDetailEvent {
  final String roomId;
  final String userId;
  KickMemberEvent({required this.roomId, required this.userId});
}

class InviteMemberEvent extends RoomDetailEvent {
  final String roomId;
  final String userId;
  InviteMemberEvent({required this.roomId, required this.userId});
}

class UpdateMemberRoleEvent extends RoomDetailEvent {
  final String roomId;
  final String userId;
  final String role;
  UpdateMemberRoleEvent({required this.roomId, required this.userId, required this.role});
}

class MarkMessagesReadEvent extends RoomDetailEvent {
  final String roomId;
  final List<String> messageIds;
  MarkMessagesReadEvent({required this.roomId, required this.messageIds});
}

class ReceiveRoomActiveStatusEvent extends RoomDetailEvent {
  final String roomId;
  final List<String> activeUsers;
  ReceiveRoomActiveStatusEvent({required this.roomId, required this.activeUsers});
}

class TransferOwnershipEvent extends RoomDetailEvent {
  final String roomId;
  final String newOwnerId;
  TransferOwnershipEvent({required this.roomId, required this.newOwnerId});
}

class LeaveRoomEvent extends RoomDetailEvent {
  final String roomId;
  LeaveRoomEvent(this.roomId);
}

class DeleteRoomEvent extends RoomDetailEvent {
  final String roomId;
  DeleteRoomEvent(this.roomId);
}

class YouWereKickedEvent extends RoomDetailEvent {}

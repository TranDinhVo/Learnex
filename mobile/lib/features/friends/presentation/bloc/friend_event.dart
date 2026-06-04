/// Events cho FriendBloc
abstract class FriendEvent {}

class LoadFriendsEvent extends FriendEvent {}
class LoadFriendRequestsEvent extends FriendEvent {}
class LoadSuggestionsEvent extends FriendEvent {}

class SendFriendRequestEvent extends FriendEvent {
  final String userId;
  SendFriendRequestEvent({required this.userId});
}

class CancelFriendRequestEvent extends FriendEvent {
  final String userId;
  CancelFriendRequestEvent({required this.userId});
}

class AcceptFriendRequestEvent extends FriendEvent {
  final String requestId;
  AcceptFriendRequestEvent({required this.requestId});
}

class RejectFriendRequestEvent extends FriendEvent {
  final String requestId;
  RejectFriendRequestEvent({required this.requestId});
}

class UnfriendEvent extends FriendEvent {
  final String userId;
  UnfriendEvent({required this.userId});
}

class SearchUsersEvent extends FriendEvent {
  final String query;
  SearchUsersEvent({required this.query});
}

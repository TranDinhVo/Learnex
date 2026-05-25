/// States cho FriendBloc
abstract class FriendState {}

class FriendInitial extends FriendState {}
class FriendLoading extends FriendState {}

class FriendsLoaded extends FriendState {
  final List<Map<String, dynamic>> friends;
  FriendsLoaded(this.friends);
}

class FriendRequestsLoaded extends FriendState {
  final List<Map<String, dynamic>> requests;
  FriendRequestsLoaded(this.requests);
}

class FriendError extends FriendState {
  final String message;
  FriendError(this.message);
}

class FriendRequestSent extends FriendState {}
class FriendRequestAccepted extends FriendState {}
class FriendRequestRejected extends FriendState {}
class Unfriended extends FriendState {}

class UserSearchResults extends FriendState {
  final List<Map<String, dynamic>> users;
  UserSearchResults(this.users);
}

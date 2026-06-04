import '../../domain/repositories/friend_repository.dart';
import '../datasources/friend_remote_datasource.dart';

class FriendRepositoryImpl implements FriendRepository {
  final FriendRemoteDatasource _datasource;

  FriendRepositoryImpl({required FriendRemoteDatasource datasource})
      : _datasource = datasource;

  @override
  Future<Map<String, dynamic>> getFriends({int page = 1, int limit = 20}) =>
      _datasource.getFriends(page: page, limit: limit);

  @override
  Future<Map<String, dynamic>> getRequests() => _datasource.getRequests();

  @override
  Future<Map<String, dynamic>> getFriendshipStatus(String userId) =>
      _datasource.getFriendshipStatus(userId);

  @override
  Future<Map<String, dynamic>> sendRequest(String userId) =>
      _datasource.sendRequest(userId);

  @override
  Future<void> acceptRequest(String requestId) =>
      _datasource.acceptRequest(requestId);

  @override
  Future<void> rejectRequest(String requestId) =>
      _datasource.rejectRequest(requestId);

  @override
  Future<void> unfriend(String userId) => _datasource.unfriend(userId);

  @override
  Future<Map<String, dynamic>> searchUsers(String query) =>
      _datasource.searchUsers(query);

  @override
  Future<Map<String, dynamic>> getSuggestions({int page = 1, int limit = 20}) =>
      _datasource.getSuggestions(page: page, limit: limit);
}

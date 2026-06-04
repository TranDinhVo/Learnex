/// Abstract repository cho Friends feature.
abstract class FriendRepository {
  Future<Map<String, dynamic>> getFriends({int page, int limit});
  Future<Map<String, dynamic>> getRequests();
  Future<Map<String, dynamic>> getFriendshipStatus(String userId);
  Future<Map<String, dynamic>> sendRequest(String userId);
  Future<void> acceptRequest(String requestId);
  Future<void> rejectRequest(String requestId);
  Future<void> unfriend(String userId);
  Future<Map<String, dynamic>> searchUsers(String query);
  Future<Map<String, dynamic>> getSuggestions({int page, int limit});
}

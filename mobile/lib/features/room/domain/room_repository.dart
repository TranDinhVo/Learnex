import '../data/models/room_model.dart';

abstract class RoomRepository {
  Future<Map<String, dynamic>> getRooms({int page = 1, int limit = 20, String? search});
  Future<RoomModel> getRoomById(String id);
  Future<RoomModel> createRoom(String name, {String? description, String privacyMode = 'public'});
  Future<RoomModel> updateRoom(String id, {String? name, String? description, String? privacyMode});
  Future<void> deleteRoom(String id);
  
  Future<String> joinRoom(String id);
  Future<void> leaveRoom(String id);
  
  Future<List<RoomMemberModel>> getMembers(String id);
  Future<void> kickMember(String roomId, String userId);
  Future<void> inviteMember(String roomId, String userId);
  Future<void> updateMemberRole(String roomId, String userId, String role);
  Future<void> transferOwnership(String roomId, String newOwnerId);
  
  Future<Map<String, dynamic>> getMessages(String roomId, {int page = 1, int limit = 50});
  Future<void> markMessagesRead(String roomId, List<String> messageIds);
  Future<Map<String, dynamic>> getReadReceipts(String roomId, List<String> messageIds);
  
  Future<List<dynamic>> getJoinRequests(String roomId);
  Future<void> approveJoinRequest(String roomId, String userId);
  Future<void> rejectJoinRequest(String roomId, String userId);
}

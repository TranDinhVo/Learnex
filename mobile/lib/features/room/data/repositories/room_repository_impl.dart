import '../datasources/room_remote_datasource.dart';
import '../models/room_model.dart';
import '../../domain/room_repository.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDatasource _datasource;

  RoomRepositoryImpl({required RoomRemoteDatasource datasource}) : _datasource = datasource;

  @override
  Future<Map<String, dynamic>> getRooms({int page = 1, int limit = 20, String? search}) async {
    final result = await _datasource.getRooms(page: page, limit: limit, search: search);
    final data = result['data'] as List;
    final rooms = data.map((e) => RoomModel.fromJson(e)).toList();
    return {
      'rooms': rooms,
      'pagination': result['pagination'],
    };
  }

  @override
  Future<RoomModel> getRoomById(String id) async {
    final result = await _datasource.getRoomById(id);
    return RoomModel.fromJson(result['data']);
  }

  @override
  Future<RoomModel> createRoom(String name, {String? description, String privacyMode = 'public'}) async {
    final result = await _datasource.createRoom({
      'name': name,
      'description': description,
      'privacy_mode': privacyMode,
    });
    return RoomModel.fromJson(result['data']);
  }

  @override
  Future<RoomModel> updateRoom(String id, {String? name, String? description, String? privacyMode}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (description != null) data['description'] = description;
    if (privacyMode != null) data['privacy_mode'] = privacyMode;
    
    final result = await _datasource.updateRoom(id, data);
    return RoomModel.fromJson(result['data']);
  }

  @override
  Future<void> deleteRoom(String id) async {
    await _datasource.deleteRoom(id);
  }

  @override
  Future<String> joinRoom(String id) async {
    final result = await _datasource.joinRoom(id);
    if (result['data'] != null && result['data'] is Map && result['data']['status'] == 'pending') {
      return 'Yêu cầu tham gia đã được gửi và đang chờ duyệt';
    }
    return 'Tham gia phòng thành công';
  }

  @override
  Future<void> leaveRoom(String id) async {
    await _datasource.leaveRoom(id);
  }

  @override
  Future<List<RoomMemberModel>> getMembers(String id) async {
    final result = await _datasource.getMembers(id);
    final data = result['data'] as List;
    return data.map((e) => RoomMemberModel.fromJson(e)).toList();
  }

  @override
  Future<void> kickMember(String roomId, String userId) async {
    await _datasource.kickMember(roomId, userId);
  }

  @override
  Future<void> inviteMember(String roomId, String userId) async {
    await _datasource.inviteMember(roomId, userId);
  }

  @override
  Future<void> transferOwnership(String roomId, String newOwnerId) async {
    await _datasource.transferOwnership(roomId, newOwnerId);
  }

  @override
  Future<void> updateMemberRole(String roomId, String userId, String role) async {
    await _datasource.updateMemberRole(roomId, userId, role);
  }

  @override
  Future<Map<String, dynamic>> getMessages(String roomId, {int page = 1, int limit = 50}) async {
    final result = await _datasource.getMessages(roomId, page: page, limit: limit);
    final data = result['data'] as List;
    final messages = data.map((e) => RoomMessageModel.fromJson(e)).toList();
    return {
      'messages': messages,
      'pagination': result['pagination'],
    };
  }

  @override
  Future<void> markMessagesRead(String roomId, List<String> messageIds) async {
    await _datasource.markMessagesRead(roomId, messageIds);
  }

  @override
  Future<Map<String, dynamic>> getReadReceipts(String roomId, List<String> messageIds) async {
    final result = await _datasource.getReadReceipts(roomId, messageIds);
    return result['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<dynamic>> getJoinRequests(String roomId) async {
    final result = await _datasource.getJoinRequests(roomId);
    return (result['data'] as List).cast<dynamic>();
  }

  @override
  Future<void> approveJoinRequest(String roomId, String userId) async {
    await _datasource.approveJoinRequest(roomId, userId);
  }

  @override
  Future<void> rejectJoinRequest(String roomId, String userId) async {
    await _datasource.rejectJoinRequest(roomId, userId);
  }
}

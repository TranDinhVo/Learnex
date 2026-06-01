import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

class RoomRemoteDatasource {
  final Dio _dio;

  RoomRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> getRooms({int page = 1, int limit = 20, String? search}) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    final response = await _dio.get(
      ApiEndpoints.rooms,
      queryParameters: query,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getRoomById(String id) async {
    final response = await _dio.get(ApiEndpoints.roomById(id));
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiEndpoints.rooms, data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateRoom(String id, Map<String, dynamic> data) async {
    final response = await _dio.put(ApiEndpoints.roomById(id), data: data);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteRoom(String id) async {
    await _dio.delete(ApiEndpoints.roomById(id));
  }

  Future<Map<String, dynamic>> joinRoom(String id) async {
    final response = await _dio.post(ApiEndpoints.joinRoom(id));
    return response.data as Map<String, dynamic>;
  }

  Future<void> leaveRoom(String id) async {
    await _dio.post(ApiEndpoints.leaveRoom(id));
  }

  Future<Map<String, dynamic>> getMembers(String id) async {
    final response = await _dio.get(ApiEndpoints.roomMembers(id));
    return response.data as Map<String, dynamic>;
  }

  Future<void> kickMember(String roomId, String userId) async {
    await _dio.post(
      '${ApiEndpoints.rooms}/$roomId/kick',
      data: {'userId': userId},
    );
  }

  Future<void> inviteMember(String roomId, String userId) async {
    await _dio.post(
      '${ApiEndpoints.rooms}/$roomId/invite',
      data: {'userId': userId},
    );
  }

  Future<void> transferOwnership(String roomId, String newOwnerId) async {
    await _dio.post(
      '${ApiEndpoints.rooms}/$roomId/transfer-ownership',
      data: {'newOwnerId': newOwnerId},
    );
  }

  Future<void> updateMemberRole(String roomId, String userId, String role) async {
    await _dio.put(
      ApiEndpoints.roomMemberRole(roomId, userId),
      data: {'role': role},
    );
  }

  Future<Map<String, dynamic>> getMessages(String roomId, {int page = 1, int limit = 50}) async {
    final response = await _dio.get(
      ApiEndpoints.roomMessages(roomId),
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> markMessagesRead(String roomId, List<String> messageIds) async {
    await _dio.post(
      ApiEndpoints.markRoomMessagesRead(roomId),
      data: {'messageIds': messageIds},
    );
  }

  Future<Map<String, dynamic>> getReadReceipts(String roomId, List<String> messageIds) async {
    final response = await _dio.get(
      '${ApiEndpoints.rooms}/$roomId/messages/read-receipts',
      queryParameters: {'messageIds': messageIds.join(',')},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getJoinRequests(String roomId) async {
    final response = await _dio.get('${ApiEndpoints.rooms}/$roomId/requests');
    return response.data as Map<String, dynamic>;
  }

  Future<void> approveJoinRequest(String roomId, String userId) async {
    await _dio.post('${ApiEndpoints.rooms}/$roomId/requests/$userId/approve');
  }

  Future<void> rejectJoinRequest(String roomId, String userId) async {
    await _dio.post('${ApiEndpoints.rooms}/$roomId/requests/$userId/reject');
  }
}

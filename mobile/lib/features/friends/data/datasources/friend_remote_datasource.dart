import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';

/// Remote datasource cho Friends feature.
class FriendRemoteDatasource {
  final Dio _dio;

  FriendRemoteDatasource(this._dio);

  /// Lấy danh sách bạn bè
  Future<Map<String, dynamic>> getFriends({int page = 1, int limit = 20}) async {
    final response = await _dio.get(
      ApiEndpoints.friends,
      queryParameters: {'page': page, 'limit': limit},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Lấy danh sách lời mời kết bạn
  Future<Map<String, dynamic>> getRequests() async {
    final response = await _dio.get(ApiEndpoints.friendRequests);
    return response.data as Map<String, dynamic>;
  }

  /// Kiểm tra trạng thái quan hệ bạn bè
  Future<Map<String, dynamic>> getFriendshipStatus(String userId) async {
    final response = await _dio.get(ApiEndpoints.friendshipStatus(userId));
    return response.data as Map<String, dynamic>;
  }

  /// Gửi lời mời kết bạn
  Future<Map<String, dynamic>> sendRequest(String userId) async {
    final response = await _dio.post(ApiEndpoints.sendFriendRequest(userId));
    return response.data as Map<String, dynamic>;
  }

  /// Chấp nhận lời mời
  Future<void> acceptRequest(String requestId) async {
    await _dio.put(ApiEndpoints.acceptFriendRequest(requestId));
  }

  /// Từ chối lời mời
  Future<void> rejectRequest(String requestId) async {
    await _dio.put(ApiEndpoints.rejectFriendRequest(requestId));
  }

  /// Huỷ kết bạn
  Future<void> unfriend(String userId) async {
    await _dio.delete(ApiEndpoints.unfriend(userId));
  }

  /// Tìm kiếm người dùng
  Future<Map<String, dynamic>> searchUsers(String query) async {
    final response = await _dio.get(
      ApiEndpoints.searchUsers,
      queryParameters: {'q': query},
    );
    return response.data as Map<String, dynamic>;
  }
}

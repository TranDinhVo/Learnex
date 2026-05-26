import 'package:dio/dio.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/user.dart';

/// Remote datasource gọi API auth qua Dio.
class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  /// Đăng nhập, trả về {accessToken, refreshToken, user}
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.register,
      data: {
        'email': email,
        'password': password,
        'full_name': fullName,
        'username': username,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// Quên mật khẩu — gửi OTP qua email
  Future<void> forgotPassword({required String email}) async {
    await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  /// Xác minh OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      ApiEndpoints.verifyOtp,
      data: {'email': email, 'otp': otp},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Đặt lại mật khẩu bằng reset token
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _dio.post(
      ApiEndpoints.resetPassword,
      data: {'resetToken': resetToken, 'newPassword': newPassword},
    );
  }

  /// Đổi mật khẩu (đã đăng nhập)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  /// Lấy thông tin user hiện tại
  Future<User> getMe() async {
    final response = await _dio.get(ApiEndpoints.me);
    final data = response.data['data'] ?? response.data;
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Cập nhật thông tin profile
  Future<User> updateProfile({
    String? fullName,
    String? bio,
    String? school,
    String? major,
  }) async {
    final response = await _dio.put(
      ApiEndpoints.updateProfile,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (bio != null) 'bio': bio,
        if (school != null) 'school': school,
        if (major != null) 'major': major,
      },
    );
    final data = response.data['data'] ?? response.data;
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Upload avatar mới
  Future<User> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.put(
      ApiEndpoints.uploadAvatar,
      data: formData,
    );
    final data = response.data['data'] ?? response.data;
    return User.fromJson(data as Map<String, dynamic>);
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await _dio.post(
      ApiEndpoints.refreshToken,
      data: {'refreshToken': refreshToken},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Đăng xuất
  Future<void> logout(String refreshToken) async {
    await _dio.post(
      ApiEndpoints.logout,
      data: {'refreshToken': refreshToken},
    );
  }

  /// Lấy chi tiết thông tin người dùng bất kỳ theo ID
  Future<User> getUserById(String id) async {
    final response = await _dio.get(ApiEndpoints.userById(id));
    final data = response.data['data'] ?? response.data;
    return User.fromJson(data as Map<String, dynamic>);
  }
}

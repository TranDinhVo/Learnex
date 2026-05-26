import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/network/api_interceptor.dart';
import '../../domain/entities/user.dart';
import '../datasources/auth_remote_datasource.dart';

/// Repository thực thi auth logic:
/// - Gọi datasource
/// - Lưu/xoá JWT trong SecureStorage
class AuthRepositoryImpl {
  final AuthRemoteDatasource _datasource;
  final FlutterSecureStorage _storage;

  AuthRepositoryImpl({
    required AuthRemoteDatasource datasource,
    required FlutterSecureStorage storage,
  })  : _datasource = datasource,
        _storage = storage;

  /// Đăng nhập: lưu token, trả về User
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final result = await _datasource.login(
      email: email,
      password: password,
    );

    // Lưu token pair
    final data = result['data'] ?? result;
    await _saveTokens(data);

    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Đăng ký: lưu token, trả về User
  Future<User> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    final result = await _datasource.register(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
    );

    final data = result['data'] ?? result;
    await _saveTokens(data);

    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Quên mật khẩu
  Future<void> forgotPassword({required String email}) async {
    await _datasource.forgotPassword(email: email);
  }

  /// Xác minh OTP, trả về resetToken
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final result = await _datasource.verifyOtp(email: email, otp: otp);
    final data = result['data'] ?? result;
    return data['resetToken'] as String;
  }

  /// Đặt lại mật khẩu
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _datasource.resetPassword(
      resetToken: resetToken,
      newPassword: newPassword,
    );
  }

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _datasource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Lấy thông tin user hiện tại
  Future<User> getMe() async {
    return await _datasource.getMe();
  }

  /// Cập nhật profile
  Future<User> updateProfile({
    String? fullName,
    String? bio,
    String? school,
    String? major,
  }) async {
    return await _datasource.updateProfile(
      fullName: fullName,
      bio: bio,
      school: school,
      major: major,
    );
  }

  /// Upload avatar
  Future<User> uploadAvatar(String filePath) async {
    return await _datasource.uploadAvatar(filePath);
  }

  /// Đăng xuất: gọi API + xoá token local
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.read(
        key: StorageKeys.refreshToken,
      );
      if (refreshToken != null) {
        await _datasource.logout(refreshToken);
      }
    } catch (_) {
      // Luôn xoá token dù API call thất bại
    } finally {
      await _clearTokens();
    }
  }

  /// Kiểm tra xem user đã đăng nhập chưa (có token lưu sẵn)
  Future<bool> hasStoredToken() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Helpers ──

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final tokens = data['tokens'] as Map<String, dynamic>?;
    final accessToken = tokens != null ? tokens['accessToken'] as String? : data['accessToken'] as String?;
    final refreshToken = tokens != null ? tokens['refreshToken'] as String? : data['refreshToken'] as String?;
    if (accessToken != null) {
      await _storage.write(
        key: StorageKeys.accessToken,
        value: accessToken,
      );
    }
    if (refreshToken != null) {
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: refreshToken,
      );
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }

  /// Lấy chi tiết thông tin người dùng theo ID
  Future<User> getUserById(String id) async {
    return await _datasource.getUserById(id);
  }
}

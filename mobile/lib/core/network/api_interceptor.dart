import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Key lưu trữ token trong SecureStorage
class StorageKeys {
  const StorageKeys._();
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}

/// Interceptor tự động gắn JWT vào header Authorization.
/// Khi nhận 401 Unauthorized → xoá token đã lưu.
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Đọc access token từ SecureStorage
    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Chỉ set Content-Type = application/json cho request KHÔNG phải FormData.
    // Với FormData (upload file), để Dio tự set 'multipart/form-data; boundary=...'
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token hết hạn hoặc không hợp lệ → xoá token
      await _storage.delete(key: StorageKeys.accessToken);
      await _storage.delete(key: StorageKeys.refreshToken);
    }
    handler.next(err);
  }
}

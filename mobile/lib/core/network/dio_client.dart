import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_interceptor.dart';

/// Factory tạo Dio instance đã được cấu hình sẵn.
///
/// Base URL mặc định: http://10.0.2.2:8080/api (Android emulator → localhost).
/// Trên thiết bị thật, truyền [baseUrl] phù hợp.
class DioClient {
  const DioClient._();

  /// Base URL mặc định cho Android emulator
  static const String _defaultBaseUrl = 'http://10.0.2.2:8080/api';

  /// Tạo Dio instance với interceptor Auth + Log.
  static Dio create({
    required FlutterSecureStorage storage,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Thứ tự interceptor: Auth trước, Log sau
    dio.interceptors.addAll([
      AuthInterceptor(storage),
      LogInterceptor(
        request: true,
        requestHeader: false,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    ]);

    return dio;
  }
}

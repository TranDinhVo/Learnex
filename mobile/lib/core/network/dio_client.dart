import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_interceptor.dart';

/// Factory tạo Dio instance đã được cấu hình sẵn.
///
/// Base URL mặc định: http://10.0.2.2:8080/api (Android emulator → localhost).
/// Trên thiết bị thật, truyền [baseUrl] phù hợp.
class DioClient {
  const DioClient._();

  /// Base URL mặc định tự động nhận diện nền tảng
  static String get _defaultBaseUrl {
    return 'https://learnex-backend-40yr.onrender.com/api';
  }

  /// Tạo Dio instance với interceptor Auth + Log.
  static Dio create({
    required FlutterSecureStorage storage,
    String? baseUrl,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl ?? _defaultBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout:
            const Duration(seconds: 120), // upload cần thời gian dài hơn
        sendTimeout:
            const Duration(seconds: 120), // upload cần thời gian dài hơn
        // QUAN TRỌNG: Không đặt Content-Type cứng ở đây!
        // Khi gửi FormData (multipart), Dio sẽ tự động set 'multipart/form-data; boundary=...'
        // Nếu set cứng 'application/json' thì server không parse được file.
        headers: {
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

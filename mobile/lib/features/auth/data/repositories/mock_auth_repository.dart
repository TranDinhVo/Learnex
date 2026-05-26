import 'package:dio/dio.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../feed/data/repositories/mock_feed_repository.dart';

class MockAuthRepository implements AuthRepository {
  // Static Dio instance for simple, unified API client
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8080/api',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Static variable to store access token in memory
  static String? userToken;

  @override
  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final resData = response.data;
        final innerData = resData['data'] ?? resData;
        final tokens = innerData['tokens'];
        if (tokens != null) {
          userToken = tokens['accessToken'] as String?;
          if (userToken != null) {
            _dio.options.headers['Authorization'] = 'Bearer $userToken';
            // Share the token with MockFeedRepository
            MockFeedRepository.setToken(userToken!);
          }
        }
        return true;
      }
      throw Exception('Đăng nhập thất bại: ${response.statusMessage}');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Không thể kết nối đến máy chủ';
      throw Exception(errorMsg);
    }
  }

  @override
  Future<bool> register(String email, String username, String password) async {
    try {
      // Automatic username extraction from email since the Flutter Register screen passes:
      // email -> email, username -> full_name, password -> password
      final parts = email.split('@');
      final emailPrefix = parts[0].replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
      final safeUsername = emailPrefix.isEmpty ? 'user_${DateTime.now().millisecondsSinceEpoch}' : emailPrefix;

      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'full_name': username, // Full name typed by the user
        'username': safeUsername, // Auto generated clean alphanumeric username
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      throw Exception('Đăng ký thất bại: ${response.statusMessage}');
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Không thể kết nối đến máy chủ';
      throw Exception(errorMsg);
    }
  }
}

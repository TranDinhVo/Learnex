import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../network/api_endpoints.dart';

/// Dịch vụ Firebase Cloud Messaging:
/// - Yêu cầu quyền thông báo
/// - Lắng nghe thông báo khi app ở foreground, background, terminated
/// - Lấy và đăng ký FCM token với server
class NotificationService {
  FirebaseMessaging? _messaging;
  final Dio _dio;

  final _foregroundController = StreamController<RemoteMessage>.broadcast();

  /// Stream nhận thông báo khi app đang mở (foreground)
  Stream<RemoteMessage> get onForegroundMessage => _foregroundController.stream;

  NotificationService({
    required Dio dio,
    FirebaseMessaging? messaging,
  })  : _messaging = messaging,
        _dio = dio;

  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint("FCM is disabled on Web to prevent Firebase crash.");
      return;
    }

    try {
      _messaging ??= FirebaseMessaging.instance;

      // 1. Yêu cầu quyền thông báo
      await requestPermission();

      // 2. Lắng nghe foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        _foregroundController.add(message);
      });

      // 3. Lắng nghe khi user tap vào notification (app ở background)
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        // Xử lý navigation dựa trên message.data
        _handleMessageOpenedApp(message);
      });

      // 4. Lấy và đăng ký FCM token
      await _registerToken();

      // 5. Theo dõi khi token thay đổi
      _messaging?.onTokenRefresh.listen((newToken) {
        _sendTokenToServer(newToken);
      });
    } catch (e) {
      debugPrint("NotificationService initialization failed: $e");
    }
  }

  /// Xin quyền thông báo từ người dùng
  Future<NotificationSettings?> requestPermission() async {
    if (_messaging == null) return null;
    return await _messaging!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
  }

  /// Lấy FCM token hiện tại
  Future<String?> getToken() async {
    if (_messaging == null) return null;
    return await _messaging!.getToken();
  }

  Future<void> _registerToken() async {
    final token = await getToken();
    if (token != null) {
      await _sendTokenToServer(token);
    }
  }

  Future<void> _sendTokenToServer(String fcmToken) async {
    try {
      await _dio.post(
        ApiEndpoints.registerFcmToken,
        data: {'fcm_token': fcmToken},
      );
    } catch (_) {
      // Bỏ qua lỗi đăng ký token — sẽ retry lần sau
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // TODO: Xử lý navigation dựa trên message.data['ref_type'] và message.data['ref_id']
    // Ví dụ: mở post detail, chat, friend request, ...
  }

  void dispose() {
    _foregroundController.close();
  }
}

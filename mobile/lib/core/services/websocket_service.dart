import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/api_interceptor.dart';
import 'audio_service.dart';

/// Dịch vụ WebSocket: kết nối, nhận message qua stream,
/// tự động reconnect với exponential backoff (1s → 2s → 4s → max 30s).
class WebSocketService {
  final FlutterSecureStorage _storage;
  final String _baseWsUrl;
  final AudioService _audioService;

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStateController = StreamController<bool>.broadcast();

  /// Stream nhận tất cả các message từ server
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  /// Stream theo dõi trạng thái kết nối
  Stream<bool> get connectionState => _connectionStateController.stream;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  int _reconnectAttempts = 0;
  static const int _maxBackoffSeconds = 30;

  // Mặc định ws URL tự động nhận diện nền tảng
  static String get _defaultWsUrl {
    return 'wss://learnex-backend-40yr.onrender.com/api';
  }

  WebSocketService({
    required FlutterSecureStorage storage,
    required AudioService audioService,
    String? baseWsUrl,
  })  : _storage = storage,
        _audioService = audioService,
        _baseWsUrl = baseWsUrl ?? _defaultWsUrl;

  /// Kết nối WebSocket với JWT token
  Future<void> connect() async {
    if (_isConnected) return;

    final token = await _storage.read(key: StorageKeys.accessToken);
    if (token == null || token.isEmpty) return;

    try {
      final uri = Uri.parse('$_baseWsUrl/ws?token=$token');
      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStateController.add(true);

      // Bắt đầu heartbeat mỗi 25 giây
      _startHeartbeat();
    } catch (e) {
      _onError(e);
    }
  }

  /// Gửi message đến server
  void send(Map<String, dynamic> data) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
    }
  }

  /// Ngắt kết nối thủ công (không reconnect)
  void disconnect() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
    _connectionStateController.add(false);
  }

  void _onMessage(dynamic message) {
    try {
      if (message is String) {
        final data = jsonDecode(message) as Map<String, dynamic>;

        // Xử lý pong heartbeat
        if (data['type'] == 'pong') return;

        // Xử lý âm thanh
        switch (data['type']) {
          case 'chat_message':
          case 'room_message':
            // Phát âm thanh khi nhận tin nhắn
            _audioService.playMessageSound();
            break;
          case 'private_call_invite':
          case 'room_call_invite':
            // Bắt đầu đổ chuông
            _audioService.startRingtone();
            break;
          case 'private_call_accept':
          case 'private_call_reject':
          case 'private_call_end':
          case 'user_joined_call':
          case 'leave_call':
          case 'user_left_call':
            // Dừng chuông khi có phản hồi cuộc gọi
            _audioService.stopRingtone();
            break;
        }

        _messageController.add(data);
      }
    } catch (_) {
      // Bỏ qua message không parse được
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _connectionStateController.add(false);
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    _isConnected = false;
    _connectionStateController.add(false);
    _heartbeatTimer?.cancel();
    _scheduleReconnect();
  }

  /// Exponential backoff: 1s → 2s → 4s → 8s → ... → max 30s
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    final backoff = min(
      pow(2, _reconnectAttempts).toInt(),
      _maxBackoffSeconds,
    );
    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: backoff), () {
      connect();
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      send({'type': 'ping'});
    });
  }

  /// Giải phóng tài nguyên
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}

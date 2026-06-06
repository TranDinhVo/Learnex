import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dịch vụ phát âm thanh thông báo và rung cho chat/calls
/// - Chat: Âm thanh beep ngắn + rung 200ms
/// - Call: Ringtone liên tục + rung 500ms
class AudioNotificationService {
  static final AudioNotificationService _instance = AudioNotificationService._();
  
  factory AudioNotificationService() {
    return _instance;
  }

  AudioNotificationService._();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlayingRingtone = false;

  /// Phát âm thanh + rung khi có tin nhắn mới
  Future<void> playMessageNotification() async {
    try {
      // Rung điện thoại 200ms - 2 lần
      await _vibrate(duration: 200, times: 2);
      
      // Phát âm thanh beep ngắn từ assets hoặc system sound
      // Dùng system notification sound (mặc định)
      await _audioPlayer.play(
        AssetSource('sounds/message_notification.wav'),
        volume: 0.8,
      );
    } catch (e) {
      // Nếu không có file sound, chỉ rung
      debugPrint('Error playing message notification: $e');
      await _vibrate(duration: 200, times: 2);
    }
  }

  /// Phát ringtone + rung liên tục khi có cuộc gọi đến
  Future<void> playIncomingCallRingtone() async {
    if (_isPlayingRingtone) return;
    
    try {
      _isPlayingRingtone = true;
      
      // Bắt đầu rung liên tục
      await _startContinuousVibration();
      
      // Phát ringtone liên tục
      await _audioPlayer.play(
        AssetSource('sounds/incoming_call_ringtone.wav'),
        volume: 1.0,
      );
      
      // Đặt loop để ringtone lặp lại
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    } catch (e) {
      debugPrint('Error playing incoming call ringtone: $e');
      await _startContinuousVibration();
    }
  }

  /// Dừng ringtone và rung
  Future<void> stopIncomingCallRingtone() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      _isPlayingRingtone = false;
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error stopping ringtone: $e');
    }
  }

  /// Rung điện thoại với thời gian (ms) và số lần
  Future<void> _vibrate({
    required int duration,
    int times = 1,
  }) async {
    try {
      for (int i = 0; i < times; i++) {
        if (i > 0) {
          // Nghỉ 100ms giữa các lần rung
          await Future.delayed(const Duration(milliseconds: 100));
        }
        await HapticFeedback.vibrate();
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }
  }

  /// Rung liên tục cho incoming call
  Future<void> _startContinuousVibration() async {
    try {
      // Rung pattern: 500ms on, 500ms off
      while (_isPlayingRingtone) {
        await HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      debugPrint('Continuous vibration error: $e');
    }
  }

  /// Dừng service
  void dispose() {
    _audioPlayer.dispose();
  }
}


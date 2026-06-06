import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  final AudioPlayer _messagePlayer = AudioPlayer();
  final AudioPlayer _ringtonePlayer = AudioPlayer();

  AudioService() {
    _messagePlayer.setReleaseMode(ReleaseMode.stop);
    _ringtonePlayer.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> playMessageSound() async {
    if (kIsWeb) return; // Prevent autoplay issues on web if not interacted
    try {
      await _messagePlayer.play(AssetSource('sounds/message_notification.wav'));
    } catch (e) {
      debugPrint("Error playing message sound: $e");
    }
  }

  Future<void> startRingtone() async {
    if (kIsWeb) return;
    try {
      await _ringtonePlayer.play(AssetSource('sounds/incoming_call_ringtone.wav'));
    } catch (e) {
      debugPrint("Error starting ringtone: $e");
    }
  }

  Future<void> stopRingtone() async {
    if (kIsWeb) return;
    try {
      await _ringtonePlayer.stop();
    } catch (e) {
      debugPrint("Error stopping ringtone: $e");
    }
  }

  void dispose() {
    _messagePlayer.dispose();
    _ringtonePlayer.dispose();
  }
}

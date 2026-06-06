# Audio Sound Files for Notifications

## Files needed:

1. **message_notification.wav** - Short beep sound for chat messages
   - Duration: 200-500ms
   - Frequency: 440-800 Hz
   - Format: WAV, MP3, or M4A
   
2. **incoming_call_ringtone.wav** - Ringtone for incoming calls
   - Duration: 3-5 seconds (will loop)
   - Should be recognizable and distinct from message sound
   - Format: WAV, MP3, or M4A

## How to add:
1. Replace the .txt files with actual audio files with the same names
2. Update pubspec.yaml assets section (see example below)

## pubspec.yaml example:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sounds/message_notification.wav
    - assets/sounds/incoming_call_ringtone.wav
```

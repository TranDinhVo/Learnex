# Audio Sound Files for Web Notifications

## Files needed:

1. **message_notification.mp3** - Short beep sound for chat messages
   - Duration: 200-500ms
   - Format: MP3, WAV, OGG, or M4A
   - Browser compatible
   
2. **incoming_call_ringtone.mp3** - Ringtone for incoming calls
   - Duration: 3-5 seconds (will loop in browser)
   - Should be recognizable and distinct from message sound
   - Format: MP3, WAV, OGG, or M4A
   - Browser compatible

## How to add:
1. Download or create audio files with the names above
2. Place them in this `public/sounds/` directory
3. Ensure they are in a browser-compatible audio format
4. The web app will automatically load these files from `/sounds/` path

## Note:
- Make sure MIME types are configured correctly in your web server
- Test audio playback in your target browsers
- Consider providing fallback audio formats (e.g., both .mp3 and .ogg)

# 🔔 Audio Notification Implementation Guide

Hệ thống đã được cập nhật để phát âm thanh thông báo cho chat và cuộc gọi. Hướng dẫn dưới đây sẽ giúp bạn hoàn thành setup.

---

## ✅ Những gì đã được thực hiện

### **Mobile (Flutter)**
1. ✅ Tạo `AudioNotificationService` - quản lý phát âm thanh và rung
2. ✅ Cập nhật `NotificationService` - phát âm thanh khi nhận message
3. ✅ Cập nhật `IncomingCallOverlay` - phát ringtone khi có cuộc gọi đến
4. ✅ Thêm assets configuration trong `pubspec.yaml`
5. ✅ Tạo thư mục `assets/sounds/` để chứa audio files

### **Backend (Node.js)**
1. ✅ Cập nhật `message.service.ts` - gửi FCM push notification khi có message
2. ✅ Cập nhật `websocket.service.ts` - gửi FCM push notification cho call invites
3. ✅ FCM data payload chứa `type: 'message'` hoặc `type: 'call'`

### **Web (React)**
1. ✅ Tạo `notificationAudio.ts` - xử lý browser notifications với âm thanh
2. ✅ Hỗ trợ browser Notification API

---

## 🎵 Cách thêm Audio Files

### **Mobile (Flutter)**

#### 1. Tạo hoặc tải audio files
Bạn cần hai file âm thanh:

**a) Message Notification Sound** (`message_notification.wav`)
- Duration: 200-500ms (âm thanh ngắn)
- Format: WAV, MP3, M4A, OGG
- Gợi ý: Dùng simple beep sound (440 Hz - 800 Hz)
- Nơi lưu: `mobile/assets/sounds/message_notification.wav`

**b) Incoming Call Ringtone** (`incoming_call_ringtone.wav`)
- Duration: 3-5 giây (sẽ lặp lại)
- Format: WAV, MP3, M4A, OGG
- Gợi ý: Dùng ringtone nghe bất thường, dễ nhận biết
- Nơi lưu: `mobile/assets/sounds/incoming_call_ringtone.wav`

#### 2. Đặt audio files vào đúng vị trí
```
mobile/
├── assets/
│   └── sounds/
│       ├── message_notification.wav   (⬅️ đặt file ở đây)
│       ├── incoming_call_ringtone.wav (⬅️ đặt file ở đây)
│       └── README.md
└── pubspec.yaml (đã cập nhật)
```

#### 3. Xác nhận pubspec.yaml
File đã được cập nhật tự động:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sounds/message_notification.wav
    - assets/sounds/incoming_call_ringtone.wav
```

#### 4. Chạy flutter pub get
```bash
cd mobile
flutter pub get
flutter pub cache repair  # nếu lỗi
```

---

### **Web (React)**

#### 1. Tạo hoặc tải audio files
**a) Message Notification Sound**
- File: `message_notification.mp3`
- Duration: 200-500ms
- Format: MP3, WAV, OGG, M4A (browser compatible)

**b) Incoming Call Ringtone**
- File: `incoming_call_ringtone.mp3`
- Duration: 3-5 giây
- Format: MP3, WAV, OGG, M4A

#### 2. Đặt vào đúng vị trí
```
web/
├── public/
│   └── sounds/
│       ├── message_notification.mp3   (⬅️ đặt file ở đây)
│       ├── incoming_call_ringtone.mp3 (⬅️ đặt file ở đây)
│       └── README.md
└── index.html
```

#### 3. Tùy chọn: Thêm MIME types vào web server
Nếu dùng Vite dev server hoặc nginx, đảm bảo MIME types được cấu hình:

**Vite (`vite.config.ts`):**
```typescript
export default {
  server: {
    mimetype: {
      'audio/mpeg': ['mp3'],
      'audio/ogg': ['ogg'],
      'audio/wav': ['wav'],
    }
  }
}
```

**Nginx (`nginx.conf`):**
```nginx
http {
  types {
    audio/mpeg mp3;
    audio/ogg ogg;
    audio/wav wav;
  }
}
```

#### 4. Tích hợp vào React App
Để sử dụng notification service trong React:

```tsx
import { notificationAudio } from './utils/notificationAudio';

// Khi app khởi động
useEffect(() => {
  notificationAudio.requestPermission();
}, []);

// Khi nhận message
const handleNewMessage = async () => {
  await notificationAudio.showMessageNotification(
    'Tin nhắn mới',
    { body: 'Bạn có tin nhắn mới' }
  );
};

// Khi có cuộc gọi đến
const handleIncomingCall = async () => {
  await notificationAudio.showIncomingCallNotification(
    'Cuộc gọi đến',
    { body: 'Người gọi: Tên' }
  );
};

// Dừng ringtone khi user chấp nhận hoặc từ chối
const handleAcceptCall = () => {
  notificationAudio.stopIncomingCallRingtone();
  // ... logic chấp nhận cuộc gọi
};
```

---

## 🎬 Hành động khi nhận Notification

### **Mobile - Cách hoạt động**

```
1. Server gửi FCM push notification
   └─> data: { type: 'message', ... } hoặc { type: 'call', ... }

2. Firebase Messaging nhận notification
   └─> Nếu app ở foreground → FirebaseMessaging.onMessage listener

3. NotificationService xử lý:
   - Kiểm tra notification type
   - type: 'message' → playMessageNotification()
     └─> Rung 2 lần (200ms mỗi lần)
     └─> Phát beep 0.8 volume
   - type: 'call' → playIncomingCallRingtone()
     └─> Rung liên tục
     └─> Phát ringtone 1.0 volume (loop)

4. IncomingCallOverlay hiển thị
   └─> Ringtone tiếp tục cho đến khi user chấp nhận/từ chối
   └─> Khi overlay đóng → stopIncomingCallRingtone() được gọi
```

### **Web - Cách hoạt động**

```
1. Khi có message/call notification:
   └─> Gọi notificationAudio.showMessageNotification()
   └─> Gọi notificationAudio.showIncomingCallNotification()

2. Browser hiển thị notification popup
   └─> Phát âm thanh tương ứng
   └─> Có thể cấu hình autoClose hoặc requireInteraction

3. User click notification
   └─> Callback được trigger
   └─> App navigate đến chat/call screen
```

---

## 🔧 Cấu hình chi tiết

### **Audio Notification Service (Mobile)**
File: `mobile/lib/core/services/audio_notification_service.dart`

```dart
// Tuỳ chỉnh âm lượng (0.0 - 1.0)
this.messageSound.volume = 0.8;  // Message: 80%
this.callSound.volume = 1.0;     // Call: 100%

// Tuỳ chỉnh pattern rung
// Message: 2 lần rung, 100ms mỗi lần
// Call: Rung liên tục (500ms on, 500ms off)
```

### **Notification Audio Service (Web)**
File: `web/src/utils/notificationAudio.ts`

```typescript
// Tuỳ chỉnh âm lượng
this.messageSound.volume = 0.8;
this.callSound.volume = 1.0;

// Auto-close notification sau 5 giây (chỉ message)
setTimeout(() => notification.close(), 5000);

// Call notification: requireInteraction = true (không tự đóng)
```

---

## ✨ Testing

### **Test Message Notification (Mobile)**
1. Build app: `flutter build apk` hoặc run emulator
2. Gửi message từ tài khoản khác
3. Kiểm tra: ✅ Rung + âm thanh beep

### **Test Incoming Call (Mobile)**
1. Gọi từ tài khoản khác
2. Kiểm tra:
   - ✅ Rung liên tục
   - ✅ Ringtone phát
   - ✅ Incoming overlay hiển thị
   - ✅ Khi chấp nhận/từ chối → ringtone dừng

### **Test Web Notifications**
1. Đảm bảo file audio ở `/public/sounds/`
2. Test message: `notificationAudio.showMessageNotification(...)`
3. Test call: `notificationAudio.showIncomingCallNotification(...)`
4. Kiểm tra:
   - ✅ Browser notification popup
   - ✅ Âm thanh phát
   - ✅ Notification hiển thị đúng icon/body

---

## 🐛 Troubleshooting

### **Mobile**
| Vấn đề | Giải pháp |
|--------|---------|
| Không nghe âm thanh | Kiểm tra file audio ở đúng path, chạy `flutter pub get` |
| Notification không phát âm thanh | Đảm bảo app có quyền RECORD_AUDIO, MODIFY_AUDIO_SETTINGS |
| Ringtone không dừng khi đóng overlay | Kiểm tra `dispose()` được gọi |
| Rung không hoạt động | Kiểm tra quyền VIBRATE trên Android |

### **Web**
| Vấn đề | Giải pháp |
|--------|---------|
| Âm thanh không phát | Kiểm tra CORS policy, file MIME type |
| Notification không hiển thị | Kiểm tra browser permission (`Notification.requestPermission()`) |
| File audio 404 | Đảm bảo file ở `/public/sounds/` với tên chính xác |

---

## 📋 Checklist

- [ ] Đặt `message_notification.wav` vào `mobile/assets/sounds/`
- [ ] Đặt `incoming_call_ringtone.wav` vào `mobile/assets/sounds/`
- [ ] Chạy `flutter pub get` trong thư mục mobile
- [ ] Đặt `message_notification.mp3` vào `web/public/sounds/`
- [ ] Đặt `incoming_call_ringtone.mp3` vào `web/public/sounds/`
- [ ] Test message notification (Mobile)
- [ ] Test incoming call (Mobile)
- [ ] Test web notifications (nếu có WebSocket chat)
- [ ] Verify FCM push notifications đến mobile
- [ ] Kiểm tra lại toàn bộ chức năng

---

## 📞 Support

Nếu gặp vấn đề, hãy kiểm tra:
1. Logs: `flutter logs` (mobile) hoặc browser console (web)
2. FCM token đã được đăng ký chưa
3. Audio file format có hỗ trợ không
4. Permission được cấp chưa

Chúc bạn thành công! 🚀

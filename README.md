# LearnEx Mobile App 🚀

LearnEx là mạng xã hội học tập tương tác. Repository này chứa toàn bộ mã nguồn của dự án (Backend, Web, Mobile). Tuy nhiên, **Backend và Web Frontend đã được deploy độc lập**. File README này sẽ tập trung hướng dẫn bạn cách clone mã nguồn và chạy ứng dụng **Mobile (Flutter)** trực tiếp kết nối với hệ thống đã deploy.

## Báo cáo đồ án

📄 Báo cáo đồ án: [BaoCaoDoAn_Mobile.pdf](docs/BaoCaoDoAn_Mobile.pdf)

## 🛠 Công nghệ sử dụng

- **Framework**: Flutter
- **Ngôn ngữ**: Dart
- **Phiên bản Flutter/Dart**: Flutter SDK `>=3.0.0 <4.0.0` (Hỗ trợ Dart 3)
- **State Management**: BLoC Pattern (`flutter_bloc`)
- **Dependency Injection**: `get_it`
- **Networking**: `dio` (REST API), `web_socket_channel` (Real-time Chat)
- **Call (Thoại/Video)**: `flutter_webrtc`
- **Push Notification**: Firebase Cloud Messaging (`firebase_core`, `firebase_messaging`)
- **Bộ nhớ cục bộ**: `flutter_secure_storage`
- **Xử lý Media**: `image_picker`, `file_picker`, `audioplayers`, `video_player`

## 📦 Các bước cài đặt và chạy project Mobile

Do Backend API (Node.js) và Web Dashboard (React) đã được deploy lên server thật, bạn chỉ cần thiết lập ứng dụng Mobile để chạy.

### 1. Clone Source Code

```bash
git clone https://github.com/TranDinhVo/Learnex.git
cd learnex/mobile
```

### 2. Cài đặt Dependencies

Tiến hành tải các thư viện cần thiết cho Flutter:

```bash
flutter clean
flutter pub get
```

### 3. Cấu hình Môi trường (API Endpoint)

Mặc định, ứng dụng đã được cấu hình trỏ tới Production Backend (`https://learnex-backend-40yr.onrender.com/api`).
Nếu bạn muốn chạy Backend Local, hãy sửa đổi biến `_defaultBaseUrl` trong file `lib/core/network/dio_client.dart` thành IP máy tính ảo/thật của bạn (VD: `http://10.0.2.2:8080/api`).Frontend Admin (`https://learnex-one.vercel.app`)

### 4. Build và Chạy Ứng dụng

Kết nối thiết bị Android/iOS hoặc mở máy ảo (Emulator) và chạy:

```bash
# Chạy chế độ debug
flutter run

# Hoặc build trực tiếp ra file APK để cài lên điện thoại Android
flutter build apk --release
```

_File APK sau khi build sẽ nằm ở: `build/app/outputs/flutter-apk/app-release.apk`_

---

## 🔥 Hướng dẫn cấu hình Firebase (Bắt buộc)

Dự án sử dụng Firebase Cloud Messaging (FCM) để đẩy thông báo Real-time (Tin nhắn mới, Lời mời kết bạn,...). Hệ thống cơ sở dữ liệu chính sử dụng **PostgreSQL** trên Backend chứ không dùng Firestore. Do đó bạn **không cần tạo Collection/Document mẫu hay thiết lập Firebase Rules**.

Tuy nhiên, bạn **BẮT BUỘC** phải cung cấp file cấu hình dự án Firebase của bạn để app build được:

### Dành cho Android

1. Đã có file `google-services.json`.
2. Nằm trong thư mục: `mobile/android/app/google-services.json`

### Dành cho iOS (Nếu build trên Mac)

1. Đã có file `GoogleService-Info.plist`.
2. Nằm trong thư mục: `mobile/ios/Runner/GoogleService-Info.plist`

---

## 🔑 Tài khoản Test (Demo)

Bạn có thể tạo tài khoản mới ngay trên app, hoặc sử dụng các tài khoản có sẵn đã được seed trên Database Production để test các tính năng kết bạn, nhắn tin, xem bài viết:

| Vai trò                           | Email đăng nhập        | Mật khẩu | Ghi chú                  |
| :-------------------------------- | :--------------------- | :------- | :----------------------- |
| **Quản trị / Admin dành cho web** | `admin@learnex.edu.vn` | `123456` | Có quyền quản lý         |
| **User 2**                        | `user1@learnex.edu.vn` | `123456` | Tài khoản sinh viên test |
| **User 3**                        | `user2@learnex.edu.vn` | `123456` | Tài khoản sinh viên test |

_(Lưu ý: Mật khẩu có thể đã bị đổi bởi người dùng khác trên môi trường Production, nếu không đăng nhập được, bạn cứ bấm "Đăng ký" tài khoản mới rất nhanh chóng)._

---

## ⚠️ Các lưu ý cần thiết khác

1. **Quyền truy cập (Permissions):**
   Lần đầu sử dụng tính năng Gọi Video (WebRTC) hoặc Gửi file/Ghi âm, app sẽ yêu cầu cấp quyền Camera, Microphone và Storage. Hãy bấm "Cho phép".
2. **Cảnh báo Build Android (Kotlin):**
   Trong quá trình build APK có thể xuất hiện dòng chữ `WARNING: Your Android app project applies the Kotlin Gradle Plugin`. Đây là cảnh báo tương thích của các package cũ (như `audioplayers`, `flutter_webrtc`) với phiên bản Flutter mới, bạn hoàn toàn **có thể bỏ qua** vì nó không ảnh hưởng đến file APK xuất ra.
3. **Quản lý trạng thái Call:**
   Tính năng gọi điện nhóm dựa trên WebRTC Server và WebSocket. Đảm bảo đường truyền mạng ổn định để luồng báo hiệu (Signaling) không bị ngắt quãng.
4. **Tải File Tài liệu:**
   Ứng dụng xử lý việc tải PDF/DOCX qua hệ thống Proxy nội bộ trên thiết bị bằng cách tự động chèn cờ tải (attachment) vào đường dẫn Cloudinary, vì vậy file sẽ tải thẳng vào bộ nhớ máy điện thoại thay vì mở tab lỗi.

---

_Developed with ❤️ by LearnEx Team._

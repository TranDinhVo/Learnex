# LearnEx 🚀

LearnEx là mạng xã hội học tập fullstack được thiết kế để mang lại trải nghiệm giáo dục tương tác và mạnh mẽ. Dự án bao gồm Web Dashboard (React), Ứng dụng Mobile (Flutter) và Backend API mở rộng được (Express + TypeScript).

## 🌟 Tính năng nổi bật

- **Xác thực**: Đăng nhập/Đăng ký an toàn với JWT.
- **Chat Real-time**: Nhắn tin theo thời gian thực (WebSocket) và gọi điện thoại/video (WebRTC).
- **Mạng xã hội & Tài liệu**: Chia sẻ bài viết, tải lên tài liệu (Cloudinary) và tương tác với nội dung.
- **Nhóm học tập (Rooms)**: Tạo các không gian/nhóm để thảo luận, học chung.
- **Tích hợp AI**: Tóm tắt tài liệu tự động bằng Google Gemini.
- **Thông báo (Notifications)**: Đẩy thông báo theo thời gian thực cho các lượt tương tác.

## 🏗 Kiến trúc & Công nghệ (Tech Stack)

### Backend (Node.js / Express)
- **Ngôn ngữ**: TypeScript
- **Framework**: Express.js
- **Database**: PostgreSQL (truy vấn với Knex.js) và Redis (Caching/Session)
- **Hạ tầng**: Docker & Docker Compose
- **Dịch vụ tích hợp**: Cloudinary (Upload ảnh/tài liệu), Google Generative AI (Gemini)

### Web (React)
- **Framework**: React + Vite
- **Styling**: Tailwind CSS v4
- **State Management**: Zustand (Client State), TanStack Query (Server State)
- **Forms & Validation**: React Hook Form + Zod
- **Icons**: Lucide React

### Mobile (Flutter)
- **Framework**: Flutter
- **Kiến trúc State**: BLoC Pattern
- **Mạng & API**: Dio (API Client), WebSockets/WebRTC
- **Lưu trữ**: Flutter Secure Storage

## 🚀 Hướng dẫn cài đặt & Chạy dự án

### Yêu cầu hệ thống
- Node.js (v18+)
- Flutter SDK
- Docker & Docker Compose

### 1. Clone repository
```bash
git clone https://github.com/TranDinhVo/Learnex.git
cd learnex
```

### 2. Chạy Backend & Databases
```bash
# Khởi động PostgreSQL và Redis
docker compose up -d postgres redis

# Cài đặt thư viện backend
cd backend
npm install

# Tạo file biến môi trường (copy từ example)
cp .env.example .env

# Chạy server development
npm run dev
```

### 3. Chạy Web Frontend
```bash
cd web
npm install
npm run dev
```

### 4. Chạy Mobile App
```bash
cd mobile
flutter pub get
flutter run
```

## 📂 Cấu trúc thư mục

- `backend/`: Chứa mã nguồn Express REST API và WebSocket server.
- `web/`: Chứa mã nguồn của Vite/React Web Dashboard.
- `mobile/`: Chứa ứng dụng Flutter cho Android/iOS.
- `database/`: Chứa script khởi tạo database, migrations.


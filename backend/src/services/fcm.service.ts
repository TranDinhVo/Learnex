import * as admin from "firebase-admin";
import path from "path";

// 1. Đường dẫn trỏ tới file JSON (Giả định file này nằm ở src/services/fcm.service.ts)
// Nó sẽ lùi ra src -> lùi ra backend -> tìm file json
const serviceAccountPath = path.resolve(
  __dirname,
  "../../firebase-service-account.json",
);

// 2. Khởi tạo Firebase Admin (Chỉ khởi tạo 1 lần để tránh lỗi khi Nodemon reload)
if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
    });
    console.log("🔥 [FCM] Firebase Admin SDK initialized successfully");
  } catch (error) {
    console.error("❌ [FCM] Lỗi khởi tạo Firebase:", error);
  }
}

export const fcmService = {
  /**
   * Gửi thông báo đến 1 thiết bị cụ thể
   */
  async sendPushNotification(
    token: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    try {
      const message: admin.messaging.Message = {
        token,
        notification: { title, body },
        data: data || {}, // Dữ liệu ẩn kèm theo để frontend/mobile xử lý khi click
      };

      const response = await admin.messaging().send(message);
      console.log(
        `✅ [FCM] Đã gửi thông báo thành công tới token: ${token.substring(0, 15)}...`,
      );
      console.log(`   ID: ${response}`);
    } catch (error) {
      console.error(`❌ [FCM] Lỗi khi gửi tới token ${token}:`, error);
      throw error; // Ném lỗi ra ngoài để Controller có thể catch và trả về response phù hợp
    }
  },

  /**
   * Gửi thông báo cho nhiều thiết bị cùng lúc
   */
  async sendMultiplePush(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    // Tránh lỗi API của Firebase khi mảng token bị rỗng
    if (!tokens || tokens.length === 0) {
      console.log("⚠️ [FCM] Bỏ qua gửi thông báo do danh sách token rỗng.");
      return;
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens,
        notification: { title, body },
        data: data || {},
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      console.log(
        `✅ [FCM] Multicast hoàn tất! Thành công: ${response.successCount}, Thất bại: ${response.failureCount}`,
      );

      // (Tùy chọn) Lọc ra các token bị lỗi (thường là do user đã gỡ app hoặc token hết hạn) để xóa khỏi DB
      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens[idx]);
          }
        });
        console.log(
          "⚠️ [FCM] Các token bị lỗi (nên xóa khỏi DB):",
          failedTokens,
        );
      }
    } catch (error) {
      console.error("❌ [FCM] Lỗi khi gửi Multicast:", error);
      throw error;
    }
  },
};

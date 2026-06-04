import { db } from "../config/database";
import { AppError } from "../utils/AppError";
import { Notification } from "../models/types";
import { PaginationParams } from "../utils/pagination";

export const notificationService = {
  async create(data: {
    user_id: string;
    type: string;
    title: string;
    body?: string;
    ref_type?: string;
    ref_id?: string;
  }): Promise<Notification> {
    const [notification] = await db("notifications")
      .insert(data)
      .returning("*");
    return notification;
  },

  async getByUser(
    userId: string,
    pagination: PaginationParams,
  ): Promise<{ data: Notification[]; total: number }> {
    const [{ count }] = await db("notifications")
      .where({ user_id: userId })
      .count("* as count");
    const total = parseInt(count as string, 10);

    const data = await db("notifications")
      .where({ user_id: userId })
      .orderBy("created_at", "desc")
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async markRead(notificationId: string, userId: string): Promise<void> {
    const result = await db("notifications")
      .where({ id: notificationId, user_id: userId })
      .update({ is_read: true });

    if (!result) {
      throw new AppError("Notification not found.", 404);
    }
  },

  async markAllRead(userId: string): Promise<void> {
    await db("notifications")
      .where({ user_id: userId, is_read: false })
      .update({ is_read: true });
  },

  async getUnreadCount(userId: string): Promise<number> {
    const [{ count }] = await db("notifications")
      .where({ user_id: userId, is_read: false })
      .count("* as count");
    return parseInt(count as string, 10);
  },

  async saveFcmToken(userId: string, token: string): Promise<void> {
    await db("users").where({ id: userId }).update({ fcm_token: token });
  },

  async delete(notificationId: string, userId: string): Promise<void> {
    const result = await db("notifications")
      .where({ id: notificationId, user_id: userId })
      .del();

    if (!result) {
      throw new AppError("Notification not found.", 404);
    }
  },
};

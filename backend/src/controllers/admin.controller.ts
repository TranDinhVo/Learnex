import { Request, Response, NextFunction } from "express";
import { adminService } from "../services/admin.service";
import { userService } from "../services/user.service";
import { sendResponse } from "../utils/response";
import { getPaginationParams } from "../utils/pagination";

export const adminController = {
  async getDashboardStats(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const stats = await adminService.getDashboardStats();
      sendResponse(res, 200, stats, "Dashboard stats retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async getAllUsers(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await adminService.getAllUsers(pagination);

      // Adapt response to frontend expectation: PaginatedResponse<User>
      const formatted = {
        data: result.data.map((u) => ({
          _id: u.id,
          name: u.full_name,
          username: u.username,
          email: u.email,
          avatar: u.avatar_url,
          role: u.role,
          isBanned: u.is_banned,
          createdAt: u.created_at,
          updatedAt: u.created_at,
        })),
        total: result.total,
        page: pagination.page,
        limit: pagination.limit,
        totalPages: Math.ceil(result.total / pagination.limit),
      };

      sendResponse(res, 200, formatted, "Users retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async getUserById(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const user = await userService.getUserById(id);
      sendResponse(res, 200, user, "User retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async createUser(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const { email, password, full_name, username, role } = req.body;
      const file = req.file as Express.Multer.File | undefined;
      const user = await userService.createUserByAdmin(
        {
          email,
          password,
          full_name,
          username,
          role,
        },
        file,
      );
      sendResponse(res, 201, user, "User created successfully");
    } catch (error) {
      next(error);
    }
  },

  async updateUser(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const payload = req.body;
      const file = req.file as Express.Multer.File | undefined;
      const user = await userService.adminUpdateUser(id, payload, file);
      sendResponse(res, 200, user, "User updated successfully");
    } catch (error) {
      next(error);
    }
  },

  async banUser(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const user = await adminService.banUser(id);
      sendResponse(res, 200, user, "User banned successfully");
    } catch (error) {
      next(error);
    }
  },

  async unbanUser(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const user = await adminService.unbanUser(id);
      sendResponse(res, 200, user, "User unbanned successfully");
    } catch (error) {
      next(error);
    }
  },

  async deleteUser(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      await adminService.deleteUser(id);
      sendResponse(res, 200, null, "User deleted successfully");
    } catch (error) {
      next(error);
    }
  },

  async updateUserRole(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const { role } = req.body;
      const user = await adminService.updateUserRole(id, role);
      sendResponse(res, 200, user, "User role updated successfully");
    } catch (error) {
      next(error);
    }
  },

  // ── Posts Moderation ──
  async getAllPosts(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await adminService.getAllPosts(pagination);
      sendResponse(res, 200, result, "Posts retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async hidePost(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const { reason } = req.body;
      const post = await adminService.hidePost(id, reason);
      sendResponse(res, 200, post, "Post hidden successfully");
    } catch (error) {
      next(error);
    }
  },

  async unhidePost(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const post = await adminService.unhidePost(id);
      sendResponse(res, 200, post, "Post unhidden successfully");
    } catch (error) {
      next(error);
    }
  },

  async deletePost(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const { reason } = req.body;
      await adminService.deletePost(id, reason);
      sendResponse(res, 200, null, "Post deleted successfully");
    } catch (error) {
      next(error);
    }
  },

  // ── Documents Management ──
  async getAllDocuments(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await adminService.getAllDocuments(pagination);
      sendResponse(res, 200, result, "Documents retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async approveDocument(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const doc = await adminService.approveDocument(id);
      sendResponse(res, 200, doc, "Document approved successfully");
    } catch (error) {
      next(error);
    }
  },

  async rejectDocument(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const { reason } = req.body;
      const doc = await adminService.rejectDocument(id, reason);
      sendResponse(res, 200, doc, "Document rejected successfully");
    } catch (error) {
      next(error);
    }
  },

  async deleteDocument(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const { reason } = req.body;
      await adminService.deleteDocument(id, reason);
      sendResponse(res, 200, null, "Document deleted successfully");
    } catch (error) {
      next(error);
    }
  },

  // ── Rooms Moderation ──
  async getAllRooms(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await adminService.getAllRooms(pagination);
      sendResponse(res, 200, result, "Rooms retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async deleteRoom(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const id = req.params.id as string;
      const { reason } = req.body;
      await adminService.deleteRoom(id, reason);
      sendResponse(res, 200, null, "Room deleted successfully");
    } catch (error) {
      next(error);
    }
  },

  // ── System Notifications ──
  async sendNotification(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const senderId = req.user!.userId;
      const notification = await adminService.sendNotification(
        senderId,
        req.body,
      );
      sendResponse(res, 201, notification, "Notification sent successfully");
    } catch (error) {
      next(error);
    }
  },

  async getNotificationHistory(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await adminService.getNotificationHistory(pagination);
      sendResponse(
        res,
        200,
        result,
        "Notification history retrieved successfully",
      );
    } catch (error) {
      next(error);
    }
  },

  // ── System Settings ──
  async getSettings(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const settings = await adminService.getSettings();
      sendResponse(res, 200, settings, "Settings retrieved successfully");
    } catch (error) {
      next(error);
    }
  },

  async updateSettings(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const { settings } = req.body;
      const updatedSettings = await adminService.updateSettings(settings);
      sendResponse(res, 200, updatedSettings, "Settings updated successfully");
    } catch (error) {
      next(error);
    }
  },
};

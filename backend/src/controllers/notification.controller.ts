import { Request, Response, NextFunction } from 'express';
import { notificationService } from '../services/notification.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams, buildPaginationInfo } from '../utils/pagination';

export const notificationController = {
  async getMyNotifications(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await notificationService.getByUser(req.user!.userId, pagination);
      
      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async markRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await notificationService.markRead(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Notification marked as read');
    } catch (error) {
      next(error);
    }
  },

  async markAllRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await notificationService.markAllRead(req.user!.userId);
      sendResponse(res, 200, null, 'All notifications marked as read');
    } catch (error) {
      next(error);
    }
  },

  async getUnreadCount(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const count = await notificationService.getUnreadCount(req.user!.userId);
      sendResponse(res, 200, { count }, 'Unread count retrieved');
    } catch (error) {
      next(error);
    }
  },

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await notificationService.delete(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Notification deleted');
    } catch (error) {
      next(error);
    }
  },
};

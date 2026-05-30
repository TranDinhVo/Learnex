import { Request, Response, NextFunction } from 'express';
import { messageService } from '@/module/message/message.service';
import { sendResponse } from '@/utils/response';
import { getPaginationParams, buildPaginationInfo } from '@/utils/pagination';

export const messageController = {
  async send(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const message = await messageService.send(req.user!.userId, req.params.userId as string, req.body);
      sendResponse(res, 201, message, 'Message sent');
    } catch (error) {
      next(error);
    }
  },

  async getConversation(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await messageService.getConversation(
        req.user!.userId,
        req.params.userId as string,
        pagination
      );

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async getConversationList(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const conversations = await messageService.getConversationList(req.user!.userId);
      sendResponse(res, 200, conversations, 'Conversations retrieved');
    } catch (error) {
      next(error);
    }
  },

  async markAsRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await messageService.markAsRead(req.user!.userId, req.params.userId as string);
      sendResponse(res, 200, null, 'Messages marked as read');
    } catch (error) {
      next(error);
    }
  },
};

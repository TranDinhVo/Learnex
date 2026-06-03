import { Request, Response, NextFunction } from 'express';
import { messageService } from '../services/message.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams, buildPaginationInfo } from '../utils/pagination';
import { webSocketService } from '../services/websocket.service';

export const chatController = {
  async getConversations(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const rawConversations = await messageService.getConversationList(req.user!.userId);
      
      // Format to match mobile app schema: other_user, last_message, unread_count
      const formattedConversations = rawConversations.map(conv => ({
        id: conv.id,
        other_user: {
          id: conv.partner?.id,
          full_name: conv.partner?.full_name,
          username: conv.partner?.username,
          avatar_url: conv.partner?.avatar_url,
        },
        last_message: {
          id: conv.id,
          sender_id: conv.sender_id,
          receiver_id: conv.receiver_id,
          content: conv.content,
          file_url: conv.file_url,
          is_read: conv.is_read,
          created_at: conv.created_at,
        },
        unread_count: conv.unread_count,
      }));

      sendResponse(res, 200, formattedConversations, 'Conversations retrieved');
    } catch (error) {
      next(error);
    }
  },

  async getMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      // In direct messages, conversationId is the other user's ID
      const { data, total } = await messageService.getConversation(
        req.user!.userId,
        req.params.conversationId as string,
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

  async sendMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { content, file_url } = req.body;
      const message = await messageService.send(
        req.user!.userId,
        req.params.conversationId as string,
        { content, file_url }
      );

      // Phát realtime
      webSocketService.sendToUser(req.params.conversationId as string, {
        type: 'chat_message',
        data: message,
      });

      // Echo lại cho sender nếu họ có các thiết bị khác đang online
      webSocketService.sendToUser(req.user!.userId, {
        type: 'chat_message',
        data: message,
      });

      sendResponse(res, 201, message, 'Message sent');
    } catch (error) {
      next(error);
    }
  },

  async deleteMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const type = req.body.type === 'for_everyone' ? 'for_everyone' : 'for_me';
      const result = await messageService.deleteMessage(req.params.messageId as string, req.user!.userId, type);
      sendResponse(res, 200, result, 'Message deleted successfully');
    } catch (error) {
      next(error);
    }
  },

  async editMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await messageService.editMessage(req.params.messageId as string, req.user!.userId, req.body.content);
      sendResponse(res, 200, result, 'Message edited successfully');
    } catch (error) {
      next(error);
    }
  },
};

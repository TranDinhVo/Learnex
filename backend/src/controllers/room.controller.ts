import { Request, Response, NextFunction } from 'express';
import { roomService } from '../services/room.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams, buildPaginationInfo } from '../utils/pagination';
import { webSocketService } from '../services/websocket.service';

export const roomController = {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const room = await roomService.create(req.user!.userId, req.body);
      sendResponse(res, 201, room, 'Room created successfully');
    } catch (error) {
      next(error);
    }
  },

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const room = await roomService.getById(req.params.id as string, req.user?.userId);
      sendResponse(res, 200, room, 'Room retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const search = req.query.search as string | undefined;
      const { data, total } = await roomService.getAll(pagination, req.user?.userId, search);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const room = await roomService.update(req.params.id as string, req.user!.userId, req.body);
      sendResponse(res, 200, room, 'Room updated successfully');
    } catch (error) {
      next(error);
    }
  },

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await roomService.delete(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Room deleted successfully');
    } catch (error) {
      next(error);
    }
  },

  async join(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await roomService.join(req.params.id as string, req.user!.userId);
      if ('status' in result && result.status === 'pending') {
        sendResponse(res, 202, result, 'Join request sent and is pending approval');
      } else {
        sendResponse(res, 201, result, 'Joined room successfully');
      }
    } catch (error) {
      next(error);
    }
  },

  async leave(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await roomService.leave(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Left room successfully');
    } catch (error) {
      next(error);
    }
  },

  async getMembers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const members = await roomService.getMembers(req.params.id as string);
      sendResponse(res, 200, members, 'Room members retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async kick(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const targetUserId = req.body.userId;
      const roomId = req.params.id as string;
      await roomService.kick(roomId, req.user!.userId, targetUserId);
      
      // Notify the kicked user via WebSocket
      webSocketService.sendToUser(targetUserId, {
        type: 'room_kicked',
        data: { roomId }
      });
      
      sendResponse(res, 200, null, 'Member kicked successfully');
    } catch (error) {
      next(error);
    }
  },

  async invite(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await roomService.invite(req.params.id as string, req.user!.userId, req.body.userId);
      sendResponse(res, 200, null, 'Invitation sent successfully');
    } catch (error) {
      next(error);
    }
  },

  async sendMessage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const message = await roomService.sendMessage(req.params.id as string, req.user!.userId, req.body);
      sendResponse(res, 201, message, 'Message sent successfully');
    } catch (error) {
      next(error);
    }
  },

  async getMessages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await roomService.getMessages(req.params.id as string, req.user!.userId, pagination);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async uploadAvatar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.file) {
        sendResponse(res, 400, null, 'No image file provided');
        return;
      }
      const url = await roomService.uploadAvatar(req.params.id as string, req.user!.userId, req.file);
      sendResponse(res, 200, { avatar_url: url }, 'Room avatar updated successfully');
    } catch (error) {
      next(error);
    }
  },

  async updateMemberRole(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await roomService.updateMemberRole(req.params.id as string, req.user!.userId, req.params.userId as string, req.body.role);
      sendResponse(res, 200, null, 'Member role updated successfully');
    } catch (error) {
      next(error);
    }
  },

  async markRead(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { messageIds } = req.body;
      if (!messageIds || !Array.isArray(messageIds)) {
        sendResponse(res, 400, null, 'messageIds must be an array of UUIDs');
        return;
      }
      await roomService.markMessagesRead(req.params.id as string, req.user!.userId, messageIds);
      sendResponse(res, 200, null, 'Messages marked as read');
    } catch (error) {
      next(error);
    }
  },

  async getReadReceipts(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      let messageIds = req.query.messageIds as string | string[];
      if (!messageIds) {
        messageIds = [];
      } else if (!Array.isArray(messageIds)) {
        messageIds = messageIds.split(',');
      }
      
      const receipts = await roomService.getReadReceipts(req.params.id as string, messageIds as string[]);
      sendResponse(res, 200, receipts, 'Read receipts retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async transferOwnership(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { newOwnerId } = req.body;
      await roomService.transferOwnership(req.params.id as string, req.user!.userId, newOwnerId);
      sendResponse(res, 200, null, 'Ownership transferred successfully');
    } catch (error) {
      next(error);
    }
  },

  async getJoinRequests(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const requests = await roomService.getJoinRequests(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, requests, 'Join requests retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async approveJoinRequest(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await roomService.approveJoinRequest(req.params.id as string, req.user!.userId, req.params.userId as string);
      sendResponse(res, 200, null, 'Join request approved');
    } catch (error) {
      next(error);
    }
  },

  async rejectJoinRequest(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await roomService.rejectJoinRequest(req.params.id as string, req.user!.userId, req.params.userId as string);
      sendResponse(res, 200, null, 'Join request rejected');
    } catch (error) {
      next(error);
    }
  }
};

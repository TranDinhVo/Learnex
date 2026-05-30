import { Request, Response, NextFunction } from 'express';
import { friendService } from '@/module/friend/friend.service';
import { sendResponse } from '@/utils/response';
import { getPaginationParams, buildPaginationInfo } from '@/utils/pagination';

export const friendController = {
  async sendRequest(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const friendship = await friendService.sendRequest(req.user!.userId, req.params.userId as string);
      sendResponse(res, 201, friendship, 'Friend request sent');
    } catch (error) {
      next(error);
    }
  },

  async acceptRequest(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const friendship = await friendService.acceptRequest(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, friendship, 'Friend request accepted');
    } catch (error) {
      next(error);
    }
  },

  async rejectRequest(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await friendService.rejectRequest(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Friend request rejected');
    } catch (error) {
      next(error);
    }
  },

  async unfriend(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await friendService.unfriend(req.user!.userId, req.params.userId as string);
      sendResponse(res, 200, null, 'Unfriended successfully');
    } catch (error) {
      next(error);
    }
  },

  async getFriends(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await friendService.getFriends(req.user!.userId, pagination);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async getRequests(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await friendService.getRequests(req.user!.userId, pagination);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async getFriendshipStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const status = await friendService.getFriendshipStatus(req.user!.userId, req.params.userId as string);
      sendResponse(res, 200, status, 'Friendship status retrieved');
    } catch (error) {
      next(error);
    }
  },
};

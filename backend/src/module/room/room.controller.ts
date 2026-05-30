import { Request, Response, NextFunction } from 'express';
import { roomService } from '@/module/room/room.service';
import { sendResponse } from '@/utils/response';
import { getPaginationParams, buildPaginationInfo } from '@/utils/pagination';

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
      const room = await roomService.getById(req.params.id as string);
      sendResponse(res, 200, room, 'Room retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await roomService.getAll(pagination, req.user?.userId);

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
      const member = await roomService.join(req.params.id as string, req.user!.userId);
      sendResponse(res, 201, member, 'Joined room successfully');
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
      await roomService.kick(req.params.id as string, req.user!.userId, req.body.userId);
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
};

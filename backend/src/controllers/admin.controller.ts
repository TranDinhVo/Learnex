import { Request, Response, NextFunction } from 'express';
import { adminService } from '../services/admin.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams } from '../utils/pagination';

export const adminController = {
  async getDashboardStats(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const stats = await adminService.getDashboardStats();
      sendResponse(res, 200, stats, 'Dashboard stats retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async getAllUsers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await adminService.getAllUsers(pagination);
      
      // Adapt response to frontend expectation: PaginatedResponse<User>
      const formatted = {
        data: result.data.map(u => ({
          _id: u.id,
          name: u.full_name,
          username: u.username,
          email: u.email,
          avatar: u.avatar_url,
          role: u.role,
          isBanned: u.is_banned,
          createdAt: u.created_at,
          updatedAt: u.created_at
        })),
        total: result.total,
        page: pagination.page,
        limit: pagination.limit,
        totalPages: Math.ceil(result.total / pagination.limit)
      };

      sendResponse(res, 200, formatted, 'Users retrieved successfully');
    } catch (error) {
      next(error);
    }
  },

  async banUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const user = await adminService.banUser(id);
      sendResponse(res, 200, user, 'User banned successfully');
    } catch (error) {
      next(error);
    }
  },

  async unbanUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const user = await adminService.unbanUser(id);
      sendResponse(res, 200, user, 'User unbanned successfully');
    } catch (error) {
      next(error);
    }
  },

  async deleteUser(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      await adminService.deleteUser(id);
      sendResponse(res, 200, null, 'User deleted successfully');
    } catch (error) {
      next(error);
    }
  }
};

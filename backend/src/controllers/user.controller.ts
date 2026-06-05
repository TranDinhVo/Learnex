import { Request, Response, NextFunction } from "express";
import { userService } from "../services/user.service";
import { sendResponse } from "../utils/response";
import { getPaginationParams, buildPaginationInfo } from "../utils/pagination";

export const userController = {
  async getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const user = await userService.getMe(req.user!.userId);
      sendResponse(res, 200, user, "User profile retrieved");
    } catch (error) {
      next(error);
    }
  },

  async updateProfile(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const user = await userService.updateProfile(
        req.user!.userId,
        req.body,
        req.file as Express.Multer.File | undefined,
      );
      sendResponse(res, 200, user, "Profile updated successfully");
    } catch (error) {
      next(error);
    }
  },

  async uploadAvatar(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      if (!req.file) {
        return next(
          new (await import("../utils/AppError")).AppError(
            "Please upload an image file.",
            400,
          ),
        );
      }
      const user = await userService.uploadAvatar(req.user!.userId, req.file);
      sendResponse(res, 200, user, "Avatar uploaded successfully");
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
      const user = await userService.getUserById(req.params.id as string);
      sendResponse(res, 200, user, "User retrieved");
    } catch (error) {
      next(error);
    }
  },

  async searchUsers(
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> {
    try {
      const query = (req.query.q as string) || "";
      const friendsOnly = req.query.friends_only === 'true';
      const pagination = getPaginationParams(
        req.query as { page?: string; limit?: string },
      );
      const { data, total } = await userService.searchUsers(query, pagination, req.user?.userId, friendsOnly);

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

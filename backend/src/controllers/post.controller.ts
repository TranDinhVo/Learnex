import { Request, Response, NextFunction } from 'express';
import { postService } from '../services/post.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams, buildPaginationInfo } from '../utils/pagination';

export const postController = {
  async create(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const post = await postService.create(req.user!.userId, req.body);
      sendResponse(res, 201, post, 'Post created successfully');
    } catch (error) {
      next(error);
    }
  },

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const post = await postService.getById(req.params.id as string, req.user?.userId);
      sendResponse(res, 200, post, 'Post retrieved');
    } catch (error) {
      next(error);
    }
  },

  async update(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const post = await postService.update(req.params.id as string, req.user!.userId, req.body);
      sendResponse(res, 200, post, 'Post updated successfully');
    } catch (error) {
      next(error);
    }
  },

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await postService.delete(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Post deleted successfully');
    } catch (error) {
      next(error);
    }
  },

  async getFeed(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const targetUserId = req.query.userId as string | undefined;
      const { data, total } = await postService.getFeed(pagination, req.user?.userId, targetUserId);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async toggleLike(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await postService.toggleLike(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, result, result.liked ? 'Post liked' : 'Post unliked');
    } catch (error) {
      next(error);
    }
  },

  async toggleSave(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await postService.toggleSave(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, result, result.saved ? 'Post saved' : 'Post unsaved');
    } catch (error) {
      next(error);
    }
  },

  async getSavedPosts(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await postService.getSavedPosts(req.user!.userId, pagination);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async addComment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const comment = await postService.addComment(req.params.id as string, req.user!.userId, req.body.content);
      sendResponse(res, 201, comment, 'Comment added successfully');
    } catch (error) {
      next(error);
    }
  },

  async getComments(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await postService.getComments(req.params.id as string, pagination);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async updateComment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const comment = await postService.updateComment(
        req.params.id as string, 
        req.params.commentId as string, 
        req.user!.userId, 
        req.body.content
      );
      sendResponse(res, 200, comment, 'Comment updated successfully');
    } catch (error) {
      next(error);
    }
  },

  async deleteComment(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await postService.deleteComment(req.params.commentId as string, req.user!.userId);
      sendResponse(res, 200, null, 'Comment deleted successfully');
    } catch (error) {
      next(error);
    }
  },
};

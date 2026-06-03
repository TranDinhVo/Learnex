import { Request, Response, NextFunction } from 'express';
import { storyService } from '../services/story.service';
import { CreateStoryRequest } from '../models/types';
import { sendResponse } from '../utils/response';
import { AppError } from '../utils/AppError';

class StoryController {
  async createStory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const data: CreateStoryRequest = req.body;
      const story = await storyService.createStory(userId, data);
      sendResponse(res, 201, story, 'Story created successfully');
    } catch (error) {
      next(error);
    }
  }

  async getFeedStories(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const feed = await storyService.getFeedStories(userId);
      sendResponse(res, 200, feed, 'Story feed retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  async viewStory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const storyId = req.params.id as string;
      await storyService.viewStory(userId, storyId);
      sendResponse(res, 200, null, 'Story viewed successfully');
    } catch (error) {
      next(error);
    }
  }

  async reactStory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const storyId = req.params.id as string;
      const { emoji } = req.body;
      
      if (!emoji) {
        return next(new AppError('Emoji is required', 400));
      }
      
      await storyService.reactStory(userId, storyId, emoji);
      sendResponse(res, 200, null, 'Reacted to story successfully');
    } catch (error) {
      next(error);
    }
  }

  async getStoryViewers(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const storyId = req.params.id as string;
      const viewers = await storyService.getStoryViewers(userId, storyId);
      sendResponse(res, 200, { viewers, viewCount: viewers.length }, 'Viewers retrieved successfully');
    } catch (error: any) {
      if (error.message.includes('unauthorized')) {
        next(new AppError('Unauthorized to view viewers for this story', 403));
      } else {
        next(error);
      }
    }
  }

  async getArchive(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const archive = await storyService.getArchive(userId);
      sendResponse(res, 200, archive, 'Story archive retrieved successfully');
    } catch (error) {
      next(error);
    }
  }

  async updateStoryPrivacy(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const storyId = req.params.id as string;
      const { visibility, excludedUserIds } = req.body;
      
      const story = await storyService.updateStoryPrivacy(userId, storyId, visibility, excludedUserIds);
      sendResponse(res, 200, story, 'Story privacy updated successfully');
    } catch (error) {
      next(error);
    }
  }

  async deleteStory(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user!.userId;
      const storyId = req.params.id as string;
      await storyService.deleteStory(userId, storyId);
      sendResponse(res, 200, null, 'Story deleted successfully');
    } catch (error) {
      next(error);
    }
  }
}

export const storyController = new StoryController();

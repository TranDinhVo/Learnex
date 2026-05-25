import { Request, Response, NextFunction } from 'express';
import { uploadService } from '../services/upload.service';
import { sendResponse } from '../utils/response';
import { AppError } from '../utils/AppError';

export const uploadController = {
  async uploadImage(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.file) {
        throw new AppError('Please provide an image to upload.', 400);
      }
      const url = await uploadService.handleImageUpload(req.file);
      sendResponse(res, 200, { url }, 'Image uploaded successfully');
    } catch (error) {
      next(error);
    }
  },

  async uploadImages(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.files || !(req.files instanceof Array) || req.files.length === 0) {
        throw new AppError('Please provide images to upload.', 400);
      }
      const urls = await uploadService.handleMultipleImageUpload(req.files);
      sendResponse(res, 200, { urls }, 'Images uploaded successfully');
    } catch (error) {
      next(error);
    }
  },

  async uploadDocument(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.file) {
        throw new AppError('Please provide a document to upload.', 400);
      }
      const result = await uploadService.handleDocumentUpload(req.file);
      sendResponse(res, 200, result, 'Document uploaded successfully');
    } catch (error) {
      next(error);
    }
  },

  async uploadAvatar(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.file) {
        throw new AppError('Please provide an avatar image to upload.', 400);
      }
      const url = await uploadService.handleAvatarUpload(req.file, req.user!.userId);
      sendResponse(res, 200, { url }, 'Avatar uploaded successfully');
    } catch (error) {
      next(error);
    }
  },
};

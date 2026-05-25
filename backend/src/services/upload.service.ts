import { v4 as uuidv4 } from 'uuid';
import { cloudinaryService } from './cloudinary.service';
import { AppError } from '../utils/AppError';

export const uploadService = {
  async handleImageUpload(file: Express.Multer.File): Promise<string> {
    if (!file) {
      throw new AppError('No image file provided.', 400);
    }

    const filename = `img_${uuidv4()}`;
    const url = await cloudinaryService.uploadImage(file.buffer, 'images', filename);
    return url;
  },

  async handleMultipleImageUpload(files: Express.Multer.File[]): Promise<string[]> {
    if (!files || files.length === 0) {
      throw new AppError('No image files provided.', 400);
    }

    const urls: string[] = [];
    for (const file of files) {
      const filename = `img_${uuidv4()}`;
      const url = await cloudinaryService.uploadImage(file.buffer, 'images', filename);
      urls.push(url);
    }

    return urls;
  },

  async handleDocumentUpload(file: Express.Multer.File): Promise<{ url: string; file_size: number; file_type: string }> {
    if (!file) {
      throw new AppError('No document file provided.', 400);
    }

    const filename = `doc_${uuidv4()}`;
    const url = await cloudinaryService.uploadDocument(file.buffer, 'documents', filename);

    return {
      url,
      file_size: file.size,
      file_type: file.mimetype,
    };
  },

  async handleAvatarUpload(file: Express.Multer.File, userId: string): Promise<string> {
    if (!file) {
      throw new AppError('No avatar file provided.', 400);
    }

    const url = await cloudinaryService.uploadAvatar(file.buffer, userId);
    return url;
  },
};

import { cloudinary, uploadFile } from '../config/cloudinary';
import { AppError } from '@/utils/AppError';

export const cloudinaryService = {
  async uploadImage(buffer: Buffer, folder: string, filename: string): Promise<string> {
    try {
      return await uploadFile(buffer, folder, filename);
    } catch (error) {
      throw new AppError('Failed to upload image.', 500);
    }
  },

  async uploadDocument(buffer: Buffer, folder: string, filename: string): Promise<string> {
    try {
      return await uploadFile(buffer, folder, filename);
    } catch (error) {
      throw new AppError('Failed to upload document.', 500);
    }
  },

  async uploadAvatar(buffer: Buffer, userId: string): Promise<string> {
    try {
      return await uploadFile(buffer, 'avatars', `avatar_${userId}`);
    } catch (error) {
      throw new AppError('Failed to upload avatar.', 500);
    }
  },

  async deleteFile(publicId: string): Promise<void> {
    try {
      await cloudinary.uploader.destroy(publicId);
    } catch (error) {
      throw new AppError('Failed to delete file.', 500);
    }
  },
};


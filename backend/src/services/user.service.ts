import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { UserPublic } from '../models/types';
import { PaginationParams } from '../utils/pagination';
import { uploadFile } from '../config/cloudinary';

const USER_PUBLIC_FIELDS = [
  'id', 'email', 'full_name', 'username', 'avatar_url',
  'bio', 'school', 'major', 'role', 'created_at',
];

export const userService = {
  async getMe(userId: string): Promise<UserPublic> {
    const user = await db('users')
      .select(USER_PUBLIC_FIELDS)
      .where({ id: userId })
      .first();

    if (!user) {
      throw new AppError('User not found.', 404);
    }

    return user;
  },

  async updateProfile(
    userId: string,
    data: { full_name?: string; bio?: string; school?: string; major?: string }
  ): Promise<UserPublic> {
    const updateData: Record<string, any> = {};
    if (data.full_name !== undefined) updateData.full_name = data.full_name;
    if (data.bio !== undefined) updateData.bio = data.bio;
    if (data.school !== undefined) updateData.school = data.school;
    if (data.major !== undefined) updateData.major = data.major;

    if (Object.keys(updateData).length === 0) {
      throw new AppError('No fields to update.', 400);
    }

    const [user] = await db('users')
      .where({ id: userId })
      .update(updateData)
      .returning(USER_PUBLIC_FIELDS);

    if (!user) {
      throw new AppError('User not found.', 404);
    }

    return user;
  },

  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<UserPublic> {
    const avatarUrl = await uploadFile(file.buffer, 'avatars', `avatar_${userId}`);

    const [user] = await db('users')
      .where({ id: userId })
      .update({ avatar_url: avatarUrl })
      .returning(USER_PUBLIC_FIELDS);

    if (!user) {
      throw new AppError('User not found.', 404);
    }

    return user;
  },

  async getUserById(userId: string): Promise<UserPublic> {
    const user = await db('users')
      .select(USER_PUBLIC_FIELDS)
      .where({ id: userId })
      .first();

    if (!user) {
      throw new AppError('User not found.', 404);
    }

    return user;
  },

  async searchUsers(
    query: string,
    pagination: PaginationParams
  ): Promise<{ data: UserPublic[]; total: number }> {
    const searchTerm = `%${query}%`;

    const baseQuery = db('users')
      .select(USER_PUBLIC_FIELDS)
      .where(function () {
        this.whereILike('full_name', searchTerm)
          .orWhereILike('username', searchTerm)
          .orWhereILike('email', searchTerm);
      });

    const [{ count }] = await baseQuery.clone().clearSelect().count('* as count');
    const total = parseInt(count as string, 10);

    const data = await baseQuery
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit)
      .orderBy('full_name', 'asc');

    return { data, total };
  },
};

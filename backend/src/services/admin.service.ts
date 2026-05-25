import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { PaginationParams } from '../utils/pagination';

export const adminService = {
  async getDashboardStats() {
    const [{ count: userCount }] = await db('users').count('* as count');
    const [{ count: postCount }] = await db('posts').count('* as count');
    const [{ count: docCount }] = await db('documents').count('* as count');
    const [{ count: roomCount }] = await db('rooms').count('* as count');

    const totalUsers = parseInt(userCount as string, 10);
    const totalPosts = parseInt(postCount as string, 10);
    const totalDocuments = parseInt(docCount as string, 10);
    const totalRooms = parseInt(roomCount as string, 10);

    // Mock chart data for premium visualization
    const userGrowth = [
      { name: 'T2', value: Math.max(0, totalUsers - 3) },
      { name: 'T3', value: Math.max(0, totalUsers - 2) },
      { name: 'T4', value: Math.max(0, totalUsers - 1) },
      { name: 'T5', value: totalUsers }
    ];

    const documentStats = [
      { name: 'Đã duyệt', value: totalDocuments, color: '#10b981' },
      { name: 'Đang chờ', value: 0, color: '#f59e0b' }
    ];

    return {
      totalUsers,
      totalPosts,
      totalDocuments,
      totalRooms,
      activeUsers: 2,
      newUsersToday: 1,
      newPostsToday: 1,
      pendingDocuments: 0,
      userGrowth,
      documentStats
    };
  },

  async getAllUsers(pagination: PaginationParams) {
    let query = db('users').select('id', 'email', 'full_name', 'username', 'avatar_url', 'role', 'is_banned', 'created_at');

    if (pagination.search) {
      const searchPattern = `%${pagination.search}%`;
      query = query.where(function () {
        this.where('full_name', 'ILIKE', searchPattern)
            .orWhere('email', 'ILIKE', searchPattern)
            .orWhere('username', 'ILIKE', searchPattern);
      });
    }

    const [{ count }] = await db('users').count('* as count');
    const total = parseInt(count as string, 10);

    const data = await query
      .orderBy('created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async banUser(id: string) {
    const user = await db('users').where({ id }).first();
    if (!user) throw new AppError('User not found.', 404);
    if (user.role === 'admin') throw new AppError('Cannot ban an administrator.', 400);

    const [updated] = await db('users')
      .where({ id })
      .update({ is_banned: true })
      .returning('*');

    return updated;
  },

  async unbanUser(id: string) {
    const user = await db('users').where({ id }).first();
    if (!user) throw new AppError('User not found.', 404);

    const [updated] = await db('users')
      .where({ id })
      .update({ is_banned: false })
      .returning('*');

    return updated;
  },

  async deleteUser(id: string) {
    const user = await db('users').where({ id }).first();
    if (!user) throw new AppError('User not found.', 404);
    if (user.role === 'admin') throw new AppError('Cannot delete an administrator.', 400);

    await db('users').where({ id }).del();
  }
};

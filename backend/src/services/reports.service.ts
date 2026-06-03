import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { PaginationParams } from '../utils/pagination';

export const reportsService = {
  // CREATE
  async createReport(reporterId: string, data: { targetType: string, targetId: string, reason: string }) {
    if (!['user', 'post', 'comment', 'room'].includes(data.targetType)) {
      throw new AppError('Loại đối tượng báo cáo không hợp lệ.', 400);
    }

    const [report] = await db('reports').insert({
      reporter_id: reporterId,
      target_type: data.targetType,
      target_id: data.targetId,
      reason: data.reason,
      status: 'pending'
    }).returning('*');

    return report;
  },

  // READ (For Admin)
  async getReports(pagination: PaginationParams) {
    let query = db('reports as r')
      .select(
        'r.id',
        'r.target_type',
        'r.target_id',
        'r.reason',
        'r.status',
        'r.created_at',
        'u.id as reporter_id',
        'u.full_name as reporter_name',
        'u.avatar_url as reporter_avatar'
      )
      .leftJoin('users as u', 'r.reporter_id', 'u.id');

    if (pagination.search) {
      const searchPattern = `%${pagination.search}%`;
      query = query.where('r.reason', 'ILIKE', searchPattern);
    }

    const [{ count }] = await db('reports').count('* as count');
    const total = parseInt(count as string, 10);

    const data = await query
      .orderBy('r.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    // Bổ sung thông tin đối tượng bị báo cáo (tuỳ theo target_type)
    const enrichedData = await Promise.all(data.map(async (r) => {
      let targetInfo: any = { _id: r.target_id };

      if (r.target_type === 'user') {
        const user = await db('users').where('id', r.target_id).first('full_name', 'email');
        if (user) targetInfo.name = user.full_name;
      } else if (r.target_type === 'post') {
        const post = await db('posts').where('id', r.target_id).first('content');
        if (post) targetInfo.content = post.content;
      } else if (r.target_type === 'room') {
        const room = await db('rooms').where('id', r.target_id).first('name');
        if (room) targetInfo.name = room.name;
      }

      return {
        _id: r.id,
        reporter: {
          _id: r.reporter_id,
          name: r.reporter_name || 'Ẩn danh',
          avatar: r.reporter_avatar
        },
        targetType: r.target_type,
        targetId: r.target_id,
        targetInfo,
        reason: r.reason,
        status: r.status,
        createdAt: r.created_at
      };
    }));

    return { data: enrichedData, total };
  },

  // UPDATE STATUS
  async updateReportStatus(id: string, status: 'resolved' | 'dismissed') {
    if (!['resolved', 'dismissed'].includes(status)) {
      throw new AppError('Trạng thái không hợp lệ.', 400);
    }

    const report = await db('reports').where({ id }).first();
    if (!report) throw new AppError('Không tìm thấy báo cáo.', 404);

    const [updated] = await db('reports')
      .where({ id })
      .update({ status })
      .returning('*');

    return updated;
  }
};

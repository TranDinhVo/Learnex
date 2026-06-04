import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { PaginationParams } from '../utils/pagination';
import { fcmService } from './fcm.service';
import { notificationService } from './notification.service';
import { cloudinaryService } from './cloudinary.service';
import { webSocketService } from './websocket.service';

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

    const pendingDocs = await db('documents').whereNull('is_approved').count('* as count');
    const pendingDocuments = parseInt(pendingDocs[0].count as string, 10);

    // Lấy số lượng người dùng mới hôm nay
    const [{ count: newUsersTodayCount }] = await db('users')
      .whereRaw('DATE(created_at) = CURRENT_DATE')
      .count('* as count');
    const newUsersToday = parseInt(newUsersTodayCount as string, 10);

    // Lấy số lượng bài viết mới hôm nay
    const [{ count: newPostsTodayCount }] = await db('posts')
      .whereRaw('DATE(created_at) = CURRENT_DATE')
      .count('* as count');
    const newPostsToday = parseInt(newPostsTodayCount as string, 10);

    // Lấy dữ liệu tăng trưởng người dùng 7 ngày gần nhất (tính cả hôm nay)
    const rawGrowth = await db('users')
      .select(db.raw('DATE(created_at) as date'))
      .count('* as count')
      .whereRaw('created_at >= CURRENT_DATE - INTERVAL \'6 days\'')
      .groupByRaw('DATE(created_at)')
      .orderByRaw('DATE(created_at) ASC');

    // Chuyển đổi dữ liệu thô thành format cho biểu đồ
    // Tạo danh sách 7 ngày gần nhất để điền số 0 nếu ngày đó không có ai đăng ký
    const userGrowth = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date();
      d.setDate(d.getDate() - i);
      const dateStr = d.toISOString().split('T')[0];
      
      const found = rawGrowth.find((r: any) => {
        const rDate = new Date(r.date);
        return rDate.toISOString().split('T')[0] === dateStr;
      });

      userGrowth.push({
        name: `${d.getDate()}/${d.getMonth() + 1}`,
        value: found ? parseInt(found.count as string, 10) : 0
      });
    }

    const approvedDocs = await db('documents').where('is_approved', true).count('* as count');
    const approvedCount = parseInt(approvedDocs[0].count as string, 10);

    const documentStats = [
      { name: 'Đã duyệt', value: approvedCount, color: '#10b981' },
      { name: 'Đang chờ', value: pendingDocuments, color: '#f59e0b' }
    ];

    return {
      totalUsers,
      totalPosts,
      totalDocuments,
      totalRooms,
      activeUsers: Math.max(2, totalUsers),
      newUsersToday,
      newPostsToday,
      pendingDocuments,
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
  },

  async updateUserRole(id: string, role: string) {
    if (role !== 'admin' && role !== 'user') {
      throw new AppError('Invalid role specified.', 400);
    }
    const user = await db('users').where({ id }).first();
    if (!user) throw new AppError('User not found.', 404);

    const [updated] = await db('users')
      .where({ id })
      .update({ role })
      .returning('*');
    return updated;
  },

  // ── Posts Moderation ──
  async getAllPosts(pagination: PaginationParams) {
    let query = db('posts as p')
      .select(
        'p.id',
        'p.content',
        'p.image_urls',
        'p.is_deleted as isHidden',
        'p.created_at',
        'p.updated_at',
        'u.id as author_id',
        'u.full_name as author_name',
        'u.email as author_email',
        'u.avatar_url as author_avatar'
      )
      .leftJoin('users as u', 'p.user_id', 'u.id');

    if (pagination.search) {
      const searchPattern = `%${pagination.search}%`;
      query = query.where('p.content', 'ILIKE', searchPattern);
    }

    const [{ count }] = await db('posts').count('* as count');
    const total = parseInt(count as string, 10);

    const rawData = await query
      .orderBy('p.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    const data = rawData.map(p => ({
      _id: p.id,
      content: p.content || '',
      isHidden: p.isHidden || false,
      images: p.image_urls || [],
      likes: [],
      comments: [],
      createdAt: p.created_at,
      updatedAt: p.updated_at,
      author: {
        _id: p.author_id,
        name: p.author_name || 'Học viên LearnEx',
        email: p.author_email || '',
        avatar: p.author_avatar
      }
    }));

    return { data, total };
  },

  async hidePost(id: string, reason?: string) {
    const post = await db('posts').where({ id }).first();
    if (!post) throw new AppError('Post not found.', 404);

    await db('posts').where({ id }).update({ is_deleted: true });
    
    const finalReason = reason && reason.trim() ? reason.trim() : 'Vi phạm Tiêu chuẩn cộng đồng';
    await notificationService.create({
      user_id: post.user_id,
      type: 'system',
      title: 'Bài viết bị ẩn',
      body: `Bài viết của bạn đã bị ẩn khỏi cộng đồng. Lý do: ${finalReason}`,
      ref_type: 'post',
      ref_id: id,
    });

    const user = await db('users').where({ id: post.user_id }).first();
    if (user && user.fcm_token) {
      fcmService.sendMultiplePush([user.fcm_token], 'Bài viết bị ẩn', `Bài viết của bạn đã bị ẩn khỏi cộng đồng. Lý do: ${finalReason}`, { type: 'system', ref_type: 'post', ref_id: id }).catch(console.error);
    }

    // Fetch and return the updated post
    const updated = await db('posts').where({ id }).first();
    return updated;
  },

  async unhidePost(id: string) {
    const post = await db('posts').where({ id }).first();
    if (!post) throw new AppError('Post not found.', 404);

    await db('posts').where({ id }).update({ is_deleted: false });

    // Fetch and return the updated post
    const updated = await db('posts').where({ id }).first();
    return updated;
  },

  async deletePost(id: string, reason?: string) {
    const post = await db('posts').where({ id }).first();
    if (!post) throw new AppError('Post not found.', 404);

    await db('posts').where({ id }).del();

    const finalReason = reason && reason.trim() ? reason.trim() : 'Vi phạm Tiêu chuẩn cộng đồng';
    await notificationService.create({
      user_id: post.user_id,
      type: 'system',
      title: 'Bài viết đã bị xóa',
      body: `Bài đăng của bạn đã bị xóa vĩnh viễn khỏi hệ thống. Lý do: ${finalReason}`,
      ref_type: 'post',
    });

    const user = await db('users').where({ id: post.user_id }).first();
    if (user && user.fcm_token) {
      fcmService.sendMultiplePush([user.fcm_token], 'Bài viết đã bị xóa', `Bài đăng của bạn đã bị xóa vĩnh viễn khỏi hệ thống. Lý do: ${finalReason}`, { type: 'system' }).catch(console.error);
    }
  },

  // ── Documents Management ──
  async getAllDocuments(pagination: PaginationParams) {
    let query = db('documents as d')
      .select(
        'd.id',
        'd.title',
        'd.description',
        'd.file_url',
        'd.file_type',
        'd.download_count',
        'd.is_approved',
        'd.created_at',
        'u.id as uploader_id',
        'u.full_name as uploader_name',
        'u.email as uploader_email',
        'u.avatar_url as uploader_avatar'
      )
      .leftJoin('users as u', 'd.user_id', 'u.id');

    if (pagination.search) {
      const searchPattern = `%${pagination.search}%`;
      query = query.where('d.title', 'ILIKE', searchPattern)
                   .orWhere('d.description', 'ILIKE', searchPattern);
    }

    const [{ count }] = await db('documents').count('* as count');
    const total = parseInt(count as string, 10);

    const rawData = await query
      .orderBy('d.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    const data = rawData.map(d => {
      let status: 'pending' | 'approved' | 'rejected' = 'pending';
      if (d.is_approved === true) status = 'approved';
      if (d.is_approved === false) status = 'rejected';

      return {
        _id: d.id,
        title: d.title,
        description: d.description || '',
        fileUrl: d.file_url,
        fileType: d.file_type || 'pdf',
        status,
        downloads: d.download_count || 0,
        createdAt: d.created_at,
        updatedAt: d.created_at,
        uploadedBy: {
          _id: d.uploader_id,
          name: d.uploader_name || 'Học viên LearnEx',
          email: d.uploader_email || '',
          avatar: d.uploader_avatar
        }
      };
    });

    return { data, total };
  },

  async approveDocument(id: string) {
    const doc = await db('documents').where({ id }).first();
    if (!doc) throw new AppError('Document not found.', 404);

    await db('documents').where({ id }).update({ is_approved: true });

    await notificationService.create({
      user_id: doc.user_id,
      type: 'system',
      title: 'Tài liệu đã được duyệt',
      body: `Tài liệu "${doc.title}" của bạn đã được phê duyệt và hiển thị công khai.`,
      ref_type: 'document',
      ref_id: id,
    });

    const user = await db('users').where({ id: doc.user_id }).first();
    if (user && user.fcm_token) {
      fcmService.sendMultiplePush([user.fcm_token], 'Tài liệu đã được duyệt', `Tài liệu "${doc.title}" của bạn đã được phê duyệt và hiển thị công khai.`, { type: 'system', ref_type: 'document', ref_id: id }).catch(console.error);
    }
    
    const updated = await db('documents').where({ id }).first();
    return updated;
  },

  async rejectDocument(id: string, reason?: string) {
    const doc = await db('documents').where({ id }).first();
    if (!doc) throw new AppError('Document not found.', 404);

    await db('documents').where({ id }).update({ is_approved: false });

    const finalReason = reason && reason.trim() ? reason.trim() : 'Không đạt chất lượng chuyên môn';
    await notificationService.create({
      user_id: doc.user_id,
      type: 'system',
      title: 'Tài liệu bị từ chối',
      body: `Tài liệu "${doc.title}" của bạn đã bị từ chối. Lý do: ${finalReason}`,
      ref_type: 'document',
      ref_id: id,
    });

    const user = await db('users').where({ id: doc.user_id }).first();
    if (user && user.fcm_token) {
      fcmService.sendMultiplePush([user.fcm_token], 'Tài liệu bị từ chối', `Tài liệu "${doc.title}" của bạn đã bị từ chối. Lý do: ${finalReason}`, { type: 'system', ref_type: 'document', ref_id: id }).catch(console.error);
    }

    const updated = await db('documents').where({ id }).first();
    return updated;
  },

  async deleteDocument(id: string, reason?: string) {
    const doc = await db('documents').where({ id }).first();
    if (!doc) throw new AppError('Document not found.', 404);

    // Delete from Cloudinary if valid url
    if (doc.file_url) {
      try {
        const match = doc.file_url.match(/learnex\/(.*?)(?:\.[a-zA-Z0-9]+)?$/);
        if (match && match[1]) {
          await cloudinaryService.deleteFile(`learnex/${match[1]}`);
        }
      } catch (err) {
        console.error('Failed to delete document from Cloudinary:', err);
      }
    }

    await db('documents').where({ id }).del();

    const finalReason = reason && reason.trim() ? reason.trim() : 'Vi phạm quy định nền tảng';
    await notificationService.create({
      user_id: doc.user_id,
      type: 'system',
      title: 'Tài liệu đã bị xóa',
      body: `Tài liệu "${doc.title}" của bạn đã bị xóa vĩnh viễn khỏi hệ thống. Lý do: ${finalReason}`,
      ref_type: 'document',
    });

    const user = await db('users').where({ id: doc.user_id }).first();
    if (user && user.fcm_token) {
      fcmService.sendMultiplePush([user.fcm_token], 'Tài liệu đã bị xóa', `Tài liệu "${doc.title}" của bạn đã bị xóa vĩnh viễn khỏi hệ thống. Lý do: ${finalReason}`, { type: 'system' }).catch(console.error);
    }
  },

  // ── Rooms Moderation ──
  async getAllRooms(pagination: PaginationParams) {
    let query = db('rooms as r')
      .select(
        'r.id',
        'r.name',
        'r.description',
        'r.is_private',
        'r.created_at',
        'u.id as creator_id',
        'u.full_name as creator_name',
        'u.email as creator_email',
        'u.avatar_url as creator_avatar'
      )
      .leftJoin('users as u', 'r.owner_id', 'u.id');

    if (pagination.search) {
      const searchPattern = `%${pagination.search}%`;
      query = query.where('r.name', 'ILIKE', searchPattern)
                   .orWhere('r.description', 'ILIKE', searchPattern);
    }

    const [{ count }] = await db('rooms').count('* as count');
    const total = parseInt(count as string, 10);

    const rawData = await query
      .orderBy('r.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    const data = await Promise.all(rawData.map(async r => {
      const membersRaw = await db('room_members as rm')
        .select('u.id', 'u.full_name', 'u.avatar_url')
        .leftJoin('users as u', 'rm.user_id', 'u.id')
        .where('rm.room_id', r.id);

      const members = membersRaw.map(m => ({
        _id: m.id,
        name: m.full_name,
        avatar: m.avatar_url
      }));

      return {
        _id: r.id,
        name: r.name,
        description: r.description || '',
        isActive: true,
        isPrivate: r.is_private || false,
        maxMembers: 50,
        createdAt: r.created_at,
        updatedAt: r.created_at,
        creator: {
          _id: r.creator_id,
          name: r.creator_name || 'Học viên LearnEx',
          email: r.creator_email || '',
          avatar: r.creator_avatar
        },
        members
      };
    }));

    return { data, total };
  },

  async deleteRoom(id: string, reason?: string) {
    const room = await db('rooms').where({ id }).first();
    if (!room) throw new AppError('Room not found.', 404);

    const members = await db('room_members').where({ room_id: id });
    const memberIds = members.map(m => m.user_id);

    const finalReason = reason && reason.trim() ? reason.trim() : 'Vi phạm tiêu chuẩn cộng đồng';

    webSocketService.emitToUsers(memberIds, {
      type: 'room_closed',
      data: {
        roomId: id,
        roomName: room.name,
        reason: finalReason
      }
    });

    await db('rooms').where({ id }).del();

    await notificationService.create({
      user_id: room.owner_id,
      type: 'system',
      title: 'Phòng học đã bị giải tán',
      body: `Phòng học "${room.name}" của bạn đã bị Admin giải tán. Lý do: ${finalReason}`,
      ref_type: 'room',
    });

    const user = await db('users').where({ id: room.owner_id }).first();
    if (user && user.fcm_token) {
      fcmService.sendMultiplePush([user.fcm_token], 'Phòng học đã bị giải tán', `Phòng học "${room.name}" của bạn đã bị Admin giải tán. Lý do: ${finalReason}`, { type: 'system' }).catch(console.error);
    }
  },

  // ── System Notifications ──
  async sendNotification(senderId: string, data: { title: string; message: string; type: string; targetAudience: string; targetUsers?: string[] }) {
    let query = db('users').select('id', 'fcm_token');
    
    if (data.targetAudience === 'specific' && data.targetUsers && data.targetUsers.length > 0) {
      query = query.whereIn('id', data.targetUsers);
    }
    
    const users = await query;
    
    const notifications = users.map(u => ({
      user_id: u.id,
      title: data.title,
      body: data.message,
      type: data.type || 'info',
      ref_type: 'system',
      is_read: false
    }));

    if (notifications.length > 0) {
      await db('notifications').insert(notifications);
    }

    const tokens = users.map(u => u.fcm_token).filter(t => t != null && t.trim() !== '');
    if (tokens.length > 0) {
      fcmService.sendMultiplePush(tokens, data.title, data.message, { type: 'system' }).catch(err => {
        console.error('Lỗi khi gửi Push Notification trong Admin Service:', err);
      });
    }

    return {
      _id: 'sys_' + Date.now(),
      title: data.title,
      message: data.message,
      type: data.type || 'info',
      targetAudience: data.targetAudience,
      createdAt: new Date().toISOString(),
      sentBy: {
        _id: senderId,
        name: 'Administrator'
      }
    };
  },

  async getNotificationHistory(pagination: PaginationParams) {
    const rawData = await db('notifications')
      .where('ref_type', 'system')
      .select('title', 'body', 'type', 'created_at')
      .groupBy('title', 'body', 'type', 'created_at')
      .orderBy('created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    const countQuery = await db('notifications')
      .where('ref_type', 'system')
      .countDistinct('title as count');
    const total = parseInt(countQuery[0].count as string, 10) || rawData.length;

    const data = rawData.map((n, idx) => ({
      _id: 'sys_' + idx + '_' + new Date(n.created_at).getTime(),
      title: n.title,
      message: n.body || '',
      type: n.type || 'info',
      targetAudience: 'all',
      createdAt: n.created_at,
      sentBy: {
        _id: 'admin_id',
        name: 'Administrator'
      }
    }));

    return { data, total };
  },

  // ── System Settings ──
  async getSettings() {
    const rawSettings = await db('system_settings').select('*');
    return rawSettings.map(s => ({
      key: s.key,
      value: s.value,
      description: s.description,
      updated_at: s.updated_at
    }));
  },

  async updateSettings(settingsData: { key: string; value: string }[]) {
    // Start a transaction to ensure all updates succeed or fail together
    await db.transaction(async (trx) => {
      for (const setting of settingsData) {
        await trx('system_settings')
          .where({ key: setting.key })
          .update({ value: setting.value });
      }
    });

    return await this.getSettings();
  }
};


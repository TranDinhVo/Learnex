import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { Room, RoomMember, RoomMessage, RoomMessageRead } from '../models/types';
import { PaginationParams } from '../utils/pagination';
import { notificationService } from './notification.service';
import { uploadService } from './upload.service';

export const roomService = {
  async create(userId: string, data: { name: string; description?: string; privacy_mode?: 'public' | 'private' | 'approval' }): Promise<Room> {
    const [room] = await db('rooms')
      .insert({
        owner_id: userId,
        name: data.name,
        description: data.description || null,
        privacy_mode: data.privacy_mode || 'public',
      })
      .returning('*');

    // Auto-add creator as owner member
    await db('room_members').insert({
      room_id: room.id,
      user_id: userId,
      role: 'owner',
    });

    return room;
  },

  async getById(roomId: string, currentUserId?: string): Promise<any> {
    const room = await db('rooms as r')
      .select(
        'r.*',
        'u.full_name as owner_name',
        'u.username as owner_username',
        'u.avatar_url as owner_avatar',
        db.raw('(SELECT COUNT(*) FROM room_members WHERE room_id = r.id)::int as member_count'),
      )
      .leftJoin('users as u', 'r.owner_id', 'u.id')
      .where('r.id', roomId)
      .first();

    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    if (currentUserId) {
      const member = await db('room_members').where({ room_id: roomId, user_id: currentUserId }).first();
      room.is_member = !!member;
      room.user_role = member ? member.role : null;
    } else {
      room.is_member = false;
      room.user_role = null;
    }

    return room;
  },

  async getAll(
    pagination: PaginationParams,
    currentUserId?: string,
    search?: string
  ): Promise<{ data: any[]; total: number }> {
    const query = db('rooms as r')
      .select(
        'r.*',
        'u.full_name as owner_name',
        'u.username as owner_username',
        'u.avatar_url as owner_avatar',
        db.raw('(SELECT COUNT(*) FROM room_members WHERE room_id = r.id)::int as member_count'),
      )
      .leftJoin('users as u', 'r.owner_id', 'u.id')
      .where(function () {
        this.where('r.privacy_mode', 'public')
            .orWhere('r.privacy_mode', 'approval');
        if (currentUserId) {
          this.orWhereIn('r.id', db('room_members').select('room_id').where('user_id', currentUserId));
        }
      });

    if (search) {
      query.andWhere('r.name', 'ilike', `%${search}%`);
    }

    const countQuery = db('rooms as r')
      .where(function () {
        this.where('r.privacy_mode', 'public')
            .orWhere('r.privacy_mode', 'approval');
        if (currentUserId) {
          this.orWhereIn('r.id', db('room_members').select('room_id').where('user_id', currentUserId));
        }
      });

    if (search) {
      countQuery.andWhere('r.name', 'ilike', `%${search}%`);
    }

    const [{ count }] = await countQuery.count('* as count');
    const total = parseInt(count as string, 10);

    const data = await query
      .orderBy('r.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    if (currentUserId) {
      const memberRoomIds = new Set(
        (await db('room_members').select('room_id').where('user_id', currentUserId)).map((m) => m.room_id)
      );
      
      const pendingRoomIds = new Set(
        (await db('room_join_requests').select('room_id').where({ user_id: currentUserId, status: 'pending' })).map(r => r.room_id)
      );

      data.forEach((r) => {
        r.is_member = memberRoomIds.has(r.id);
        r.is_pending = pendingRoomIds.has(r.id);
      });
    } else {
      data.forEach((r) => {
        r.is_member = false;
        r.is_pending = false;
      });
    }

    return { data, total };
  },

  async update(roomId: string, userId: string, data: { name?: string; description?: string; privacy_mode?: 'public' | 'private' | 'approval'; avatar_url?: string }): Promise<Room> {
    const room = await db('rooms').where({ id: roomId, owner_id: userId }).first();
    if (!room) {
      throw new AppError('Room not found or you are not the owner.', 404);
    }

    const updateData: Record<string, any> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.privacy_mode !== undefined) updateData.privacy_mode = data.privacy_mode;
    if (data.avatar_url !== undefined) updateData.avatar_url = data.avatar_url;

    const [updated] = await db('rooms')
      .where({ id: roomId })
      .update(updateData)
      .returning('*');

    return updated;
  },

  async uploadAvatar(roomId: string, userId: string, file: Express.Multer.File): Promise<string> {
    const room = await db('rooms').where({ id: roomId, owner_id: userId }).first();
    if (!room) {
      throw new AppError('Room not found or you are not the owner.', 404);
    }

    const url = await uploadService.handleImageUpload(file);
    await db('rooms').where({ id: roomId }).update({ avatar_url: url });
    return url;
  },

  async delete(roomId: string, userId: string): Promise<void> {
    const room = await db('rooms').where({ id: roomId, owner_id: userId }).first();
    if (!room) {
      throw new AppError('Room not found or you are not the owner.', 404);
    }

    // Cleanup: messages and members will cascade due to FK
    await db('rooms').where({ id: roomId }).del();
  },

  async join(roomId: string, userId: string): Promise<RoomMember | { status: 'pending' }> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    if (room.privacy_mode === 'private') {
      // Check if user has an invite notification
      const inviteNotification = await db('notifications')
        .where({ user_id: userId, type: 'room_invite', ref_id: roomId })
        .first();

      if (!inviteNotification) {
        throw new AppError('This room is private. You need an invitation to join.', 403);
      }
      
      // Delete the notification since they joined
      await db('notifications').where({ id: inviteNotification.id }).del();
    } else if (room.privacy_mode === 'approval') {
      const request = await db('room_join_requests')
        .where({ room_id: roomId, user_id: userId })
        .first();

      if (request && request.status === 'approved') {
        // Pre-approved (e.g., invited by mod/owner)
        await db('room_join_requests').where({ id: request.id }).del();
      } else if (request && request.status === 'pending') {
        return { status: 'pending' };
      } else {
        // Insert pending request
        await db('room_join_requests').insert({
          room_id: roomId,
          user_id: userId,
          status: 'pending'
        });

        const admins = await db('room_members')
          .where({ room_id: roomId })
          .whereIn('role', ['owner', 'moderator']);
        
        const requester = await db('users').where({ id: userId }).first();
        const wsService = require('./websocket.service').WebSocketService.getInstance();
        
        for (const admin of admins) {
          const notif = await notificationService.create({
            user_id: admin.user_id,
            type: 'room_join_request',
            title: 'Yêu cầu tham gia phòng',
            body: `${requester?.full_name || 'Ai đó'} yêu cầu tham gia phòng ${room.name}`,
            ref_type: 'room',
            ref_id: roomId,
          });
          
          wsService.sendToUser(admin.user_id, {
            type: 'new_notification',
            data: notif
          });
        }

        return { status: 'pending' };
      }
    }

    const existing = await db('room_members').where({ room_id: roomId, user_id: userId }).first();
    if (existing) {
      throw new AppError('You are already a member of this room.', 400);
    }

    const [member] = await db('room_members')
      .insert({ room_id: roomId, user_id: userId, role: 'member' })
      .returning('*');

    // Create system message
    const user = await db('users').where({ id: userId }).first();
    if (user) {
      const [sysMsg] = await db('room_messages').insert({
        room_id: roomId,
        sender_id: null,
        content: `[SYSTEM]:user_joined:${userId}:${user.full_name}`,
      }).returning('*');

      // Broadast via websocket
      const wsService = require('./websocket.service').webSocketService;
      const members = await this.getMembers(roomId);
      for (const m of members) {
        wsService.sendToUser(m.user_id, {
          type: 'room_message',
          data: {
            ...sysMsg,
            sender_name: 'Hệ thống',
            sender_username: 'system',
            sender_avatar: null,
          }
        });
      }
    }

    return member;
  },

  async leave(roomId: string, userId: string): Promise<void> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    if (room.owner_id === userId) {
      throw new AppError('Room owner cannot leave. Transfer ownership or delete the room.', 400);
    }

    const result = await db('room_members').where({ room_id: roomId, user_id: userId }).del();
    if (!result) {
      throw new AppError('You are not a member of this room.', 400);
    }
  },

  async getMembers(roomId: string): Promise<any[]> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    const members = await db('room_members as rm')
      .select(
        'rm.id',
        'rm.role',
        'rm.joined_at',
        'u.id as user_id',
        'u.full_name',
        'u.username',
        'u.avatar_url',
      )
      .leftJoin('users as u', 'rm.user_id', 'u.id')
      .where('rm.room_id', roomId)
      .orderBy('rm.joined_at', 'asc');

    return members;
  },

  async kick(roomId: string, requesterId: string, targetUserId: string): Promise<void> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    // Check requester is owner or moderator
    const requesterMember = await db('room_members')
      .where({ room_id: roomId, user_id: requesterId })
      .first();

    if (!requesterMember || !['owner', 'moderator'].includes(requesterMember.role)) {
      throw new AppError('You do not have permission to kick members.', 403);
    }

    // Cannot kick the owner
    if (targetUserId === room.owner_id) {
      throw new AppError('Cannot kick the room owner.', 400);
    }
    
    // Check target's role
    const targetMember = await db('room_members').where({ room_id: roomId, user_id: targetUserId }).first();
    if (!targetMember) {
      throw new AppError('Target user is not a member of this room.', 404);
    }

    if (requesterMember.role === 'moderator' && targetMember.role === 'moderator') {
      throw new AppError('Moderators cannot kick other moderators.', 403);
    }

    const result = await db('room_members')
      .where({ room_id: roomId, user_id: targetUserId })
      .del();

    if (!result) {
      throw new AppError('Target user is not a member of this room.', 404);
    }

    // Create system message
    const targetUser = await db('users').where({ id: targetUserId }).first();
    const requesterUser = await db('users').where({ id: requesterId }).first();
    if (targetUser && requesterUser) {
      const [sysMsg] = await db('room_messages').insert({
        room_id: roomId,
        sender_id: null,
        content: `[SYSTEM]:user_kicked:${targetUserId}:${targetUser.full_name}:${requesterId}:${requesterUser.full_name}`,
      }).returning('*');

      // Broadast via websocket
      const wsService = require('./websocket.service').webSocketService;
      const members = await this.getMembers(roomId);
      for (const m of members) {
        wsService.sendToUser(m.user_id, {
          type: 'room_message',
          data: {
            ...sysMsg,
            sender_name: 'Hệ thống',
            sender_username: 'system',
            sender_avatar: null,
          }
        });
      }
    }
  },

  async invite(roomId: string, inviterId: string, targetUserId: string): Promise<void> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    // Check inviter is a member
    const inviterMember = await db('room_members')
      .where({ room_id: roomId, user_id: inviterId })
      .first();

    if (!inviterMember) {
      throw new AppError('You are not a member of this room.', 403);
    }

    // Check target user exists
    const targetUser = await db('users').where({ id: targetUserId }).first();
    if (!targetUser) {
      throw new AppError('User not found.', 404);
    }

    // Check if already a member
    const existing = await db('room_members')
      .where({ room_id: roomId, user_id: targetUserId })
      .first();

    if (existing) {
      throw new AppError('User is already a member of this room.', 400);
    }

    // Check if an invite already exists
    const existingInvite = await db('notifications')
      .where({ user_id: targetUserId, type: 'room_invite', ref_id: roomId })
      .first();

    if (existingInvite) {
      throw new AppError('User has already been invited.', 400);
    }

    // Send notification
    const inviter = await db('users').where({ id: inviterId }).select('full_name').first();
    await notificationService.create({
      user_id: targetUserId,
      type: 'room_invite',
      title: 'Room Invitation',
      body: `${inviter?.full_name || 'Someone'} invited you to join "${room.name}".`,
      ref_type: 'room',
      ref_id: roomId,
    });

    if (room.privacy_mode === 'approval' && ['owner', 'moderator'].includes(inviterMember.role)) {
      // Pre-approve this user since owner/mod invited them
      const existingReq = await db('room_join_requests').where({ room_id: roomId, user_id: targetUserId }).first();
      if (!existingReq) {
        await db('room_join_requests').insert({
          room_id: roomId,
          user_id: targetUserId,
          status: 'approved'
        });
      } else {
        await db('room_join_requests').where({ id: existingReq.id }).update({ status: 'approved' });
      }
    }
  },

  async sendMessage(
    roomId: string,
    senderId: string,
    data: { content?: string; file_url?: string }
  ): Promise<RoomMessage> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    // Check sender is a member
    const member = await db('room_members')
      .where({ room_id: roomId, user_id: senderId })
      .first();

    if (!member) {
      throw new AppError('You are not a member of this room.', 403);
    }

    if (!data.content && !data.file_url) {
      throw new AppError('Message must have content or a file.', 400);
    }

    const [message] = await db('room_messages')
      .insert({
        room_id: roomId,
        sender_id: senderId,
        content: data.content || null,
        file_url: data.file_url || null,
      })
      .returning('*');

    return message;
  },

  async getMessages(
    roomId: string,
    userId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    // Check user is a member
    const member = await db('room_members')
      .where({ room_id: roomId, user_id: userId })
      .first();

    if (!member) {
      throw new AppError('You are not a member of this room.', 403);
    }

    const [{ count }] = await db('room_messages')
      .where({ room_id: roomId })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const messages = await db('room_messages as rm')
      .select(
        'rm.*',
        'u.full_name as sender_name',
        'u.username as sender_username',
        'u.avatar_url as sender_avatar',
      )
      .leftJoin('users as u', 'rm.sender_id', 'u.id')
      .where('rm.room_id', roomId)
      .orderBy('rm.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data: messages, total };
  },

  async updateMemberRole(roomId: string, requesterId: string, targetUserId: string, newRole: 'owner' | 'moderator' | 'member'): Promise<void> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    if (room.owner_id !== requesterId) {
      throw new AppError('Only the room owner can change roles.', 403);
    }

    if (requesterId === targetUserId) {
      throw new AppError('You cannot change your own role this way.', 400);
    }

    const targetMember = await db('room_members').where({ room_id: roomId, user_id: targetUserId }).first();
    if (!targetMember) {
      throw new AppError('Target user is not a member of this room.', 404);
    }

    await db('room_members')
      .where({ room_id: roomId, user_id: targetUserId })
      .update({ role: newRole });
  },

  async markMessagesRead(roomId: string, userId: string, messageIds: string[]): Promise<void> {
    // Upsert into room_message_reads
    const insertData = messageIds.map(id => ({
      message_id: id,
      user_id: userId,
    }));

    if (insertData.length > 0) {
      await db('room_message_reads')
        .insert(insertData)
        .onConflict(['message_id', 'user_id'])
        .ignore();
    }
  },

  async getReadReceipts(roomId: string, messageIds: string[]): Promise<any> {
    const receipts = await db('room_message_reads as rmr')
      .select('rmr.message_id', 'rmr.user_id', 'u.avatar_url', 'u.full_name', 'rmr.read_at')
      .leftJoin('users as u', 'rmr.user_id', 'u.id')
      .leftJoin('room_messages as rm', 'rmr.message_id', 'rm.id')
      .where('rm.room_id', roomId)
      .whereIn('rmr.message_id', messageIds);

    // Group by message_id
    const result: Record<string, any[]> = {};
    for (const id of messageIds) {
      result[id] = [];
    }
    
    for (const row of receipts) {
      if (result[row.message_id]) {
        result[row.message_id].push({
          user_id: row.user_id,
          avatar_url: row.avatar_url,
          full_name: row.full_name,
          read_at: row.read_at,
        });
      }
    }

    return result;
  },

  async transferOwnership(roomId: string, ownerId: string, newOwnerId: string): Promise<void> {
    const room = await db('rooms').where({ id: roomId, owner_id: ownerId }).first();
    if (!room) {
      throw new AppError('Room not found or you are not the owner.', 404);
    }

    if (ownerId === newOwnerId) {
      throw new AppError('You are already the owner.', 400);
    }

    // Check if new owner is a member
    const newOwnerMember = await db('room_members').where({ room_id: roomId, user_id: newOwnerId }).first();
    if (!newOwnerMember) {
      throw new AppError('New owner must be a member of the room.', 400);
    }

    await db.transaction(async (trx) => {
      // 1. Update room owner
      await trx('rooms').where({ id: roomId }).update({ owner_id: newOwnerId });

      // 2. Change old owner to moderator
      await trx('room_members').where({ room_id: roomId, user_id: ownerId }).update({ role: 'moderator' });

      // 3. Change new owner role to owner
      await trx('room_members').where({ room_id: roomId, user_id: newOwnerId }).update({ role: 'owner' });
    });
  },

  async getJoinRequests(roomId: string, requesterId: string): Promise<any[]> {
    const member = await db('room_members').where({ room_id: roomId, user_id: requesterId }).first();
    if (!member || !['owner', 'moderator'].includes(member.role)) {
      throw new AppError('Only owners and moderators can view join requests.', 403);
    }

    return db('room_join_requests as rjr')
      .select('rjr.id', 'rjr.status', 'rjr.created_at', 'u.id as user_id', 'u.full_name', 'u.username', 'u.avatar_url')
      .leftJoin('users as u', 'rjr.user_id', 'u.id')
      .where('rjr.room_id', roomId)
      .andWhere('rjr.status', 'pending')
      .orderBy('rjr.created_at', 'desc');
  },

  async approveJoinRequest(roomId: string, requesterId: string, targetUserId: string): Promise<void> {
    const member = await db('room_members').where({ room_id: roomId, user_id: requesterId }).first();
    if (!member || !['owner', 'moderator'].includes(member.role)) {
      throw new AppError('Only owners and moderators can approve requests.', 403);
    }

    const request = await db('room_join_requests')
      .where({ room_id: roomId, user_id: targetUserId, status: 'pending' })
      .first();

    if (!request) {
      throw new AppError('Join request not found or already processed.', 404);
    }

    await db.transaction(async (trx) => {
      // 1. Delete the request
      await trx('room_join_requests').where({ id: request.id }).del();
      
      // 2. Add to members
      const existing = await trx('room_members').where({ room_id: roomId, user_id: targetUserId }).first();
      if (!existing) {
        await trx('room_members').insert({ room_id: roomId, user_id: targetUserId, role: 'member' });
      }

      // 3. Create system message
      const targetUser = await trx('users').where({ id: targetUserId }).first();
      if (targetUser) {
        const [sysMsg] = await trx('room_messages').insert({
          room_id: roomId,
          sender_id: null,
          content: `[SYSTEM]:user_joined:${targetUserId}:${targetUser.full_name}`,
        }).returning('*');

        const wsService = require('./websocket.service').webSocketService;
        const members = await trx('room_members').where({ room_id: roomId });
        for (const m of members) {
          wsService.sendToUser(m.user_id, {
            type: 'room_message',
            data: {
              ...sysMsg,
              sender_name: 'Hệ thống',
              sender_username: 'system',
              sender_avatar: null,
            }
          });
        }
      }
    });
  },

  async rejectJoinRequest(roomId: string, requesterId: string, targetUserId: string): Promise<void> {
    const member = await db('room_members').where({ room_id: roomId, user_id: requesterId }).first();
    if (!member || !['owner', 'moderator'].includes(member.role)) {
      throw new AppError('Only owners and moderators can reject requests.', 403);
    }

    const result = await db('room_join_requests')
      .where({ room_id: roomId, user_id: targetUserId, status: 'pending' })
      .del();

    if (!result) {
      throw new AppError('Join request not found or already processed.', 404);
    }
  }
};

import { db } from '@/config/database';
import { AppError } from '@/utils/AppError';
import { Room, RoomMember, RoomMessage } from '@/module/common/common.type';
import { PaginationParams } from '@/utils/pagination';
import { notificationService } from '@/module/notification/notification.service';

export const roomService = {
  async create(userId: string, data: { name: string; description?: string; is_private?: boolean }): Promise<Room> {
    const [room] = await db('rooms')
      .insert({
        owner_id: userId,
        name: data.name,
        description: data.description || null,
        is_private: data.is_private || false,
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

  async getById(roomId: string): Promise<any> {
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

    return room;
  },

  async getAll(
    pagination: PaginationParams,
    currentUserId?: string
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
        this.where('r.is_private', false);
        if (currentUserId) {
          this.orWhereIn('r.id', db('room_members').select('room_id').where('user_id', currentUserId));
        }
      });

    const countQuery = db('rooms as r')
      .where(function () {
        this.where('r.is_private', false);
        if (currentUserId) {
          this.orWhereIn('r.id', db('room_members').select('room_id').where('user_id', currentUserId));
        }
      });

    const [{ count }] = await countQuery.count('* as count');
    const total = parseInt(count as string, 10);

    const data = await query
      .orderBy('r.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async update(roomId: string, userId: string, data: { name?: string; description?: string; is_private?: boolean }): Promise<Room> {
    const room = await db('rooms').where({ id: roomId, owner_id: userId }).first();
    if (!room) {
      throw new AppError('Room not found or you are not the owner.', 404);
    }

    const updateData: Record<string, any> = {};
    if (data.name !== undefined) updateData.name = data.name;
    if (data.description !== undefined) updateData.description = data.description;
    if (data.is_private !== undefined) updateData.is_private = data.is_private;

    const [updated] = await db('rooms')
      .where({ id: roomId })
      .update(updateData)
      .returning('*');

    return updated;
  },

  async delete(roomId: string, userId: string): Promise<void> {
    const room = await db('rooms').where({ id: roomId, owner_id: userId }).first();
    if (!room) {
      throw new AppError('Room not found or you are not the owner.', 404);
    }

    // Cleanup: messages and members will cascade due to FK
    await db('rooms').where({ id: roomId }).del();
  },

  async join(roomId: string, userId: string): Promise<RoomMember> {
    const room = await db('rooms').where({ id: roomId }).first();
    if (!room) {
      throw new AppError('Room not found.', 404);
    }

    if (room.is_private) {
      throw new AppError('This room is private. You need an invitation to join.', 403);
    }

    const existing = await db('room_members').where({ room_id: roomId, user_id: userId }).first();
    if (existing) {
      throw new AppError('You are already a member of this room.', 400);
    }

    const [member] = await db('room_members')
      .insert({ room_id: roomId, user_id: userId, role: 'member' })
      .returning('*');

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

    const result = await db('room_members')
      .where({ room_id: roomId, user_id: targetUserId })
      .del();

    if (!result) {
      throw new AppError('Target user is not a member of this room.', 404);
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

    // Add as member
    await db('room_members').insert({
      room_id: roomId,
      user_id: targetUserId,
      role: 'member',
    });

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
};

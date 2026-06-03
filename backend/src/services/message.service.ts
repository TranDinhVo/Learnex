import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { DirectMessage } from '../models/types';
import { PaginationParams } from '../utils/pagination';
import { notificationService } from './notification.service';
import { webSocketService } from './websocket.service';

export const messageService = {
  async send(
    senderId: string,
    receiverId: string,
    data: { content?: string; file_url?: string }
  ): Promise<DirectMessage> {
    if (senderId === receiverId) {
      throw new AppError('You cannot send a message to yourself.', 400);
    }

    const receiver = await db('users').where({ id: receiverId }).first();
    if (!receiver) {
      throw new AppError('Recipient not found.', 404);
    }

    if (!data.content && !data.file_url) {
      throw new AppError('Message must have content or a file.', 400);
    }

    const [message] = await db('direct_messages')
      .insert({
        sender_id: senderId,
        receiver_id: receiverId,
        content: data.content || null,
        file_url: data.file_url || null,
      })
      .returning('*');

    // Notification
    const sender = await db('users').where({ id: senderId }).select('full_name').first();
    await notificationService.create({
      user_id: receiverId,
      type: 'message',
      title: 'New Message',
      body: `${sender?.full_name || 'Someone'} sent you a message.`,
      ref_type: 'direct_message',
      ref_id: message.id,
    });

    return message;
  },

  async getConversation(
    userId: string,
    otherUserId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('direct_messages')
      .where(function () {
        this.where(function () {
          this.where('sender_id', userId)
              .andWhere('receiver_id', otherUserId)
              .andWhere('deleted_for_sender', false);
        }).orWhere(function () {
          this.where('sender_id', otherUserId)
              .andWhere('receiver_id', userId)
              .andWhere('deleted_for_receiver', false);
        });
      })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const messages = await db('direct_messages as dm')
      .select(
        'dm.*',
        'u.full_name as sender_name',
        'u.username as sender_username',
        'u.avatar_url as sender_avatar',
      )
      .leftJoin('users as u', 'dm.sender_id', 'u.id')
      .where(function () {
        this.where(function () {
          this.where('dm.sender_id', userId)
              .andWhere('dm.receiver_id', otherUserId)
              .andWhere('dm.deleted_for_sender', false);
        }).orWhere(function () {
          this.where('dm.sender_id', otherUserId)
              .andWhere('dm.receiver_id', userId)
              .andWhere('dm.deleted_for_receiver', false);
        });
      })
      .orderBy('dm.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data: messages, total };
  },

  async getConversationList(userId: string): Promise<any[]> {
    // Get the latest message for each conversation partner
    const conversations = await db.raw(`
      SELECT DISTINCT ON (partner_id) *
      FROM (
        SELECT
          dm.*,
          CASE
            WHEN dm.sender_id = ? THEN dm.receiver_id
            ELSE dm.sender_id
          END as partner_id
        FROM direct_messages dm
        WHERE (dm.sender_id = ? AND dm.deleted_for_sender = FALSE) 
           OR (dm.receiver_id = ? AND dm.deleted_for_receiver = FALSE)
      ) sub
      ORDER BY partner_id, created_at DESC
    `, [userId, userId, userId]);

    const partnerIds = conversations.rows.map((c: any) => c.partner_id);

    if (partnerIds.length === 0) return [];

    const partners = await db('users')
      .select('id', 'full_name', 'username', 'avatar_url')
      .whereIn('id', partnerIds);

    const partnerMap = new Map(partners.map((p: any) => [p.id, p]));

    // Get unread counts per partner
    const unreadCounts = await db('direct_messages')
      .select('sender_id')
      .count('* as unread_count')
      .where({ receiver_id: userId, is_read: false })
      .whereIn('sender_id', partnerIds)
      .groupBy('sender_id');

    const unreadMap = new Map(unreadCounts.map((u: any) => [u.sender_id, parseInt(u.unread_count as string, 10)]));

    return conversations.rows.map((conv: any) => ({
      ...conv,
      partner: partnerMap.get(conv.partner_id) || null,
      unread_count: unreadMap.get(conv.partner_id) || 0,
    }));
  },

  async markAsRead(userId: string, senderId: string): Promise<void> {
    await db('direct_messages')
      .where({ sender_id: senderId, receiver_id: userId, is_read: false })
      .update({ is_read: true });
  },

  async deleteMessage(messageId: string, requesterId: string, type: 'for_me' | 'for_everyone'): Promise<any> {
    const message = await db('direct_messages').where({ id: messageId }).first();
    if (!message) throw new AppError('Message not found', 404);

    if (type === 'for_everyone') {
      if (message.sender_id !== requesterId) {
        throw new AppError('Only the sender can unsend the message', 403);
      }
      const [updatedMessage] = await db('direct_messages')
        .where({ id: messageId })
        .update({ is_deleted: true, content: null, file_url: null })
        .returning('*');
        
      // Notify receiver via WebSocket
      const receiver = message.receiver_id;
      webSocketService.sendToUser(receiver, {
        type: 'message_deleted',
        data: { messageId, conversationId: requesterId }
      });
      return updatedMessage;
    } else {
      // type === 'for_me'
      if (message.sender_id === requesterId) {
        await db('direct_messages').where({ id: messageId }).update({ deleted_for_sender: true });
      } else if (message.receiver_id === requesterId) {
        await db('direct_messages').where({ id: messageId }).update({ deleted_for_receiver: true });
      } else {
        throw new AppError('Unauthorized', 403);
      }
      return { id: messageId, deleted_for_me: true };
    }
  },

  async editMessage(messageId: string, requesterId: string, newContent: string): Promise<any> {
    const message = await db('direct_messages').where({ id: messageId }).first();
    if (!message) throw new AppError('Message not found', 404);

    if (message.sender_id !== requesterId) {
      throw new AppError('Only the sender can edit the message', 403);
    }
    if (message.is_deleted) {
      throw new AppError('Cannot edit deleted message', 400);
    }

    const [updatedMessage] = await db('direct_messages')
      .where({ id: messageId })
      .update({ content: newContent, edited_at: db.fn.now() })
      .returning('*');

    webSocketService.sendToUser(message.receiver_id, {
      type: 'message_edited',
      data: { messageId, content: newContent, conversationId: requesterId }
    });
    return updatedMessage;
  },

  async toggleReaction(messageId: string, userId: string, emoji: string): Promise<any> {
    const message = await db('direct_messages').where({ id: messageId }).first();
    if (!message) {
      throw new AppError('Message not found', 404);
    }

    let reactions = message.reactions || {};
    
    // Ensure reactions is parsed correctly if it's a string from DB driver
    if (typeof reactions === 'string') {
      try {
        reactions = JSON.parse(reactions);
      } catch (e) {
        reactions = {};
      }
    }

    if (!reactions[emoji]) {
      reactions[emoji] = [];
    }

    const userIndex = reactions[emoji].indexOf(userId);
    if (userIndex > -1) {
      // Remove reaction
      reactions[emoji].splice(userIndex, 1);
      if (reactions[emoji].length === 0) {
        delete reactions[emoji];
      }
    } else {
      // Add reaction
      reactions[emoji].push(userId);
    }

    const [updatedMessage] = await db('direct_messages')
      .where({ id: messageId })
      .update({ reactions })
      .returning('*');

    // Determine the peer to notify
    const peerId = message.sender_id === userId ? message.receiver_id : message.sender_id;

    webSocketService.sendToUser(peerId, {
      type: 'message_reaction_updated',
      data: { messageId, reactions: updatedMessage.reactions }
    });

    return updatedMessage;
  }
};

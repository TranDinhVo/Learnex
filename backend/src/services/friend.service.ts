import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { Friendship } from '../models/types';
import { PaginationParams } from '../utils/pagination';
import { notificationService } from './notification.service';

export const friendService = {
  async sendRequest(requesterId: string, addresseeId: string): Promise<Friendship> {
    if (requesterId === addresseeId) {
      throw new AppError('You cannot send a friend request to yourself.', 400);
    }

    // Check if target user exists
    const addressee = await db('users').where({ id: addresseeId }).first();
    if (!addressee) {
      throw new AppError('User not found.', 404);
    }

    // Check existing friendship in either direction
    const existing = await db('friendships')
      .where(function () {
        this.where({ requester_id: requesterId, addressee_id: addresseeId })
          .orWhere({ requester_id: addresseeId, addressee_id: requesterId });
      })
      .first();

    if (existing) {
      if (existing.status === 'accepted') {
        throw new AppError('You are already friends.', 400);
      }
      if (existing.status === 'pending') {
        throw new AppError('A friend request already exists.', 400);
      }
      if (existing.status === 'rejected') {
        // Allow re-sending after rejection
        const [updated] = await db('friendships')
          .where({ id: existing.id })
          .update({
            requester_id: requesterId,
            addressee_id: addresseeId,
            status: 'pending',
          })
          .returning('*');
        return updated;
      }
    }

    const [friendship] = await db('friendships')
      .insert({
        requester_id: requesterId,
        addressee_id: addresseeId,
        status: 'pending',
      })
      .returning('*');

    // Notification
    const requester = await db('users').where({ id: requesterId }).select('full_name').first();
    await notificationService.create({
      user_id: addresseeId,
      type: 'friend_request',
      title: 'New Friend Request',
      body: `${requester?.full_name || 'Someone'} sent you a friend request.`,
      ref_type: 'friendship',
      ref_id: friendship.id,
    });

    return friendship;
  },

  async acceptRequest(friendshipId: string, userId: string): Promise<Friendship> {
    const friendship = await db('friendships')
      .where({ id: friendshipId, addressee_id: userId, status: 'pending' })
      .first();

    if (!friendship) {
      throw new AppError('Friend request not found.', 404);
    }

    const [updated] = await db('friendships')
      .where({ id: friendshipId })
      .update({ status: 'accepted' })
      .returning('*');

    return updated;
  },

  async rejectRequest(friendshipId: string, userId: string): Promise<void> {
    const friendship = await db('friendships')
      .where({ id: friendshipId, addressee_id: userId, status: 'pending' })
      .first();

    if (!friendship) {
      throw new AppError('Friend request not found.', 404);
    }

    await db('friendships')
      .where({ id: friendshipId })
      .update({ status: 'rejected' });
  },

  async unfriend(userId: string, friendId: string): Promise<void> {
    const result = await db('friendships')
      .where(function () {
        this.where({ requester_id: userId, addressee_id: friendId })
          .orWhere({ requester_id: friendId, addressee_id: userId });
      })
      .andWhere({ status: 'accepted' })
      .del();

    if (!result) {
      throw new AppError('Friendship not found.', 404);
    }
  },

  async getFriends(
    userId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('friendships')
      .where(function () {
        this.where({ requester_id: userId }).orWhere({ addressee_id: userId });
      })
      .andWhere({ status: 'accepted' })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const friendships = await db('friendships')
      .where(function () {
        this.where({ requester_id: userId }).orWhere({ addressee_id: userId });
      })
      .andWhere({ status: 'accepted' })
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    // Get friend user details
    const friendIds = friendships.map((f: any) =>
      f.requester_id === userId ? f.addressee_id : f.requester_id
    );

    const friends = friendIds.length > 0
      ? await db('users')
        .select('id', 'full_name', 'username', 'avatar_url', 'bio', 'school', 'major')
        .whereIn('id', friendIds)
      : [];

    return { data: friends, total };
  },

  async getRequests(
    userId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('friendships')
      .where({ addressee_id: userId, status: 'pending' })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const requests = await db('friendships as f')
      .select(
        'f.*',
        'u.full_name as requester_name',
        'u.username as requester_username',
        'u.avatar_url as requester_avatar',
      )
      .leftJoin('users as u', 'f.requester_id', 'u.id')
      .where({ 'f.addressee_id': userId, 'f.status': 'pending' })
      .orderBy('f.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data: requests, total };
  },

  async getSuggestions(
    userId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const currentUser = await db('users').where({ id: userId }).select('school', 'major').first();

    // Collect IDs to exclude (self + existing relations)
    const existingRelations = await db('friendships').where(function () {
      this.where({ requester_id: userId }).orWhere({ addressee_id: userId });
    });

    const excludeIds = new Set<string>([userId]);
    existingRelations.forEach((f: any) => {
      excludeIds.add(f.requester_id);
      excludeIds.add(f.addressee_id);
    });

    // Friends-of-friends (2nd degree connections)
    const myFriends = await db('friendships')
      .where(function () {
        this.where({ requester_id: userId }).orWhere({ addressee_id: userId });
      })
      .andWhere({ status: 'accepted' });

    const friendIds = myFriends.map((f: any) =>
      f.requester_id === userId ? f.addressee_id : f.requester_id
    );

    let suggestions: any[] = [];

    if (friendIds.length > 0) {
      const fofRelations = await db('friendships')
        .where(function () {
          this.whereIn('requester_id', friendIds).orWhereIn('addressee_id', friendIds);
        })
        .andWhere({ status: 'accepted' });

      const fofIds = new Set<string>();
      fofRelations.forEach((f: any) => {
        if (!excludeIds.has(f.requester_id)) fofIds.add(f.requester_id);
        if (!excludeIds.has(f.addressee_id)) fofIds.add(f.addressee_id);
      });

      if (fofIds.size > 0) {
        suggestions = await db('users')
          .select('id', 'full_name', 'username', 'avatar_url', 'bio', 'school', 'major')
          .whereIn('id', [...fofIds])
          .andWhere('is_banned', false)
          .limit(pagination.limit)
          .offset((pagination.page - 1) * pagination.limit);
      }
    }

    // Fill with same school/major
    if (suggestions.length < pagination.limit) {
      const existingSuggestionIds = suggestions.map((s: any) => s.id);
      const remaining = pagination.limit - suggestions.length;
      const fillQuery = db('users')
        .select('id', 'full_name', 'username', 'avatar_url', 'bio', 'school', 'major')
        .whereNotIn('id', [...excludeIds, ...existingSuggestionIds])
        .andWhere('is_banned', false);

      if (currentUser?.school || currentUser?.major) {
        fillQuery.andWhere(function () {
          if (currentUser.school) this.orWhere('school', currentUser.school);
          if (currentUser.major) this.orWhere('major', currentUser.major);
        });
      }

      const fillSuggestions = await fillQuery.limit(remaining);
      suggestions = [...suggestions, ...fillSuggestions];
    }

    // Fall back to newest users
    if (suggestions.length < pagination.limit) {
      const existingSuggestionIds = suggestions.map((s: any) => s.id);
      const remaining = pagination.limit - suggestions.length;
      const randomSuggestions = await db('users')
        .select('id', 'full_name', 'username', 'avatar_url', 'bio', 'school', 'major')
        .whereNotIn('id', [...excludeIds, ...existingSuggestionIds])
        .andWhere('is_banned', false)
        .orderBy('created_at', 'desc')
        .limit(remaining);
      suggestions = [...suggestions, ...randomSuggestions];
    }

    return { data: suggestions, total: suggestions.length };
  },

  async getFriendshipStatus(userId: string, otherUserId: string): Promise<any> {
    const friendship = await db('friendships')
      .where(function () {
        this.where({ requester_id: userId, addressee_id: otherUserId })
          .orWhere({ requester_id: otherUserId, addressee_id: userId });
      })
      .first();

    if (!friendship) {
      return { status: 'none' };
    }

    return {
      id: friendship.id,
      status: friendship.status,
      is_requester: friendship.requester_id === userId,
    };
  },
};

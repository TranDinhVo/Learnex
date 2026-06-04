import { db } from '../config/database';
import { CreateStoryRequest } from '../models/types';
import { webSocketService } from './websocket.service';
import cron from 'node-cron';

class StoryService {
  /**
   * Create a new story
   */
  async createStory(userId: string, data: CreateStoryRequest) {
    const [story] = await db('stories').insert({
      user_id: userId,
      media_url: data.media_url,
      media_type: data.media_type || 'image',
      text_content: data.text_content,
      text_color: data.text_color || '#FFFFFF',
      bg_color: data.bg_color || '#6366F1',
      bg_gradient: data.bg_gradient,
      duration_sec: data.duration_sec || 5,
      visibility: data.visibility || 'friends',
      excluded_user_ids: JSON.stringify(data.excluded_user_ids || []),
      is_active: true,
      is_archived: false,
      created_at: new Date(),
      expires_at: new Date(Date.now() + 12 * 60 * 60 * 1000) // 12 hours from now
    }).returning('*');

    // Broadcast to WebSocket
    webSocketService.broadcastToAll({
      type: 'story_new_feed',
      data: {
        userId: userId,
        storyId: story.id
      }
    });

    return story;
  }

  /**
   * Get Feed Stories (User's own stories + Friends' stories)
   */
  async getFeedStories(userId: string) {
    // 1. Get my active stories
    const myStories = await db('stories')
      .where({ user_id: userId, is_active: true })
      .orderBy('created_at', 'asc');

    // 2. Get friends' active stories
    // Find accepted friends
    const friendsQuery = await db('friendships')
      .where(function() {
        this.where('requester_id', userId).orWhere('addressee_id', userId);
      })
      .andWhere('status', 'accepted');

    const friendIds = friendsQuery.map(f => f.requester_id === userId ? f.addressee_id : f.requester_id);

    let friendStories: any[] = [];
    if (friendIds.length > 0) {
      // Get all active stories from friends
      const rawStories = await db('stories')
        .join('users', 'stories.user_id', 'users.id')
        .whereIn('stories.user_id', friendIds)
        .andWhere('stories.is_active', true)
        .andWhere((builder) => {
          builder.whereIn('stories.visibility', ['public', 'friends'])
            .orWhere((eb) => {
              eb.where('stories.visibility', 'except')
                .andWhereRaw('NOT (COALESCE(stories.excluded_user_ids, \'[]\'::jsonb) @> ?::jsonb)', [JSON.stringify([userId])]);
            });
        })
        .select(
          'stories.*',
          'users.full_name as user_name',
          'users.avatar_url as user_avatar'
        )
        .orderBy('stories.created_at', 'asc');

      // Check if current user has viewed these stories
      const viewedStoryIds = await db('story_views')
        .where('viewer_id', userId)
        .whereIn('story_id', rawStories.map(s => s.id))
        .pluck('story_id');

      // Group stories by user
      const grouped = rawStories.reduce((acc, story) => {
        const isViewed = viewedStoryIds.includes(story.id);
        const uId = story.user_id;
        
        if (!acc[uId]) {
          acc[uId] = {
            user_id: uId,
            user_name: story.user_name,
            user_avatar: story.user_avatar,
            has_unseen: false,
            stories: []
          };
        }
        
        if (!isViewed) {
          acc[uId].has_unseen = true;
        }
        
        acc[uId].stories.push({
          ...story,
          is_viewed: isViewed
        });
        return acc;
      }, {} as Record<string, any>);

      friendStories = Object.values(grouped);
      
      // Sort: those with unseen stories first
      friendStories.sort((a: any, b: any) => {
        if (a.has_unseen && !b.has_unseen) return -1;
        if (!a.has_unseen && b.has_unseen) return 1;
        return 0;
      });
    }

    return {
      my_stories: myStories,
      friend_stories: friendStories
    };
  }

  /**
   * Record a view on a story
   */
  async viewStory(userId: string, storyId: string) {
    try {
      // Lấy thông tin story trước
      const story = await db('stories').where({ id: storyId }).select('user_id').first();
      
      // Chủ story xem story của chính mình → không ghi view, không tính count
      if (story && story.user_id === userId) return true;

      await db('story_views').insert({
        story_id: storyId,
        viewer_id: userId,
        viewed_at: new Date()
      });

      // Broadcast real-time view count cho chủ story
      if (story) {
        // Count chỉ tính những người KHÔNG phải chủ story
        const [{ count }] = await db('story_views')
          .where({ story_id: storyId })
          .whereNot('viewer_id', story.user_id)
          .count('* as count');
        webSocketService.broadcastToAll({
          type: 'story_view_update',
          data: {
            storyId,
            storyOwnerId: story.user_id,
            viewCount: parseInt(count as string, 10)
          }
        });
      }

      return true;
    } catch (e: any) {
      // Ignore unique constraint violation (already viewed)
      if (e.code === '23505') return true;
      throw e;
    }
  }

  /**
   * React to a story
   */
  async reactStory(userId: string, storyId: string, emoji: string) {
    await db('story_reactions')
      .insert({
        story_id: storyId,
        user_id: userId,
        emoji: emoji,
        created_at: new Date()
      });
    
    // Broadcast reaction
    webSocketService.broadcastToAll({
      type: 'story_reaction',
      data: {
        storyId,
        userId,
        emoji
      }
    });
    
    return true;
  }

  /**
   * Get viewers of a story (only owner can access)
   */
  async getStoryViewers(userId: string, storyId: string) {
    // Verify ownership
    const story = await db('stories').where({ id: storyId, user_id: userId }).first();
    if (!story) throw new Error('Story not found or unauthorized');

    const views = await db('story_views')
      .join('users', 'story_views.viewer_id', 'users.id')
      .where('story_views.story_id', storyId)
      .whereNot('story_views.viewer_id', userId)  // Loại chủ story khỏi danh sách
      .select(
        'users.id',
        'users.full_name',
        'users.username',
        'users.avatar_url',
        'story_views.viewed_at'
      )
      .orderBy('story_views.viewed_at', 'desc');

    const reactions = await db('story_reactions')
      .where('story_id', storyId)
      .orderBy('created_at', 'desc')
      .select('user_id', 'emoji');

    const reactionMap = reactions.reduce((acc, r) => {
      if (!acc[r.user_id]) acc[r.user_id] = [];
      if (acc[r.user_id].length < 3) {
        acc[r.user_id].push(r.emoji);
      }
      return acc;
    }, {} as Record<string, string[]>);

    return views.map(v => ({
      ...v,
      reactions: reactionMap[v.id] || []
    }));
  }

  /**
   * Get archived stories (expired ones)
   */
  async getArchive(userId: string) {
    return await db('stories')
      .where({ user_id: userId, is_archived: true })
      .orderBy('created_at', 'desc');
  }

  /**
   * Update story privacy
   */
  async updateStoryPrivacy(userId: string, storyId: string, visibility: string, excludedUserIds?: string[]) {
    const story = await db('stories').where({ id: storyId, user_id: userId }).first();
    if (!story) throw new Error('Story not found or unauthorized');

    const [updated] = await db('stories')
      .where({ id: storyId })
      .update({
        visibility: visibility,
        excluded_user_ids: excludedUserIds ? JSON.stringify(excludedUserIds) : story.excluded_user_ids,
      })
      .returning('*');
    
    // Broadcast privacy update
    webSocketService.broadcastToAll({
      type: 'story_privacy_updated',
      data: { storyId }
    });

    return updated;
  }

  /**
   * Delete a story
   */
  async deleteStory(userId: string, storyId: string) {
    const story = await db('stories').where({ id: storyId, user_id: userId }).first();
    if (!story) throw new Error('Story not found or unauthorized');

    // Delete views and reactions first
    await db('story_views').where({ story_id: storyId }).delete();
    await db('story_reactions').where({ story_id: storyId }).delete();
    
    // Delete the story
    await db('stories').where({ id: storyId }).delete();
    
    // Broadcast delete event
    webSocketService.broadcastToAll({
      type: 'story_deleted',
      data: { storyId }
    });
    
    return true;
  }
}

export const storyService = new StoryService();

// Cron job to expire stories older than 12 hours
// Runs every 15 minutes
cron.schedule('*/15 * * * *', async () => {
  try {
    const updatedCount = await db('stories')
      .where('expires_at', '<', new Date())
      .where('is_active', true)
      .update({
        is_active: false,
        is_archived: true,
        archived_at: new Date()
      });
      
    if (updatedCount > 0) {
      console.log(`✅ Story expiry check: Archived ${updatedCount} stories`);
    }
  } catch (error) {
    console.error('❌ Story expiry check failed:', error);
  }
});

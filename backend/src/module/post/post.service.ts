import { db } from '@/config/database';
import { AppError } from '@/utils/AppError';
import { Post, Comment as CommentType } from '@/module/common/common.type';
import { PaginationParams } from '@/utils/pagination';
import { notificationService } from '@/module/notification/notification.service';

export const postService = {
  async create(userId: string, data: { content?: string; image_urls?: string[]; document_id?: string }): Promise<Post> {
    const [post] = await db('posts')
      .insert({
        user_id: userId,
        content: data.content || null,
        image_urls: data.image_urls ? JSON.stringify(data.image_urls) : null,
        document_id: data.document_id || null,
      })
      .returning('*');
    return post;
  },

  async getById(postId: string, currentUserId?: string): Promise<any> {
    const post = await db('posts as p')
      .select(
        'p.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
      )
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .where('p.id', postId)
      .andWhere('p.is_deleted', false)
      .first();

    if (!post) {
      throw new AppError('Post not found.', 404);
    }

    if (currentUserId) {
      const liked = await db('likes').where({ post_id: postId, user_id: currentUserId }).first();
      const saved = await db('saved_posts').where({ post_id: postId, user_id: currentUserId }).first();
      post.is_liked = !!liked;
      post.is_saved = !!saved;
    }

    return post;
  },

  async update(postId: string, userId: string, data: { content?: string; image_urls?: string[] }): Promise<Post> {
    const post = await db('posts').where({ id: postId, user_id: userId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found or you are not the author.', 404);
    }

    const updateData: Record<string, any> = {};
    if (data.content !== undefined) updateData.content = data.content;
    if (data.image_urls !== undefined) updateData.image_urls = JSON.stringify(data.image_urls);

    const [updated] = await db('posts')
      .where({ id: postId })
      .update(updateData)
      .returning('*');

    return updated;
  },

  async delete(postId: string, userId: string): Promise<void> {
    const post = await db('posts').where({ id: postId, user_id: userId }).first();
    if (!post) {
      throw new AppError('Post not found or you are not the author.', 404);
    }

    await db('posts').where({ id: postId }).update({ is_deleted: true });
  },

  async getFeed(
    pagination: PaginationParams,
    currentUserId?: string,
    targetUserId?: string
  ): Promise<{ data: any[]; total: number }> {
    const baseQuery = db('posts').where('is_deleted', false);
    if (targetUserId) {
      baseQuery.where('user_id', targetUserId);
    }
    const [{ count }] = await baseQuery.clone().count('* as count');
    const total = parseInt(count as string, 10);

    const postsQuery = db('posts as p')
      .select(
        'p.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
      )
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .where('p.is_deleted', false)
      .orderBy('p.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    if (targetUserId) {
      postsQuery.where('p.user_id', targetUserId);
    }

    const posts = await postsQuery;

    if (currentUserId) {
      for (const post of posts) {
        const liked = await db('likes').where({ post_id: post.id, user_id: currentUserId }).first();
        const saved = await db('saved_posts').where({ post_id: post.id, user_id: currentUserId }).first();
        post.is_liked = !!liked;
        post.is_saved = !!saved;
      }
    }

    return { data: posts, total };
  },

  async toggleLike(postId: string, userId: string): Promise<{ liked: boolean }> {
    const post = await db('posts').where({ id: postId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found.', 404);
    }

    const existingLike = await db('likes').where({ post_id: postId, user_id: userId }).first();

    if (existingLike) {
      await db('likes').where({ id: existingLike.id }).del();
      return { liked: false };
    } else {
      await db('likes').insert({ post_id: postId, user_id: userId });

      // Create notification for post owner (if not self-like)
      if (post.user_id !== userId) {
        const liker = await db('users').where({ id: userId }).select('full_name').first();
        await notificationService.create({
          user_id: post.user_id,
          type: 'like',
          title: 'New Like',
          body: `${liker?.full_name || 'Someone'} liked your post.`,
          ref_type: 'post',
          ref_id: postId,
        });
      }

      return { liked: true };
    }
  },

  async toggleSave(postId: string, userId: string): Promise<{ saved: boolean }> {
    const post = await db('posts').where({ id: postId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found.', 404);
    }

    const existingSave = await db('saved_posts').where({ post_id: postId, user_id: userId }).first();

    if (existingSave) {
      await db('saved_posts').where({ id: existingSave.id }).del();
      return { saved: false };
    } else {
      await db('saved_posts').insert({ post_id: postId, user_id: userId });
      return { saved: true };
    }
  },

  async getSavedPosts(
    userId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('saved_posts')
      .where({ user_id: userId })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const posts = await db('saved_posts as sp')
      .select(
        'p.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
        'sp.created_at as saved_at',
      )
      .innerJoin('posts as p', 'sp.post_id', 'p.id')
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .where('sp.user_id', userId)
      .andWhere('p.is_deleted', false)
      .orderBy('sp.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data: posts, total };
  },

  async addComment(postId: string, userId: string, content: string): Promise<CommentType> {
    const post = await db('posts').where({ id: postId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found.', 404);
    }

    const [comment] = await db('comments')
      .insert({ post_id: postId, user_id: userId, content })
      .returning('*');

    // Notification for post owner
    if (post.user_id !== userId) {
      const commenter = await db('users').where({ id: userId }).select('full_name').first();
      await notificationService.create({
        user_id: post.user_id,
        type: 'comment',
        title: 'New Comment',
        body: `${commenter?.full_name || 'Someone'} commented on your post.`,
        ref_type: 'post',
        ref_id: postId,
      });
    }

    return comment;
  },

  async getComments(
    postId: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('comments')
      .where({ post_id: postId })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const comments = await db('comments as c')
      .select(
        'c.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
      )
      .leftJoin('users as u', 'c.user_id', 'u.id')
      .where('c.post_id', postId)
      .orderBy('c.created_at', 'asc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data: comments, total };
  },

  async deleteComment(commentId: string, userId: string): Promise<void> {
    const comment = await db('comments').where({ id: commentId }).first();
    if (!comment) {
      throw new AppError('Comment not found.', 404);
    }

    // Allow delete if comment author or post author
    const post = await db('posts').where({ id: comment.post_id }).first();
    if (comment.user_id !== userId && post?.user_id !== userId) {
      throw new AppError('You are not authorized to delete this comment.', 403);
    }

    await db('comments').where({ id: commentId }).del();
  },
};

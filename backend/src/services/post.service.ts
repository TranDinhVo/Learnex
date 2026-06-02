import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { Post, Comment as CommentType } from '../models/types';
import { PaginationParams } from '../utils/pagination';
import { notificationService } from './notification.service';

export const postService = {
  async create(userId: string, data: { content?: string; image_urls?: string[]; document_id?: string; visibility?: string; tagged_user_ids?: string[] }): Promise<Post> {
    const [post] = await db('posts')
      .insert({
        user_id: userId,
        content: data.content || null,
        image_urls: data.image_urls ? JSON.stringify(data.image_urls) : null,
        document_id: data.document_id || null,
        visibility: data.visibility || 'public',
        tagged_user_ids: data.tagged_user_ids ? JSON.stringify(data.tagged_user_ids) : null,
      })
      .returning('*');

    if (data.tagged_user_ids && data.tagged_user_ids.length > 0) {
      const author = await db('users').where({ id: userId }).first();
      for (const taggedId of data.tagged_user_ids) {
        if (taggedId !== userId) {
          await notificationService.create({
            user_id: taggedId,
            type: 'tag',
            title: `${author.full_name || author.username} đã gắn thẻ bạn trong một bài viết.`,
            ref_type: 'post',
            ref_id: post.id,
          });
        }
      }
    }

    return post;
  },

  async getById(postId: string, currentUserId?: string): Promise<any> {
    const post = await db('posts as p')
      .select(
        'p.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        'd.title as document_title',
        'd.file_size as document_size',
        'd.file_url as document_url',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
        db.raw(`
          (
            SELECT COALESCE(json_agg(json_build_object('id', tu.id, 'full_name', tu.full_name, 'avatar_url', tu.avatar_url)), '[]'::json)
            FROM users tu
            WHERE p.tagged_user_ids IS NOT NULL 
              AND p.tagged_user_ids != 'null'::jsonb 
              AND tu.id::text IN (SELECT jsonb_array_elements_text(p.tagged_user_ids))
          ) as tagged_users
        `)
      )
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .leftJoin('documents as d', 'p.document_id', 'd.id')
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

  async update(postId: string, userId: string, data: { content?: string; image_urls?: string[]; visibility?: string; tagged_user_ids?: string[]; document_id?: string }): Promise<Post> {
    const post = await db('posts').where({ id: postId, user_id: userId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found or you are not the author.', 404);
    }

    const updateData: Record<string, any> = {};
    if (data.content !== undefined) updateData.content = data.content;
    if (data.image_urls !== undefined) updateData.image_urls = JSON.stringify(data.image_urls);
    if (data.visibility !== undefined) updateData.visibility = data.visibility;
    if (data.tagged_user_ids !== undefined) updateData.tagged_user_ids = JSON.stringify(data.tagged_user_ids);
    if (data.document_id !== undefined) updateData.document_id = data.document_id;

    await db('posts')
      .where({ id: postId })
      .update(updateData);

    return this.getById(postId, userId);
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

    // Áp dụng bộ lọc visibility
    if (currentUserId) {
      if (targetUserId) {
        // Đang xem tường nhà người khác
        baseQuery.where('user_id', targetUserId);
        if (targetUserId !== currentUserId) {
          // Kiểm tra xem có phải bạn bè không (bằng subquery)
          baseQuery.where((builder) => {
            builder.where('visibility', 'public')
              .orWhere((orBuilder) => {
                orBuilder.where('visibility', 'friends')
                  .whereExists(
                    db.select('*')
                      .from('friendships')
                      .where('status', 'accepted')
                      .andWhere((subBuilder) => {
                        subBuilder.where('requester_id', currentUserId).andWhere('addressee_id', targetUserId)
                          .orWhere('requester_id', targetUserId).andWhere('addressee_id', currentUserId);
                      })
                  );
              });
          });
        }
      } else {
        // Đang xem feed chung
        baseQuery.where((builder) => {
          builder.where('user_id', currentUserId) // Bài của mình
            .orWhere('visibility', 'public') // Bài public
            .orWhere((orBuilder) => {
              // Bài friends của những người là bạn bè
              orBuilder.where('visibility', 'friends')
                .andWhere((subBuilder) => {
                  subBuilder.whereIn('user_id', db.select('addressee_id').from('friendships').where('requester_id', currentUserId).andWhere('status', 'accepted'))
                    .orWhereIn('user_id', db.select('requester_id').from('friendships').where('addressee_id', currentUserId).andWhere('status', 'accepted'));
                });
            });
        });
      }
    } else {
      // Khách chưa login
      baseQuery.where('visibility', 'public');
      if (targetUserId) {
        baseQuery.where('user_id', targetUserId);
      }
    }

    const [{ count }] = await baseQuery.clone().count('* as count');
    const total = parseInt(count as string, 10);

    const postsQuery = db('posts as p')
      .select(
        'p.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        'd.title as document_title',
        'd.file_size as document_size',
        'd.file_url as document_url',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
        db.raw(`
          (
            SELECT COALESCE(json_agg(json_build_object('id', tu.id, 'full_name', tu.full_name, 'avatar_url', tu.avatar_url)), '[]'::json)
            FROM users tu
            WHERE p.tagged_user_ids IS NOT NULL 
              AND p.tagged_user_ids != 'null'::jsonb 
              AND tu.id::text IN (SELECT jsonb_array_elements_text(p.tagged_user_ids))
          ) as tagged_users
        `)
      )
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .leftJoin('documents as d', 'p.document_id', 'd.id')
      .where('p.is_deleted', false)
      .orderBy('p.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    // Áp dụng bộ lọc visibility cho Query thật
    if (currentUserId) {
      if (targetUserId) {
        postsQuery.where('p.user_id', targetUserId);
        if (targetUserId !== currentUserId) {
          postsQuery.where((builder) => {
            builder.where('p.visibility', 'public')
              .orWhere((orBuilder) => {
                orBuilder.where('p.visibility', 'friends')
                  .whereExists(
                    db.select('*')
                      .from('friendships')
                      .where('status', 'accepted')
                      .andWhere((subBuilder) => {
                        subBuilder.where('requester_id', currentUserId).andWhere('addressee_id', targetUserId)
                          .orWhere('requester_id', targetUserId).andWhere('addressee_id', currentUserId);
                      })
                  );
              });
          });
        }
      } else {
        postsQuery.where((builder) => {
          builder.where('p.user_id', currentUserId)
            .orWhere('p.visibility', 'public')
            .orWhere((orBuilder) => {
              orBuilder.where('p.visibility', 'friends')
                .andWhere((subBuilder) => {
                  subBuilder.whereIn('p.user_id', db.select('addressee_id').from('friendships').where('requester_id', currentUserId).andWhere('status', 'accepted'))
                    .orWhereIn('p.user_id', db.select('requester_id').from('friendships').where('addressee_id', currentUserId).andWhere('status', 'accepted'));
                });
            });
        });
      }
    } else {
      postsQuery.where('p.visibility', 'public');
      if (targetUserId) {
        postsQuery.where('p.user_id', targetUserId);
      }
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
        'd.title as document_title',
        'd.file_size as document_size',
        'd.file_url as document_url',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
        'sp.created_at as saved_at',
      )
      .innerJoin('posts as p', 'sp.post_id', 'p.id')
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .leftJoin('documents as d', 'p.document_id', 'd.id')
      .where('sp.user_id', userId)
      .andWhere('p.is_deleted', false)
      .orderBy('sp.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data: posts, total };
  },

  async getLikers(postId: string): Promise<any[]> {
    const post = await db('posts').where({ id: postId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found.', 404);
    }

    const likers = await db('likes as l')
      .select('u.id', 'u.full_name', 'u.username', 'u.avatar_url', 'l.created_at')
      .innerJoin('users as u', 'l.user_id', 'u.id')
      .where('l.post_id', postId)
      .orderBy('l.created_at', 'desc');

    return likers;
  },

  async addComment(postId: string, userId: string, content: string, parentId?: string, replyToCommentId?: string): Promise<any> {
    const post = await db('posts').where({ id: postId, is_deleted: false }).first();
    if (!post) {
      throw new AppError('Post not found.', 404);
    }

    const [comment] = await db('comments')
      .insert({ post_id: postId, user_id: userId, content, parent_id: parentId || null, reply_to_comment_id: replyToCommentId || null })
      .returning('*');

    const commenter = await db('users').where({ id: userId }).select('full_name', 'username', 'avatar_url').first();
    
    // Notifications
    const targetCommentId = replyToCommentId || parentId;
    if (targetCommentId) {
      const targetComment = await db('comments').where({ id: targetCommentId }).first();
      if (targetComment && targetComment.user_id !== userId) {
        await notificationService.create({
          user_id: targetComment.user_id,
          type: 'comment',
          title: 'New Reply',
          body: `${commenter?.full_name || 'Người dùng'} đã phản hồi bình luận của bạn.`,
          ref_type: 'post',
          ref_id: postId,
        });
      }
    } else if (post.user_id !== userId) {
      await notificationService.create({
        user_id: post.user_id,
        type: 'comment',
        title: 'New Comment',
        body: `${commenter?.full_name || 'Người dùng'} đã bình luận bài viết của bạn.`,
        ref_type: 'post',
        ref_id: postId,
      });
    }

    return {
      ...comment,
      author_name: commenter.full_name,
      author_username: commenter.username,
      author_avatar: commenter.avatar_url,
      like_count: 0,
      is_liked: false,
      replies: []
    };
  },

  async getComments(
    postId: string,
    pagination: PaginationParams,
    currentUserId?: string
  ): Promise<{ data: any[]; total: number }> {
    // We fetch root comments with pagination
    const [{ count }] = await db('comments')
      .where({ post_id: postId })
      .whereNull('parent_id')
      .count('* as count');
    const total = parseInt(count as string, 10);

    const rootComments = await db('comments as c')
      .select(
        'c.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('(SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id)::int as like_count')
      )
      .leftJoin('users as u', 'c.user_id', 'u.id')
      .where('c.post_id', postId)
      .whereNull('c.parent_id')
      .orderBy('c.created_at', 'asc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    if (rootComments.length === 0) {
      return { data: [], total: 0 };
    }

    const rootCommentIds = rootComments.map(c => c.id);

    // Fetch replies for these root comments
    const replies = await db('comments as c')
      .select(
        'c.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('(SELECT COUNT(*) FROM comment_likes WHERE comment_id = c.id)::int as like_count')
      )
      .leftJoin('users as u', 'c.user_id', 'u.id')
      .whereIn('c.parent_id', rootCommentIds)
      .orderBy('c.created_at', 'asc');
      
    // Fetch user likes if authenticated
    let userLikedCommentIds = new Set<string>();
    if (currentUserId) {
      const allCommentIds = [...rootCommentIds, ...replies.map(r => r.id)];
      const likes = await db('comment_likes')
        .where('user_id', currentUserId)
        .whereIn('comment_id', allCommentIds)
        .select('comment_id');
      userLikedCommentIds = new Set(likes.map(l => l.comment_id));
    }

    // Nest replies into root comments
    const repliesMap: Record<string, any[]> = {};
    for (const reply of replies) {
      reply.is_liked = userLikedCommentIds.has(reply.id);
      if (!repliesMap[reply.parent_id]) {
        repliesMap[reply.parent_id] = [];
      }
      repliesMap[reply.parent_id].push(reply);
    }

    for (const comment of rootComments) {
      comment.is_liked = userLikedCommentIds.has(comment.id);
      comment.replies = repliesMap[comment.id] || [];
    }

    return { data: rootComments, total };
  },

  async toggleCommentLike(commentId: string, userId: string): Promise<{ liked: boolean }> {
    const comment = await db('comments').where({ id: commentId }).first();
    if (!comment) {
      throw new AppError('Comment not found.', 404);
    }

    const existingLike = await db('comment_likes').where({ comment_id: commentId, user_id: userId }).first();

    if (existingLike) {
      await db('comment_likes').where({ id: existingLike.id }).del();
      return { liked: false };
    } else {
      await db('comment_likes').insert({ comment_id: commentId, user_id: userId });

      if (comment.user_id !== userId) {
        const liker = await db('users').where({ id: userId }).select('full_name').first();
        await notificationService.create({
          user_id: comment.user_id,
          type: 'like',
          title: 'Comment Liked',
          body: `${liker?.full_name || 'Người dùng'} đã thích bình luận của bạn.`,
          ref_type: 'post',
          ref_id: comment.post_id,
        });
      }

      return { liked: true };
    }
  },

  async updateComment(postId: string, commentId: string, userId: string, content: string): Promise<any> {
    const comment = await db('comments')
      .where({ id: commentId, post_id: postId })
      .first();

    if (!comment) {
      throw new AppError('Comment not found.', 404);
    }
    if (comment.user_id !== userId) {
      throw new AppError('You are not authorized to edit this comment.', 403);
    }

    const [updatedComment] = await db('comments')
      .where({ id: commentId })
      .update({ content, is_edited: true })
      .returning('*');

    return updatedComment;
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

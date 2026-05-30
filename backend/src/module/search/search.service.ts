import { db } from '@/config/database';
import { AppError } from '@/utils/AppError';
import { PaginationParams } from '@/utils/pagination';

export const searchService = {
  async search(
    query: string,
    type: 'all' | 'users' | 'posts' | 'documents',
    pagination: PaginationParams
  ): Promise<{ users?: any[]; posts?: any[]; documents?: any[]; total: number }> {
    if (!query || query.trim().length === 0) {
      throw new AppError('Search query is required.', 400);
    }

    const searchTerm = `%${query.trim()}%`;
    const result: { users?: any[]; posts?: any[]; documents?: any[]; total: number } = { total: 0 };

    if (type === 'all' || type === 'users') {
      const users = await searchService.searchUsers(searchTerm, pagination);
      result.users = users.data;
      result.total += users.total;
    }

    if (type === 'all' || type === 'posts') {
      const posts = await searchService.searchPosts(searchTerm, pagination);
      result.posts = posts.data;
      result.total += posts.total;
    }

    if (type === 'all' || type === 'documents') {
      const documents = await searchService.searchDocuments(searchTerm, pagination);
      result.documents = documents.data;
      result.total += documents.total;
    }

    return result;
  },

  async searchUsers(
    searchTerm: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('users')
      .where(function () {
        this.where('username', 'ILIKE', searchTerm)
          .orWhere('full_name', 'ILIKE', searchTerm);
      })
      .andWhere('is_banned', false)
      .count('* as count');
    const total = parseInt(count as string, 10);

    const data = await db('users')
      .select('id', 'full_name', 'username', 'avatar_url', 'bio', 'school', 'major', 'created_at')
      .where(function () {
        this.where('username', 'ILIKE', searchTerm)
          .orWhere('full_name', 'ILIKE', searchTerm);
      })
      .andWhere('is_banned', false)
      .orderBy('full_name', 'asc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async searchPosts(
    searchTerm: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('posts')
      .where('content', 'ILIKE', searchTerm)
      .andWhere('is_deleted', false)
      .count('* as count');
    const total = parseInt(count as string, 10);

    const data = await db('posts as p')
      .select(
        'p.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('(SELECT COUNT(*) FROM likes WHERE post_id = p.id)::int as like_count'),
        db.raw('(SELECT COUNT(*) FROM comments WHERE post_id = p.id)::int as comment_count'),
      )
      .leftJoin('users as u', 'p.user_id', 'u.id')
      .where('p.content', 'ILIKE', searchTerm)
      .andWhere('p.is_deleted', false)
      .orderBy('p.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async searchDocuments(
    searchTerm: string,
    pagination: PaginationParams
  ): Promise<{ data: any[]; total: number }> {
    const [{ count }] = await db('documents')
      .where(function () {
        this.where('title', 'ILIKE', searchTerm)
          .orWhere('description', 'ILIKE', searchTerm);
      })
      .count('* as count');
    const total = parseInt(count as string, 10);

    const data = await db('documents as d')
      .select(
        'd.*',
        'u.full_name as uploader_name',
        'u.username as uploader_username',
        'u.avatar_url as uploader_avatar',
      )
      .leftJoin('users as u', 'd.user_id', 'u.id')
      .where(function () {
        this.where('d.title', 'ILIKE', searchTerm)
          .orWhere('d.description', 'ILIKE', searchTerm);
      })
      .orderBy('d.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },
};

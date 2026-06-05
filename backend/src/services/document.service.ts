import { db } from '../config/database';
import { AppError } from '../utils/AppError';
import { Document as DocumentType } from '../models/types';
import { PaginationParams } from '../utils/pagination';
import { uploadFile } from '../config/cloudinary';

export const documentService = {
  async upload(
    userId: string,
    file: Express.Multer.File,
    data: { title: string; description?: string; subject?: string; tags?: string[] }
  ): Promise<DocumentType> {
    const fileUrl = await uploadFile(file.buffer, 'documents', `doc_${Date.now()}`);

    const [document] = await db('documents')
      .insert({
        user_id: userId,
        title: data.title,
        description: data.description || null,
        file_url: fileUrl,
        file_size: file.size,
        file_type: file.mimetype,
        subject: data.subject || null,
        tags: data.tags ? JSON.stringify(data.tags) : '[]',
      })
      .returning('*');

    return document;
  },

  async getAll(
    pagination: PaginationParams,
    filters?: { subject?: string; user_id?: string },
    requestUserId?: string
  ): Promise<{ data: any[]; total: number }> {
    let query = db('documents as d')
      .select(
        'd.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
      )
      .leftJoin('users as u', 'd.user_id', 'u.id');

    if (requestUserId) {
      query.select(db.raw(`EXISTS(SELECT 1 FROM saved_documents sd WHERE sd.document_id = d.id AND sd.user_id = ?) as is_saved`, [requestUserId]));
    }

    let countQuery = db('documents as d');

    if (filters?.subject) {
      query = query.where('d.subject', filters.subject);
      countQuery = countQuery.where('d.subject', filters.subject);
    }
    if (filters?.user_id) {
      query = query.where('d.user_id', filters.user_id);
      countQuery = countQuery.where('d.user_id', filters.user_id);
    }

    const [{ count }] = await countQuery.count('* as count');
    const total = parseInt(count as string, 10);

    const data = await query
      .orderBy('d.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async getById(documentId: string, requestUserId?: string): Promise<any> {
    const query = db('documents as d')
      .select(
        'd.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
      )
      .leftJoin('users as u', 'd.user_id', 'u.id')
      .where('d.id', documentId);

    if (requestUserId) {
      query.select(db.raw(`EXISTS(SELECT 1 FROM saved_documents sd WHERE sd.document_id = d.id AND sd.user_id = ?) as is_saved`, [requestUserId]));
    }

    const document = await query.first();

    if (!document) {
      throw new AppError('Document not found.', 404);
    }

    return document;
  },

  async search(
    query: string,
    pagination: PaginationParams,
    requestUserId?: string
  ): Promise<{ data: any[]; total: number }> {
    const searchTerm = `%${query}%`;

    const baseQuery = db('documents as d')
      .select(
        'd.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
      )
      .leftJoin('users as u', 'd.user_id', 'u.id');

    if (requestUserId) {
      baseQuery.select(db.raw(`EXISTS(SELECT 1 FROM saved_documents sd WHERE sd.document_id = d.id AND sd.user_id = ?) as is_saved`, [requestUserId]));
    }

    baseQuery.where(function () {
        this.whereILike('d.title', searchTerm)
          .orWhereILike('d.description', searchTerm)
          .orWhereILike('d.subject', searchTerm);
      });

    const [{ count }] = await baseQuery.clone().clearSelect().count('* as count');
    const total = parseInt(count as string, 10);

    const data = await baseQuery
      .orderBy('d.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async download(documentId: string): Promise<DocumentType> {
    const document = await db('documents').where({ id: documentId }).first();
    if (!document) {
      throw new AppError('Document not found.', 404);
    }

    // Increment download count
    await db('documents')
      .where({ id: documentId })
      .increment('download_count', 1);

    return document;
  },

  async delete(documentId: string, userId: string): Promise<void> {
    const document = await db('documents').where({ id: documentId, user_id: userId }).first();
    if (!document) {
      throw new AppError('Document not found or you are not the owner.', 404);
    }

    await db('documents').where({ id: documentId }).del();
  },

  async trackView(documentId: string, userId: string): Promise<void> {
    // Increment view count
    await db('documents')
      .where({ id: documentId })
      .increment('view_count', 1);

    // Record view for AI recommendations
    await db('document_views').insert({
      user_id: userId,
      document_id: documentId,
    });
  },

  async getRecommendations(userId: string, limit: number = 10): Promise<any[]> {
    // Get subjects the user has viewed
    const viewedSubjects = await db('document_views as dv')
      .select('d.subject')
      .innerJoin('documents as d', 'dv.document_id', 'd.id')
      .where('dv.user_id', userId)
      .whereNotNull('d.subject')
      .groupBy('d.subject')
      .orderByRaw('COUNT(*) DESC')
      .limit(5);

    const subjects = viewedSubjects.map((v: any) => v.subject);

    if (subjects.length === 0) {
      // If no view history, return most popular documents
      return db('documents as d')
        .select(
          'd.*',
          'u.full_name as author_name',
          'u.username as author_username',
        )
        .leftJoin('users as u', 'd.user_id', 'u.id')
        .orderBy('d.view_count', 'desc')
        .limit(limit);
    }

    // Get viewed document IDs to exclude
    const viewedDocs = await db('document_views')
      .select('document_id')
      .where({ user_id: userId })
      .groupBy('document_id');
    const viewedDocIds = viewedDocs.map((v: any) => v.document_id);

    // Recommend documents in similar subjects not yet viewed
    let query = db('documents as d')
      .select(
        'd.*',
        'u.full_name as author_name',
        'u.username as author_username',
      )
      .leftJoin('users as u', 'd.user_id', 'u.id')
      .whereIn('d.subject', subjects)
      .orderBy('d.view_count', 'desc')
      .limit(limit);

    if (viewedDocIds.length > 0) {
      query = query.whereNotIn('d.id', viewedDocIds);
    }

    return query;
  },

  async toggleSave(documentId: string, userId: string): Promise<{ is_saved: boolean }> {
    const doc = await db('documents').where({ id: documentId }).first();
    if (!doc) throw new AppError('Document not found.', 404);

    const saved = await db('saved_documents')
      .where({ user_id: userId, document_id: documentId })
      .first();

    if (saved) {
      await db('saved_documents')
        .where({ user_id: userId, document_id: documentId })
        .del();
      return { is_saved: false };
    } else {
      await db('saved_documents')
        .insert({ user_id: userId, document_id: documentId });
      return { is_saved: true };
    }
  },

  async getSaved(
    userId: string,
    pagination: PaginationParams,
    filters?: { subject?: string }
  ): Promise<{ data: any[]; total: number }> {
    let query = db('documents as d')
      .select(
        'd.*',
        'u.full_name as author_name',
        'u.username as author_username',
        'u.avatar_url as author_avatar',
        db.raw('true as is_saved')
      )
      .innerJoin('saved_documents as sd', 'd.id', 'sd.document_id')
      .leftJoin('users as u', 'd.user_id', 'u.id')
      .where('sd.user_id', userId);

    let countQuery = db('saved_documents as sd')
      .innerJoin('documents as d', 'sd.document_id', 'd.id')
      .where('sd.user_id', userId);

    if (filters?.subject) {
      query = query.where('d.subject', filters.subject);
      countQuery = countQuery.where('d.subject', filters.subject);
    }

    const [{ count }] = await countQuery.count('* as count');
    const total = parseInt(count as string, 10);

    const data = await query
      .orderBy('sd.created_at', 'desc')
      .limit(pagination.limit)
      .offset((pagination.page - 1) * pagination.limit);

    return { data, total };
  },

  async getSubjects(): Promise<any[]> {
    const subjects = await db('subjects').orderBy('name', 'asc');
    return subjects;
  },
};

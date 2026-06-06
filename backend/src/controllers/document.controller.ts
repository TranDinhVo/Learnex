import { Request, Response, NextFunction } from 'express';
import https from 'https';
import http from 'http';
import path from 'path';
import { documentService } from '../services/document.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams, buildPaginationInfo } from '../utils/pagination';
import { AppError } from '../utils/AppError';

/**
 * Convert a Cloudinary URL to force attachment download.
 * Inserts the fl_attachment transformation flag into the URL.
 */
function toAttachmentUrl(url: string, filename?: string): string {
  const flag = filename
    ? `fl_attachment:${filename.replace(/\s+/g, '_')}`
    : 'fl_attachment';
  return url.replace(
    /(\/(raw|image|video)\/upload\/)/,
    `$1${flag}/`
  );
}

export const documentController = {
  async upload(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      if (!req.file) {
        return next(new AppError('Please upload a document file.', 400));
      }
      const { title, description, subject, tags } = req.body;
      const parsedTags = tags ? (typeof tags === 'string' ? JSON.parse(tags) : tags) : [];
      const document = await documentService.upload(req.user!.userId, req.file, {
        title,
        description,
        subject,
        tags: parsedTags,
      });
      sendResponse(res, 201, document, 'Document uploaded successfully');
    } catch (error) {
      next(error);
    }
  },

  async getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });

      // ?mine=true → return only current user's documents (all approval states)
      if (req.query.mine === 'true' && req.user?.userId) {
        const filters: { subject?: string } = {};
        if (req.query.subject) filters.subject = req.query.subject as string;
        const { data, total } = await documentService.getMine(req.user.userId, pagination, filters);
        return void res.status(200).json({
          success: true,
          data,
          pagination: buildPaginationInfo(total, pagination),
        });
      }

      // Public feed — filter out rejected docs
      const filters: { subject?: string; user_id?: string } = {};
      if (req.query.subject) filters.subject = req.query.subject as string;
      if (req.query.user_id) filters.user_id = req.query.user_id as string;

      const { data, total } = await documentService.getAll(pagination, filters, req.user?.userId);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async getById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const document = await documentService.getById(req.params.id as string, req.user?.userId);
      sendResponse(res, 200, document, 'Document retrieved');
    } catch (error) {
      next(error);
    }
  },

  async search(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const query = (req.query.q as string) || '';
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const { data, total } = await documentService.search(query, pagination, req.user?.userId);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async download(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const document = await documentService.download(req.params.id as string);
      const originalUrl = document.file_url as string;
      // Add fl_attachment so mobile browsers trigger download instead of ERR_INVALID_RESPONSE
      const fileUrl = originalUrl?.includes('cloudinary.com')
        ? toAttachmentUrl(originalUrl, path.basename(originalUrl))
        : originalUrl;
      sendResponse(res, 200, { file_url: fileUrl }, 'Download URL retrieved');
    } catch (error) {
      next(error);
    }
  },

  async streamDownload(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const document = await documentService.download(req.params.id as string);
      const fileUrl = document.file_url as string;
      if (!fileUrl) {
        return next(new AppError('File URL not found.', 404));
      }

      const filename = path.basename(fileUrl.split('?')[0]) || 'download';
      const mimeType = (document.file_type as string) || 'application/octet-stream';

      res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
      res.setHeader('Content-Type', mimeType);
      res.setHeader('Cache-Control', 'no-cache');

      const protocol = fileUrl.startsWith('https') ? https : http;
      protocol.get(fileUrl, (fileRes) => {
        if (fileRes.statusCode !== 200) {
          res.status(502).json({ success: false, message: 'Failed to fetch file from storage.' });
          return;
        }
        fileRes.pipe(res);
      }).on('error', (err) => {
        next(new AppError('Failed to stream file: ' + err.message, 502));
      });
    } catch (error) {
      next(error);
    }
  },

  async delete(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await documentService.delete(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'Document deleted successfully');
    } catch (error) {
      next(error);
    }
  },

  async trackView(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      await documentService.trackView(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, null, 'View tracked');
    } catch (error) {
      next(error);
    }
  },

  async getRecommendations(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const limit = parseInt(req.query.limit as string || '10', 10);
      const recommendations = await documentService.getRecommendations(req.user!.userId, limit);
      sendResponse(res, 200, recommendations, 'Recommendations retrieved');
    } catch (error) {
      next(error);
    }
  },

  async toggleSave(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await documentService.toggleSave(req.params.id as string, req.user!.userId);
      sendResponse(res, 200, result, result.is_saved ? 'Document saved' : 'Document unsaved');
    } catch (error) {
      next(error);
    }
  },

  async getSaved(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });
      const filters: { subject?: string } = {};
      if (req.query.subject) filters.subject = req.query.subject as string;

      const { data, total } = await documentService.getSaved(req.user!.userId, pagination, filters);

      res.status(200).json({
        success: true,
        data,
        pagination: buildPaginationInfo(total, pagination),
      });
    } catch (error) {
      next(error);
    }
  },

  async getSubjects(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const subjects = await documentService.getSubjects();
      sendResponse(res, 200, subjects, 'Subjects retrieved');
    } catch (error) {
      next(error);
    }
  },
};

import { Request, Response, NextFunction } from 'express';
import { searchService } from '@/module/search/search.service';
import { getPaginationParams } from '@/utils/pagination';

export const searchController = {
  async search(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const query = (req.query.q as string) || '';
      const type = (req.query.type as 'all' | 'users' | 'posts' | 'documents') || 'all';
      const pagination = getPaginationParams(req.query as { page?: string; limit?: string });

      const results = await searchService.search(query, type, pagination);

      res.status(200).json({
        success: true,
        data: results,
      });
    } catch (error) {
      next(error);
    }
  },
};

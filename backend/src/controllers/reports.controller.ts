import { Request, Response, NextFunction } from 'express';
import { reportsService } from '../services/reports.service';
import { sendResponse } from '../utils/response';
import { getPaginationParams } from '../utils/pagination';

export const reportsController = {
  async createReport(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const reporterId = req.user!.userId;
      const { targetType, targetId, reason } = req.body;
      
      const report = await reportsService.createReport(reporterId, { targetType, targetId, reason });
      sendResponse(res, 201, report, 'Đã gửi báo cáo thành công');
    } catch (error) {
      next(error);
    }
  },

  async getReports(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const pagination = getPaginationParams(req.query as any);
      const result = await reportsService.getReports(pagination);
      
      const formatted = {
        data: result.data,
        total: result.total,
        page: pagination.page,
        limit: pagination.limit,
        totalPages: Math.ceil(result.total / pagination.limit)
      };

      sendResponse(res, 200, formatted, 'Lấy danh sách báo cáo thành công');
    } catch (error) {
      next(error);
    }
  },

  async updateReportStatus(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const { status } = req.body;
      const report = await reportsService.updateReportStatus(id, status);
      sendResponse(res, 200, report, 'Cập nhật trạng thái báo cáo thành công');
    } catch (error) {
      next(error);
    }
  }
};

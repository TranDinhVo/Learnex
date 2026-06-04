import { Router } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { requireAdmin } from '../middleware/admin.middleware';
import { reportsController } from '../controllers/reports.controller';

const router = Router();

// Users can create reports
router.post('/', requireAuth, reportsController.createReport);

// Only admins can view and manage reports
router.get('/', requireAuth, requireAdmin, reportsController.getReports);
router.put('/:id/status', requireAuth, requireAdmin, reportsController.updateReportStatus);

export default router;

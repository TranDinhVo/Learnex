import { Router } from 'express';
import { notificationController } from '../controllers/notification.controller';
import { requireAuth } from '../middleware/auth.middleware';

const router = Router();

router.use(requireAuth);

router.get('/', notificationController.getMyNotifications);
router.get('/unread-count', notificationController.getUnreadCount);
router.post('/read-all', notificationController.markAllRead);
router.post('/fcm-token', notificationController.registerFcmToken);
router.post('/:id/read', notificationController.markRead);

export default router;

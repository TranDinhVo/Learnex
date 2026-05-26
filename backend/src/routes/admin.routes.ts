import { Router } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { requireAdmin } from '../middleware/admin.middleware';
import { adminController } from '../controllers/admin.controller';

const router = Router();

// All admin routes require both Authentication and Admin role
router.use(requireAuth, requireAdmin);

router.get('/dashboard/stats', adminController.getDashboardStats);
router.get('/users', adminController.getAllUsers);
router.put('/users/:id/ban', adminController.banUser);
router.put('/users/:id/unban', adminController.unbanUser);
router.delete('/users/:id', adminController.deleteUser);

// Posts Moderation
router.get('/posts', adminController.getAllPosts);
router.put('/posts/:id/hide', adminController.hidePost);
router.put('/posts/:id/unhide', adminController.unhidePost);
router.delete('/posts/:id', adminController.deletePost);

// Documents Management
router.get('/documents', adminController.getAllDocuments);
router.put('/documents/:id/approve', adminController.approveDocument);
router.put('/documents/:id/reject', adminController.rejectDocument);
router.delete('/documents/:id', adminController.deleteDocument);

// Rooms Moderation
router.get('/rooms', adminController.getAllRooms);
router.delete('/rooms/:id', adminController.deleteRoom);

// System Notifications
router.post('/notifications', adminController.sendNotification);
router.get('/notifications', adminController.getNotificationHistory);

export default router;

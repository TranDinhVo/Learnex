import { Router } from 'express';
import { query } from 'express-validator';
import { validate } from '@/middleware/validate';
import { requireAuth } from '@/middleware/auth.middleware';
import { uploadImage } from '@/middleware/upload.middleware';
import { userController } from '@/module/user/user.controller';

const router = Router();

// All user routes require authentication
router.use(requireAuth);

router.get('/me', userController.getMe);

router.put('/me', userController.updateProfile);

router.put('/me/avatar', uploadImage.single('avatar'), userController.uploadAvatar);

router.get(
  '/search',
  validate([
    query('q').notEmpty().withMessage('Search query is required'),
  ]),
  userController.searchUsers
);

router.get('/:id', userController.getUserById);

export default router;

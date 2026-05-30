import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '@/middleware/validate';
import { requireAuth } from '@/middleware/auth.middleware';
import { roomController } from '@/module/room/room.controller';

const router = Router();

// Protect all routes
router.use(requireAuth);

router.post(
  '/',
  validate([
    body('name').notEmpty().trim().withMessage('Room name is required'),
    body('description').optional().trim(),
    body('is_private').optional().isBoolean(),
  ]),
  roomController.create
);

router.get('/', roomController.getAll);
router.get('/:id', roomController.getById);

router.put(
  '/:id',
  validate([
    body('name').optional().trim().notEmpty().withMessage('Room name cannot be empty'),
    body('description').optional().trim(),
    body('is_private').optional().isBoolean(),
  ]),
  roomController.update
);

router.delete('/:id', roomController.delete);

router.post('/:id/join', roomController.join);
router.post('/:id/leave', roomController.leave);

router.get('/:id/members', roomController.getMembers);

router.post(
  '/:id/kick',
  validate([
    body('userId').notEmpty().withMessage('User ID to kick is required'),
  ]),
  roomController.kick
);

router.post(
  '/:id/invite',
  validate([
    body('userId').notEmpty().withMessage('User ID to invite is required'),
  ]),
  roomController.invite
);

router.post(
  '/:id/messages',
  validate([
    body('content').optional().trim(),
    body('file_url').optional().isURL().withMessage('Please provide a valid file URL'),
  ]),
  roomController.sendMessage
);

router.get('/:id/messages', roomController.getMessages);

export default router;

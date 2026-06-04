import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth } from '../middleware/auth.middleware';
import { roomController } from '../controllers/room.controller';
import { uploadImage } from '../middleware/upload.middleware';

const router = Router();

// Protect all routes
router.use(requireAuth);

router.post(
  '/',
  validate([
    body('name').notEmpty().trim().withMessage('Room name is required'),
    body('description').optional().trim(),
    body('privacy_mode').optional().isIn(['public', 'private', 'approval']).withMessage('Invalid privacy mode'),
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
    body('privacy_mode').optional().isIn(['public', 'private', 'approval']).withMessage('Invalid privacy mode'),
  ]),
  roomController.update
);

router.delete('/:id', roomController.delete);

router.post('/:id/join', roomController.join);
router.post('/:id/leave', roomController.leave);

router.post('/:id/avatar', uploadImage.single('avatar'), roomController.uploadAvatar);

router.get('/:id/members', roomController.getMembers);

router.put(
  '/:id/members/:userId/role',
  validate([
    body('role').isIn(['owner', 'moderator', 'member']).withMessage('Invalid role'),
  ]),
  roomController.updateMemberRole
);

router.post(
  '/:id/kick',
  validate([
    body('userId').notEmpty().withMessage('User ID to kick is required'),
  ]),
  roomController.kick
);

router.post(
  '/:id/transfer-ownership',
  validate([
    body('newOwnerId').notEmpty().withMessage('New owner ID is required'),
  ]),
  roomController.transferOwnership
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

router.post(
  '/:id/messages/read',
  validate([
    body('messageIds').isArray().withMessage('messageIds must be an array'),
  ]),
  roomController.markRead
);

router.get('/:id/messages/read-receipts', roomController.getReadReceipts);

// Join Requests
router.get('/:id/requests', roomController.getJoinRequests);
router.post('/:id/requests/:userId/approve', roomController.approveJoinRequest);
router.post('/:id/requests/:userId/reject', roomController.rejectJoinRequest);

export default router;

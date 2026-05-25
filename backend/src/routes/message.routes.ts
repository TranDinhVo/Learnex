import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth } from '../middleware/auth.middleware';
import { messageController } from '../controllers/message.controller';

const router = Router();

router.use(requireAuth);

router.post(
  '/',
  validate([
    body('receiverId').notEmpty().withMessage('Receiver ID is required'),
    body('content').optional().trim(),
    body('fileUrl').optional().isURL().withMessage('Please provide a valid file URL'),
  ]),
  messageController.send
);

router.get('/conversations', messageController.getConversationList);
router.get('/:userId', messageController.getConversation);
router.put('/:userId/read', messageController.markAsRead);

export default router;

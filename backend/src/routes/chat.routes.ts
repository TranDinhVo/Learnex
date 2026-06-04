import { Router } from 'express';
import { chatController } from '../controllers/chat.controller';
import { requireAuth } from '../middleware/auth.middleware';

const router = Router();

router.use(requireAuth);

router.get('/conversations', chatController.getConversations);
router.get('/conversations/:conversationId/messages', chatController.getMessages);
router.post('/conversations/:conversationId/messages', chatController.sendMessage);

router.delete('/messages/:messageId', chatController.deleteMessage);
router.put('/messages/:messageId', chatController.editMessage);
router.post('/messages/:messageId/reactions', chatController.toggleReaction);

export default router;

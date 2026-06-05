import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth } from '../middleware/auth.middleware';
import { aiController } from '../controllers/ai.controller';

const router = Router();

router.post(
  '/chat',
  requireAuth,
  validate([
    body('messages').isArray().withMessage('Messages must be an array'),
  ]),
  aiController.chat
);

export default router;

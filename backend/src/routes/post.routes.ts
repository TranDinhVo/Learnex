import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth, optionalAuth } from '../middleware/auth.middleware';
import { postController } from '../controllers/post.controller';

const router = Router();

// Public feed (with optional auth for like/save status)
router.get('/feed', optionalAuth, postController.getFeed);

// Saved posts
router.get('/saved', requireAuth, postController.getSavedPosts);

// CRUD
router.post(
  '/',
  requireAuth,
  validate([
    body('content').optional().isString(),
    body('image_urls').optional().isArray(),
    body('document_id').optional().isUUID(),
    body('visibility').optional().isString().isIn(['public', 'friends', 'private']),
    body('tagged_user_ids').optional().isArray(),
    body('tagged_user_ids.*').optional().isUUID(),
  ]),
  postController.create
);

router.get('/:id', optionalAuth, postController.getById);

router.put(
  '/:id',
  requireAuth,
  validate([
    body('content').optional().isString(),
    body('image_urls').optional().isArray(),
    body('visibility').optional().isString().isIn(['public', 'friends', 'private']),
    body('tagged_user_ids').optional().isArray(),
    body('tagged_user_ids.*').optional().isUUID(),
  ]),
  postController.update
);

router.delete('/:id', requireAuth, postController.delete);

// Like & Save
router.post('/:id/like', requireAuth, postController.toggleLike);
router.post('/:id/save', requireAuth, postController.toggleSave);

// Comments
router.get('/:id/comments', optionalAuth, postController.getComments);
router.post(
  '/:id/comments',
  requireAuth,
  validate([
    body('content').notEmpty().withMessage('Comment content is required'),
  ]),
  postController.addComment
);
router.delete('/:id/comments/:commentId', requireAuth, postController.deleteComment);

export default router;

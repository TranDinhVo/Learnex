import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth, optionalAuth } from '../middleware/auth.middleware';
import { postController } from '../controllers/post.controller';
import rateLimit from 'express-rate-limit';

const createPostLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  limit: 5,
  message: { success: false, message: 'Too many posts created. Please try again later.' },
});

const router = Router();

// Public feed (with optional auth for like/save status)
router.get('/feed', optionalAuth, postController.getFeed);

// Saved posts
router.get('/saved', requireAuth, postController.getSavedPosts);

// CRUD
router.post(
  '/',
  requireAuth,
  createPostLimiter,
  validate([
    body('content').optional().isString(),
    body('image_urls').optional().isArray(),
    body('document_id').optional().isUUID(),
    body('visibility').optional().isString().isIn(['public', 'friends', 'private']),
    body('tagged_user_ids').optional().isArray(),
    body('tagged_user_ids.*').optional().isUUID(),
    body().custom((value, { req }) => {
      const { content, image_urls, document_id } = req.body;
      if (!content && (!image_urls || image_urls.length === 0) && !document_id) {
        throw new Error('Post must have at least content, images, or a document.');
      }
      return true;
    }),
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
    body().custom((value, { req }) => {
      const { content, image_urls, document_id } = req.body;
      if (!content && (!image_urls || image_urls.length === 0) && !document_id) {
        throw new Error('Post must have at least content, images, or a document.');
      }
      return true;
    }),
  ]),
  postController.update
);

router.delete('/:id', requireAuth, postController.delete);

// Like & Save
router.get('/:id/likers', optionalAuth, postController.getLikers);
router.post('/:id/like', requireAuth, postController.toggleLike);
router.post('/:id/save', requireAuth, postController.toggleSave);

// Comments
router.get('/:id/comments', optionalAuth, postController.getComments);
router.post(
  '/:id/comments',
  requireAuth,
  validate([
    body('content').notEmpty().withMessage('Comment content is required'),
    body('parent_id').optional().isUUID().withMessage('Invalid parent comment ID'),
    body('reply_to_comment_id').optional().isUUID().withMessage('Invalid reply comment ID'),
  ]),
  postController.addComment
);
router.post('/:id/comments/:commentId/like', requireAuth, postController.toggleCommentLike);
router.put(
  '/:id/comments/:commentId',
  requireAuth,
  validate([
    body('content').notEmpty().withMessage('Comment content is required'),
  ]),
  postController.updateComment
);
router.delete('/:id/comments/:commentId', requireAuth, postController.deleteComment);

export default router;

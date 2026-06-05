import { Router } from 'express';
import { body, query } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth, optionalAuth } from '../middleware/auth.middleware';
import { uploadDocument } from '../middleware/upload.middleware';
import { documentController } from '../controllers/document.controller';

const router = Router();

// Get predefined subjects
router.get('/subjects', documentController.getSubjects);

// Get saved documents (Must be before /:id)
router.get('/saved', requireAuth, documentController.getSaved);

// Toggle save document
router.post('/:id/save', requireAuth, documentController.toggleSave);

// Search documents
router.get(
  '/search',
  optionalAuth,
  validate([
    query('q').notEmpty().withMessage('Search query is required'),
  ]),
  documentController.search
);

// Recommendations (requires auth for personalization)
router.get('/recommendations', requireAuth, documentController.getRecommendations);

// List all documents (with optional filters)
router.get('/', optionalAuth, documentController.getAll);

// Upload document
router.post(
  '/',
  requireAuth,
  uploadDocument.single('file'),
  validate([
    body('title').notEmpty().withMessage('Title is required'),
  ]),
  documentController.upload
);

// Get single document
router.get('/:id', optionalAuth, documentController.getById);

// Download document (increments count)
router.get('/:id/download', documentController.download);

// Track view
router.post('/:id/view', requireAuth, documentController.trackView);

// Delete document
router.delete('/:id', requireAuth, documentController.delete);

export default router;

import { Router } from 'express';
import { query } from 'express-validator';
import { validate } from '../middleware/validate';
import { requireAuth } from '../middleware/auth.middleware';
import { searchController } from '../controllers/search.controller';

const router = Router();

router.get(
  '/',
  requireAuth,
  validate([
    query('q').notEmpty().trim().withMessage('Search query is required'),
    query('type').optional().isIn(['all', 'users', 'posts', 'documents']).withMessage('Invalid search type'),
  ]),
  searchController.search
);

export default router;

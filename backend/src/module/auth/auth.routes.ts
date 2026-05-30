import { Router } from 'express';
import { body } from 'express-validator';
import { validate } from '@/middleware/validate';
import { requireAuth } from '@/middleware/auth.middleware';
import { authLimiter } from '@/middleware/rateLimiter.middleware';
import { authController } from '@/module/auth/auth.controller';

const router = Router();

router.post(
  '/register',
  authLimiter,
  validate([
    body('email').isEmail().withMessage('Please provide a valid email'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('full_name').notEmpty().trim().withMessage('Full name is required'),
    body('username')
      .isLength({ min: 3, max: 50 })
      .matches(/^[a-zA-Z0-9_]+$/)
      .withMessage('Username must be 3-50 chars, alphanumeric and underscores only'),
  ]),
  authController.register
);

router.post(
  '/login',
  authLimiter,
  validate([
    body('email').isEmail().withMessage('Please provide a valid email'),
    body('password').notEmpty().withMessage('Password is required'),
  ]),
  authController.login
);

router.post(
  '/refresh',
  validate([
    body('refreshToken').notEmpty().withMessage('Refresh token is required'),
  ]),
  authController.refreshToken
);

router.post(
  '/logout',
  validate([
    body('refreshToken').notEmpty().withMessage('Refresh token is required'),
  ]),
  authController.logout
);

router.post(
  '/forgot-password',
  authLimiter,
  validate([
    body('email').isEmail().withMessage('Please provide a valid email'),
  ]),
  authController.forgotPassword
);

router.post(
  '/verify-otp',
  authLimiter,
  validate([
    body('email').isEmail().withMessage('Please provide a valid email'),
    body('otp').isLength({ min: 6, max: 6 }).withMessage('OTP must be 6 digits'),
  ]),
  authController.verifyOtp
);

router.post(
  '/reset-password',
  authLimiter,
  validate([
    body('resetToken').notEmpty().withMessage('Reset token is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  ]),
  authController.resetPassword
);

router.put(
  '/change-password',
  requireAuth,
  validate([
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters'),
  ]),
  authController.changePassword
);

export default router;

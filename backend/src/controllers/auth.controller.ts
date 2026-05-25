import { Request, Response, NextFunction } from 'express';
import { authService } from '../services/auth.service';
import { sendResponse } from '../utils/response';

export const authController = {
  async register(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password, full_name, username } = req.body;
      const result = await authService.register(email, password, full_name, username);
      sendResponse(res, 201, result, 'Registration successful');
    } catch (error) {
      next(error);
    }
  },

  async login(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;
      const result = await authService.login(email, password);
      sendResponse(res, 200, result, 'Login successful');
    } catch (error) {
      next(error);
    }
  },

  async refreshToken(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      const tokens = await authService.refreshToken(refreshToken);
      sendResponse(res, 200, tokens, 'Token refreshed successfully');
    } catch (error) {
      next(error);
    }
  },

  async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;
      await authService.logout(refreshToken);
      sendResponse(res, 200, null, 'Logged out successfully');
    } catch (error) {
      next(error);
    }
  },

  async forgotPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email } = req.body;
      await authService.forgotPassword(email);
      sendResponse(res, 200, null, 'If the email exists, an OTP has been sent.');
    } catch (error) {
      next(error);
    }
  },

  async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, otp } = req.body;
      const result = await authService.verifyOtp(email, otp);
      sendResponse(res, 200, result, 'OTP verified successfully');
    } catch (error) {
      next(error);
    }
  },

  async resetPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { resetToken, newPassword } = req.body;
      await authService.resetPassword(resetToken, newPassword);
      sendResponse(res, 200, null, 'Password reset successfully');
    } catch (error) {
      next(error);
    }
  },

  async changePassword(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { currentPassword, newPassword } = req.body;
      await authService.changePassword(req.user!.userId, currentPassword, newPassword);
      sendResponse(res, 200, null, 'Password changed successfully');
    } catch (error) {
      next(error);
    }
  },
};

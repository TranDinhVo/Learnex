import { Request, Response, NextFunction } from 'express';
import { AppError } from '../utils/AppError';

export const requireAdmin = (req: Request, res: Response, next: NextFunction): void => {
  if (!req.user) {
    return next(new AppError('You are not logged in.', 401));
  }

  if (req.user.role !== 'admin') {
    return next(new AppError('You do not have permission to perform this action.', 403));
  }

  next();
};

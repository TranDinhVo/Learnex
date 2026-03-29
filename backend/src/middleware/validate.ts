import { Request, Response, NextFunction } from 'express';
import { validationResult, ContextRunner } from 'express-validator';
import { AppError } from '../utils/AppError';

export const validate = (validations: ContextRunner[]) => {
  return async (req: Request, res: Response, next: NextFunction) => {
    // Sequential validation, stop on first error if needed or run all
    for (let validation of validations) {
      const result = await validation.run(req);
      if (result.array().length) break;
    }

    const errors = validationResult(req);
    if (errors.isEmpty()) {
      return next();
    }

    const firstError = errors.array()[0].msg;
    return next(new AppError(firstError, 400));
  };
};
